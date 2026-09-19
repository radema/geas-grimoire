# Local configuration

These files are intentionally not versioned — they hold site-specific names.
Create the ones you need; every collector works without them.

| File | Env var override | Contents |
|---|---|---|
| `repos.txt` | `MORNING_BRIEF_REPOS` | absolute paths of the repositories to watch. Absent: every git repo directly under `$HOME`. |
| `projects.txt` | `MORNING_BRIEF_PROJECTS` | Jira project keys. Absent: every project the account can see. |
| `team.txt` | `MORNING_BRIEF_TEAM` | colleague email addresses whose unowned tickets should surface. Absent: your own only. |
| `ignore.txt` | — | branches and worktrees the brief must never mention (versioned, see the file's header). |

One entry per line, `#` starts a comment. The env vars take the same entries
comma-separated and win over the file.
