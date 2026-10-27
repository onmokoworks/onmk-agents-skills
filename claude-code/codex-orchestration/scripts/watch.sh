#!/bin/zsh
# Block until a new drift flag / worker exit / error appears, print it, exit.
# Run it in the background; its exit is the orchestrator's wake-up signal.
source "${0:A:h}/env.sh"
here=${0:A:h}
snap(){ { "$here/drift.sh"; grep -H '^exit' "$ORCH"/state/*.meta 2>/dev/null; grep -lE '^ERROR: \{|auto-rejecting|at capacity|flagged for possible cybersecurity risk' "$ORCH"/logs/*.log 2>/dev/null | sed 's/^/errors-in /'; } | sort; }
prev=$(snap)
while true; do
  sleep 60; cur=$(snap)
  new=$(comm -13 <(echo "$prev") <(echo "$cur"))
  [[ -n $new ]] && { echo "$new"; exit 0; }
  prev=$cur
done
