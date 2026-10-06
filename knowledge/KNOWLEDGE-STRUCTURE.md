# Knowledge Structure

Put each kind of project information in one clear place so people and AI tools can find it.

| Type | Put here | Examples |
| --- | --- | --- |
| Shared rules | Rules that apply to many tasks and links to more detail | Root or folder-level `AGENTS.md`, tool-specific `CLAUDE.md` |
| Project facts | Information that explains this project | Design notes, system limits, agreed decisions |
| Reusable tools | Files that run or check work | Scripts, skills, templates, test and CI checks |
| Current work | Files for one feature or task | Requirements, plans, tasks, prompts, test notes; `.todo/` for private scratch notes |

## Rules

- Keep root guidance files short. Link to details instead of copying them all into `AGENTS.md`.
- Put project facts in project docs. Put reusable commands and checks in scripts, skills, or CI.
- Keep each feature's files together. Commit the files the team needs to review or continue the work; do not keep them only in chat.
- Use `.todo/` for private scratch notes, not team decisions. It is ignored by Git; move useful decisions into project docs.
- Remove stale working notes when they no longer help. Do not store credentials or sensitive data in any layer.

## Related

- [Agent instructions](../AGENTS.md)
- [README](./README.md)
- [Repeatable repo workflow](./REPO-WORKFLOW.md)
- [Skills and scripts](../skills/README.md)
