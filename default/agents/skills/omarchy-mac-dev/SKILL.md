---
name: omarchy-mac-dev
description: REQUIRED for Omarchy Mac source development on Apple Silicon aarch64. Use when editing this repo, merging upstream Omarchy, writing install or migration scripts, changing pacman configs or package lists, touching hardware setup, or running upgrades. Stops x86-only scripts and repos from breaking aarch64.
license: MIT
metadata:
  audience: development
  platform: asahi-alarm-aarch64
---

# Omarchy Mac development

This repository is the Apple Silicon fork of Omarchy. The target is Asahi Alarm (Arch Linux ARM) on M-series Macs, not upstream x86 Omarchy and not macOS.

Read this skill before editing anything. The end-user skill at `default/agents/skills/omarchy/SKILL.md` is for installed-system customization and explicitly excludes source development.

Deeper lists live next to this file:

- [`references/x86-blocklist.md`](references/x86-blocklist.md) — commands, packages, repos, and scripts that must not run as-is on aarch64
- [`references/apple-divergences.md`](references/apple-divergences.md) — intentional Mac behavior that is not a bug

## Always-on facts

- Default development branch is `quattro` (Omarchy 4). `main` still carries Omarchy 3.x. `cat version` must start with `4.` before treating a tree as current.
- `install.sh` refuses to run unless `uname -m` is `aarch64`. There is no upstream ISO for this hardware.
- Runtime path is `$OMARCHY_PATH` (`/usr/share/omarchy`, directory or symlink). Do not invent paths from `$HOME/.local/share/omarchy` except as the documented checkout/build source.
- Fresh Quattro installs build the `omarchy` / `omarchy-settings` packages from this checkout (`build-packages.sh` then `pacman -U`). 3.x-to-4 upgrades keep running from the checkout and symlink `/usr/share/omarchy` at it. See `docs/upgrade-to-quattro.md`.
- Contributor task guides stay in `agents/skills/`. Packaged agent skills stay in `default/agents/skills/*/`. `omarchy-provision-user` symlinks every packaged skill directory into `~/.agents/skills`, `~/.claude/skills`, `~/.codex/skills`, `~/.pi/agent/skills`, and `~/.gemini/config/skills`.

## Hard stop — do not do these

Stop and rewrite the change if you are about to:

1. Point pacman at `pkgs.omarchy.org` or any `omarchy.org` mirror. Those repos are x86_64 only. The aarch64 replacement is `[omarchy-aarch64]` with `Server = https://github.com/omarchy-mac/omarchy-pkgs-aarch64/releases/download/edge`.
2. Drop `Architecture = aarch64` from any shipped `default/pacman/pacman*.conf`. A config that omits it inherits `uname` today and silently becomes x86 the next time upstream defaults are merged.
3. Ship a pacman config that has `Architecture = aarch64` but no `[omarchy-aarch64]` block. Without that block, `herdr` builds `zig0.15` for hours and aarch64 rejects it.
4. Run or recommend `omarchy-upgrade-to-quattro` on this fork. It rewrites `/etc/pacman.d/mirrorlist` to x86 Omarchy mirrors. The Mac command is `omarchy-upgrade-to-quattro-mac`. The x86 command already fences itself with `uname -m`; do not remove that guard.
5. Install or require `lib32-*`, NVIDIA userspace (`nvidia-utils`, `nvidia-open-dkms`, `libva-nvidia-driver`, `force-igpu`), Intel Panther Lake packages, `gpu-screen-recorder` as the Asahi backend, MSSQL, or the Windows VM stack.
6. Call `omarchy-windows-vm install` (or treat a refusal as a bug). The command exits on `aarch64`/`arm64` on purpose.
7. Install 1Password from the AUR PKGBUILD. That PKGBUILD is x86_64-only. Use `bin/omarchy-install-1password`, which pulls the official `aarch64` tarball.
8. Add packages to `install/omarchy-base.packages` that have no ARM build without also listing the expensive ones in `install/omarchy-aarch64-unavailable.packages`. Cheap arch-check failures can skip via `omarchy-pkg-add`; multi-hour fail-chains must be on the unavailable list.
9. Put `herdr`, `omacalc`, `omacut`, or `omawrite` on the unavailable list. Those come from the ARM repo and skipping them breaks the install.
10. Touch the macOS APFS container, the Asahi `m1n1`/U-Boot boot chain, or dual-boot partition layout except through the documented `bin/omarchy-mac-setup` / `docs/btrfs.md` path.
11. Treat Limine or GRUB as the Asahi bootloader of record. Encrypted machines must keep `/boot` on the EFI partition; leaving GRUB modules on an encrypted root is how machines land in `grub rescue>`.
12. File or "fix" these as bugs: notch-height bar sizing, `hid_apple fnmode=1` media keys, Shift+brightness for keyboard backlight, `wf-recorder` capture on the Asahi GPU, Spotify as a webapp, Codeberg/GitHub update remotes.

