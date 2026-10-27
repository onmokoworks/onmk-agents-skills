# onmk-agents-skills

コーディングエージェント向けに作ったスキルを置いています。

[English](README.en.md)

## Claude Code

| スキル | 内容 |
| --- | --- |
| [codex-orchestration](claude-code/codex-orchestration/SKILL.md) | Claude Code が指揮役になり、Codex CLI のワーカーを git worktree で並列に動かす |

使うときは、スキルのフォルダーを `~/.claude/skills/` にコピーするか、シンボリックリンクを張ります。

```sh
ln -s "$PWD/claude-code/codex-orchestration" ~/.claude/skills/codex-orchestration
```

スクリプトは macOS の zsh で動かしています。`memory_pressure` や `stat -f` を使っているので、Linux ではそのままでは動きません。
