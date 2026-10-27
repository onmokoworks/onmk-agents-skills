#!/bin/zsh
# Shared settings. Sourced by the other scripts.
#   ORCH_MAIN  main checkout of the project (default: the git top level of the current directory)
#   ORCH_BASE  integration branch workers branch from and are compared against (default: its current branch)
ORCH_MAIN=${ORCH_MAIN:-$(git rev-parse --show-toplevel 2>/dev/null)}
[[ -n $ORCH_MAIN ]] || { echo "ORCH_MAIN not set and not inside a git repository" >&2; exit 1; }
ORCH_BASE=${ORCH_BASE:-$(git -C "$ORCH_MAIN" branch --show-current)}
ORCH="$ORCH_MAIN/orchestra"
ORCH_WT="$ORCH_MAIN/worktrees"