## Merge and upstream hygiene

This tree tracks `basecamp/omarchy` and keeps many x86 hardware leaves (`install/hardware/nvidia.sh`, `install/hardware/intel/*`, Framework/ASUS/Dell/Surface/T2). Those leaves are allowed to exist so merges stay small. They are not allowed to become required on Apple Silicon.

When merging upstream:

- Re-run `./test/shell.d/aarch64-compat-test.sh` and `./test/shell.d/aarch64-packages-test.sh` before calling the merge done.
- Keep every shipped `default/pacman/pacman*.conf` on `Architecture = aarch64` with `[omarchy-aarch64]` and without `pkgs.omarchy.org`.
- Keep `bin/omarchy-pkg-add` skipping packages `pacman -Si` cannot see. Migrations must install packages through that helper so x86-only names warn and continue instead of aborting `omarchy update`.
- Keep `install/hardware/all.sh` calling the Apple leaves (`install/hardware/apple/*.sh`). Do not delete x86 leaves just to look tidy; do not make them unconditional package installs.
- Do not copy upstream ISO orchestration assumptions. This repo ships target-side setup. Fresh machines come from Asahi Alarm + `bin/omarchy-mac-setup` or `install.sh`, not from an Omarchy ISO.

## Install, packages, and repos

- Package helpers: `omarchy-pkg-add` / `omarchy-pkg-drop`. Never raw `pacman -R*`.
- Unavailable-by-default today (measured fail-chains): `obs-studio`, `dotnet-runtime`, `pinta`, `obsidian`. Override with `OMARCHY_TRY_UNAVAILABLE=1`. Drop an entry once it actually builds on ARM.
- Obsidian on this fork is `install/user/hardware/apple/obsidian.sh` (name/appimage problem, not a missing port).
- `wf-recorder` is the Asahi screen-recorder. `bin/omarchy-capture-screenrecording` selects it when the machine is Apple Silicon. Do not "upgrade" that path to `gpu-screen-recorder`.
- Docker DB menu omits MSSQL on non-x86_64 (`bin/omarchy-install-docker-dbs`). Do not add it back for Mac.
- Publish ARM packages with `bin/omarchy-pkg-publish-aarch64`, not the x86 omarchy-pkgs pipeline.

## Hardware and desktop

Apple-only setup lives under `install/hardware/apple/` and `install/user/hardware/apple/`:

- `enable-notch.sh` — `options appledrm show_notch=1` so the bar can use the strip beside the notch
- `audio.sh` / Asahi audio — not the NVIDIA/SOF/Intel IPU paths
- `fix-asahi-hid-race.sh`, `fix-brcmfmac-supplicant.sh`, `fix-spi-keyboard.sh`, `fix-suspend-nvme.sh`, `fix-t2.sh`

Display brightness and focused-monitor helpers are the `*-apple` binaries (`omarchy-brightness-display-apple`, `omarchy-hyprland-monitor-focused-apple`). Prefer those over generic x86 helpers when the hardware is Apple.

## Tests that must stay green

From the repo root, after any install/pacman/migration/hardware/upgrade change:

```bash
./test/shell.d/aarch64-compat-test.sh
./test/shell.d/aarch64-packages-test.sh
./test/all
bin/omarchy commands --check
```

`./test/all` is CLI + shell only. Graphical acceptance stays in a disposable VM (`agents/skills/acceptance-tests.md`). Do not run acceptance against the live development session.

CI (`.github/workflows/main.yml`) is ARM64-only (`ubuntu-24.04-arm`). Do not add an x86 runner that installs or executes this tree as if it were upstream Omarchy.

## Style and process

Follow `AGENTS.md` for bash style, command naming, privilege escalation, and the SWE → QA → Review loop. Extra Mac rules:

- Shebangs are `#!/bin/bash`.
- `install/` and `migrations/` leaves may omit shebangs because they are sourced.
- Atomic commits. Do not mix an upstream merge with a Mac-only behavior change.
- Dual-boot work goes through `docs/btrfs.md` and `bin/omarchy-mac-setup`. Do not invent a second encryption or boot-layout path.
