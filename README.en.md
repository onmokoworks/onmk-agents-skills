# onmk-agents-skills

Skills for coding agents.

[日本語](README.md)

## Claude Code

| Skill | What it does |
| --- | --- |
| [codex-orchestration](claude-code/codex-orchestration/SKILL.md) | Claude Code acts as the orchestrator and runs Codex CLI workers in parallel, one git worktree per ticket |

To use a skill, copy its folder into `~/.claude/skills/` or symlink it.

```sh
ln -s "$PWD/claude-code/codex-orchestration" ~/.claude/skills/codex-orchestration
```

The scripts run under zsh on macOS. They use `memory_pressure` and `stat -f`, so they will not run on Linux as is.

The skill text is in Japanese.
