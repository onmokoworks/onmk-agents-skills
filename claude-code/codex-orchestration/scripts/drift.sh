#!/bin/zsh
# Cheap drift detector: prints only rule violations / red flags per running worker.
# PROTECTED_RE: extended regex of paths workers must not change (release gate, expected outputs, ...).
source "${0:A:h}/env.sh"
PROTECTED_RE=${PROTECTED_RE:-'(expected|golden)[^/]*\.(json|bin)$'}
for meta in "$ORCH"/state/*.meta(N); do
  id=${meta:t:r}; wt="$ORCH_WT/$id"; log="$ORCH/logs/$id.log"
  [[ -f $log ]] || continue
  grep -q "^exit" "$meta" && continue  # only running workers
  hits=()
  grep -qE '(>|cp |mv |mkdir[^\n]*|write_text\(|open\()[^\n]*/tmp/' "$log" && hits+=("writes-/tmp")
  grep -qE '(-lc|\$ ).*git (push|reset --hard|rebase|commit --amend|stash)' "$log" && hits+=("git-history/push")
  git -C "$ORCH_MAIN" status --porcelain | grep -vqE '^\?\? (orchestra|worktrees)/' && hits+=("MAIN-dirty")
  changed=$(git -C "$wt" diff --name-only "$ORCH_BASE" 2>/dev/null; git -C "$wt" status --porcelain 2>/dev/null | cut -c4-)
  echo "$changed" | grep -qE "$PROTECTED_RE" && hits+=("touches-protected")
  scratch=$(du -sk "$wt/orchestra/state" 2>/dev/null | cut -f1); (( ${scratch:-0} > 5242880 )) && hits+=("scratch>5GiB")
  # repetition: same tool command issued many times recently
  rep=$(tail -c 200000 "$log" | grep -E '^\s*(\$ |bash -lc)' | sort | uniq -c | sort -rn | awk '$1>=8{print $1}' | head -1)
  [[ -n $rep ]] && hits+=("repeating-cmd x$rep")
  (( ${#hits} )) && echo "$id: ${hits[*]}"
done
exit 0
