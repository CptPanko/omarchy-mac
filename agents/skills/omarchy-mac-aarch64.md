# Omarchy Mac / aarch64 development

Required reading for every change in this repository.

The packaged skill agents pick up on an installed system (Claude, Codex, Gemini, Pi, and `~/.agents/skills`) is:

[`default/agents/skills/omarchy-mac-dev/SKILL.md`](../../default/agents/skills/omarchy-mac-dev/SKILL.md)

`omarchy-provision-user` symlinks every directory under `default/agents/skills/` into the editor skill paths. Keep new Mac development rules in that skill so a `omarchy dev link` checkout is what agents see.

This file exists so the contributor tree in `agents/skills/` matches the other task guides listed in `AGENTS.md`.
