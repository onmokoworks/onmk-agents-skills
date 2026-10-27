#!/bin/zsh
# One compact line per ticket, for the orchestrator. Keep output small.
source "${0:A:h}/env.sh"
now=$(date +%s)
printf "disk_free=%s base=%s\n" "$(df -h "$ORCH_MAIN" | awk 'NR==2{print $4}')" "$ORCH_BASE"
for meta in "$ORCH"/state/*.meta(N); do
  id=${meta:t:r}; wt="$ORCH_WT/$id"
  read engine model start < "$meta"
  fin=$(grep '^exit' "$meta" | tail -1)
  state=${fin:-running}
  mins=$(( (now - start) / 60 ))
  rep=$wt/orchestra/reports/$id.md
  st=$( [[ -f $rep ]] && grep -m1 '^status:' "$rep" | cut -c9- || echo "-")
  commits=$(git -C "$wt" rev-list --count HEAD "^$ORCH_BASE" 2>/dev/null || echo 0)
  dirty=$(git -C "$wt" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  logsz=$(stat -f %z "$ORCH/logs/$id.log" 2>/dev/null || echo 0)
  printf "%-28s %-20s %4sm %-10s report=%-8s commits=%s dirty=%s log=%sB\n" \
    "$id" "${model:-default}" "$mins" "$state" "$st" "$commits" "$dirty" "$logsz"
done
