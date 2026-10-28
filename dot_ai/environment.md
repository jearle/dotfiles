# Environment

## Shell: Directory Navigation
- `z` (zoxide) may be undefined in non-interactive shells. Fallback: `cd "$(zoxide query -- <term>)"`, or use absolute paths.
- Directory changes may not persist across separate tool calls. Chain navigation with the command in one invocation: `z <term> && <command>`.

## Notification Provider Dispatch
- Check for user notification dispatch command: `$ODVA_NOTIFY_CMD`, `~/.local/bin/message-discord`, or `~/.local/bin/notify`.
- If present, use it to send execution milestone notifications per repository conventions.
- If absent, skip silently.

## Review and Subagent Models
- Fast exploration and adversarial review model: `agy-flash-high` (`gemini-3.8-flash` / `flash`).
- Lead orchestration model: `claude-opus-max` (`agent-agentic-coding`) or `claude-sonnet-5-max`.
