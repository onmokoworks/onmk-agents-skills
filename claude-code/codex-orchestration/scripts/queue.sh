#!/bin/zsh
# Dynamic queue: queue.sh <model|-> <queue-file> [max-concurrent]
# Runs the first ticket id in the file that has not started; append lines to add work.
# A ticket line "depends: <id>" waits until <id> finished and its branch orch/<id> was merged and deleted.
# Tickets whose id starts with I (integration) run alone.
source "${0:A:h}/env.sh"
model=$1; q=$2; limit=${3:-1}; [[ $model == - ]] && model=""
running(){ local n=0; for m in "$ORCH"/state/*.meta(N); do grep -q "^exit" "$m" || ((n++)); done; echo $n; }
while true; do
  (( $(running) >= limit )) && { sleep 60; continue; }
  # while an integration ticket runs, start nothing else
  excl=0; for m in "$ORCH"/state/I*.meta(N); do grep -q "^exit" "$m" || excl=1; done
  (( excl )) && { sleep 60; continue; }
  # resource gate: keep memory and disk headroom
  memfree=$(memory_pressure 2>/dev/null | awk -F': ' '/free percentage/{gsub("%","",$2);print $2}')
  diskfree=$(df -g "$ORCH_MAIN" | awk 'NR==2{print $4}')
  if (( ${memfree:-100} < ${MIN_MEM_PCT:-25} || ${diskfree:-999} < ${MIN_DISK_GB:-20} )); then
    echo "$(date +%T) hold: mem ${memfree}% disk ${diskfree}G" >> "$ORCH/state/queue.hold"; sleep 120; continue
  fi
  next=""
  while read -r t; do
    [[ -z $t || $t == \#* ]] && continue
    [[ -f "$ORCH/state/$t.meta" ]] && continue  # started or done; delete meta to re-run
    blocked=0; for d in $(sed -n 's/^depends: *//p' "$ORCH/tickets/$t.md" 2>/dev/null); do
      { [[ -f "$ORCH/state/$d.meta" ]] && grep -q "^exit" "$ORCH/state/$d.meta" && [[ -z $(git -C "$ORCH_MAIN" branch --list "orch/$d") ]]; } || blocked=1
    done; (( blocked )) && continue
    next=$t; break
  done < "$q"
  [[ -z $next ]] && { sleep 120; continue; }
  if [[ $next == I* ]] && (( $(running) > 0 )); then sleep 60; continue; fi
  echo "codex ${model:-default} $(date +%s)" > "$ORCH/state/$next.meta"  # claim before launch (avoid double start)
  # own process group per worker so procguard/run.sh can kill the whole subtree
  python3 -c 'import os,sys; os.setsid(); os.execvp(sys.argv[1], sys.argv[1:])' "${0:A:h}/run.sh" "$next" $model &
  sleep ${LAUNCH_GAP:-240}  # let the new worker ramp up before the memory gate is read again
done
