# Palbahngmiyine's Toolbox

Agent tooling for running a software factory on a small token budget.

| Path | Purpose |
|---|---|
| `skills/software-factory` | Takes one issue from spec to a merged pull request with deterministic gates first and one independent review. |
| `skills/conventional-commit` | Writes Conventional Commits messages. |
| `skills/fork-pr` | Opens a pull request from a fork to its upstream. |
| `skills/evening-socratic-journal` | Turns the day's agent sessions into a journal entry through questions. |
| `hooks/quiet-checks.sh` | Sends test, lint, and build output to a log file and shows the agent only the tail. |
| `hooks/secret-guard.sh` | Blocks a prompt, shell command, or file write that carries a token, webhook URL, or private key. |

## Install

Link a skill into the agent's skill directory:

```bash
ln -s "$PWD/skills/software-factory" ~/.claude/skills/software-factory
```

Register the hooks in `~/.claude/settings.json`, replacing the path with this checkout:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      { "hooks": [{ "type": "command", "command": "/path/to/toolbox/hooks/secret-guard.sh" }] }
    ],
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [{ "type": "command", "command": "/path/to/toolbox/hooks/quiet-checks.sh" }] },
      { "matcher": "Bash|Write|Edit", "hooks": [{ "type": "command", "command": "/path/to/toolbox/hooks/secret-guard.sh" }] }
    ]
  }
}
```

A recognized check prints its last 5 lines on success and its last 80 on failure, followed by the exit status and the log path. Set `QUIET_CHECKS_OK_LINES` or `QUIET_CHECKS_FAIL_LINES` to change the counts. Prefix a command with `QUIET_CHECKS=0` to run it untouched.

`secret-guard.sh` matches known credential prefixes, not arbitrary strings. A blocked prompt is not sent to the model, but it can stay in local prompt history, so rotate a real credential. Start the agent with `SECRET_GUARD=0` to turn it off.
