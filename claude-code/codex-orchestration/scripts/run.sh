#!/bin/zsh
# Launch one Codex worker on one ticket in its own worktree.
#   run.sh <ticket-id> [model]
# Ticket text: orchestra/tickets/<ticket-id>.md
set -u
source "${0:A:h}/env.sh"
id=$1; model=${2:-}
ticket="$ORCH/tickets/$id.md"
[[ -f $ticket ]] || { echo "no ticket $ticket"; exit 1; }
wt="$ORCH_WT/$id"
mkdir -p "$ORCH/logs" "$ORCH/state"
if [[ ! -d $wt ]]; then
  git -C "$ORCH_MAIN" worktree add -q -b "orch/$id" "$wt" "$ORCH_BASE"
fi
mkdir -p "$wt/orchestra/state/$id" "$wt/orchestra/reports"
prompt="$(cat "$ORCH/BRIEF.md")

# Your ticket: $id
Worktree: $wt
Main checkout (read-only): $ORCH_MAIN

$(cat "$ticket")"
log="$ORCH/logs/$id.log"
[[ -f "$ORCH/state/$id.meta" ]] || echo "codex ${model:-default} $(date +%s)" > "$ORCH/state/$id.meta"
cd "$wt"
# limit runaway process creation: allow ~400 more processes than the user has now
ulimit -u $(( $(ps -axo user= | grep -c "^$(whoami)") + 400 )) 2>/dev/null
marg=(); [[ -n $model ]] && marg=(-m "$model")
codex exec --dangerously-bypass-approvals-and-sandbox -C "$wt" -c model_reasoning_effort=${EFFORT:-medium} "${marg[@]}" "$prompt" < /dev/null > "$log" 2>&1; rc=$?
for attempt in 1 2 3; do
  [[ -f "$wt/orchestra/reports/$id.md" ]] && break
  grep -qE 'routing discovery timed out|Reconnecting\.\.\. 5/5|at capacity|stream disconnected|request timed out' "$log" || break
  echo "[run.sh] codex transient failure, retry $attempt after 120s" >> "$log"; sleep 120
  codex exec --dangerously-bypass-approvals-and-sandbox -C "$wt" -c model_reasoning_effort=${EFFORT:-medium} "${marg[@]}" "$prompt

## Resume
A previous attempt of this ticket was cut off by a network/capacity error. Inspect git status/diff and
orchestra/state/$id/ in this worktree, keep what you can verify, and continue." < /dev/null >> "$log" 2>&1; rc=$?
done
echo "exit $rc $(date +%s)" >> "$ORCH/state/$id.meta"
# reap anything left in this worker's process group (MCP helpers, timed-out test descendants)
pg=$(ps -o pgid= -p $$ | tr -d " "); [[ -n $pg && $pg -gt 1 ]] && { for p in $(pgrep -g $pg); do [[ $p != $$ ]] && kill -TERM $p 2>/dev/null; done; }
