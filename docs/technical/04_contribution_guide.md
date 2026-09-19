# Contribution Guide

See `AGENTS.md` for the conventions. This file covers the three procedures.

## Add a skill

1. Pick a category: `data-engineering`, `engineering`, `experimenting`, `productivity`, `brand`.
2. `mkdir -p skills/<category>/<name>` — kebab-case name.
3. Write `SKILL.md` with the frontmatter:

   ```yaml
   ---
   name: <name>
   description: One sentence saying when to use this skill.
   ---
   ```

   The description is what the model matches against, so name the triggers, not the internals.
4. Optional subfolders: `scripts/`, `references/`, `templates/`, `assets/`.
5. Link it live: `./scripts/link-skills.sh <name>`.
6. Refresh the README catalogue: `./scripts/list-skills.sh`.

## Archive a skill

A skill that is no longer used but still worth keeping:

1. `git mv skills/<category>/<name> skills/archive/<name>`.
2. Remove the live symlink: `rm ~/.claude/skills/<name>` (it is a symlink — this deletes nothing
   else).
3. Note it in `skills/archive/ARCHIVE.md`: why it was dropped, and the date.
4. `./scripts/list-skills.sh` to refresh the catalogue.

Third-party skills are never archived. Delete them and credit the upstream project in `README.md`.

## Fork a third-party skill

Only vendor someone else's skill if you actually change it. Unmodified, install it at user scope
from upstream instead.

1. Copy the skill in, under the right category. Rename it if the local name is clearer — record the
   rename.
2. Add the upstream licence text to `LICENSES/<project>-<licence>.txt` if it is not already there.
3. Make the changes.
4. Write `FORK.md` next to `SKILL.md`:

   - upstream project and path;
   - the upstream commit or date compared against;
   - each local change, specific enough to re-apply by hand;
   - ending with: "Do not refresh this skill blindly from upstream: re-apply these changes after
     any refresh."
5. Credit the project in the README's **Derived from** section.

Refreshing later means diffing against the new upstream, then re-applying every line in `FORK.md`
and updating its comparison commit.
