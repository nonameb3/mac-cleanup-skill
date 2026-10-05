---
name: mac-disk-cleanup
description: Use when a macOS disk is nearly full, "System Data" is huge, free space is low, or the user asks what is using disk space and how to reclaim it safely on a developer Mac (Docker, OrbStack, node_modules, Xcode, Android, package caches).
---

# Mac Disk Cleanup (Safe-Only)

## Overview
Analyze first, delete only with confirmation, and never touch risky data. Every run follows four phases, in order:

1. **Summary**: a read-only analysis of who uses the disk, grouped by type
2. **Confirm**: the user picks which safe items to clean
3. **Summary after**: what was freed, measured before and after each step
4. **Summary remaining**: what is left, with risky items listed but never acted on

## Hard Rules
- Phase 1 is read-only: `df`, `du`, `ls`, `find`, `stat`, `sysctl`, `docker system df`, `diskutil`. No `rm` and no prune.
- Delete nothing until the user explicitly names the items. If they approve a group, that approval covers only that group.
- Before deleting an app's cache, check that the app is closed (`pgrep -fl "<App>.app"`). If it's running, skip the item and say so.
- Prefer each tool's own clean command (`npm cache clean --force`, `brew cleanup -s`, `docker builder prune`) over `rm`.
- Delete exact paths only, and list them first. Don't use globs on user folders.
- Measure free space before and after every step. Report honestly, including when a step freed nothing.
- Never act on 🔴 risky items. Only list them in Phase 4.

## Phase 1: Analyze
Run `bash scripts/analyze.sh`. It is read-only and takes a few minutes. Then present one table **by type**, with GB and %:
developer tools/caches, Docker/OrbStack, swap (VM volume), applications, user files, other app data, macOS system, **unmeasured**, and free.

Unmeasured = `Data volume used − sum of du`. This is space `du` can't see because macOS privacy protection blocks the terminal. To measure it without Full Disk Access, run `bash scripts/finder-size.sh <paths…>`. Finder opens Get Info windows to read the sizes, so the user may need to allow "Terminal wants to control Finder". Usual suspects: OrbStack/Docker group containers, LINE, Trash, Mail, Messages, Office/Teams, CoreSpotlight.

## Risk Tiers
| Tier | Items | Action |
|---|---|---|
| 🟢 Safe | npm/yarn/pnpm/pip/brew/go/CocoaPods caches, `~/Library/Caches/{JetBrains,ms-playwright,goimports,com.apple.python,typescript}`, Xcode DerivedData, `*.hprof` crash dumps, `.dmg`/`.pkg` installers in Downloads, Trash, `docker builder prune`, old VS Code extension versions not listed in `extensions.json`, `*.ShipIt` update leftovers (app closed) | Clean after confirmation |
| 🟡 Redo-later | `node_modules` untouched for 3+ months (show the list), `docker image prune -a`, `~/.gradle/caches`, puppeteer and codex runtime caches | Clean after confirmation of the exact list |
| 🟠 Ask | iOS simulators, Android AVD and system images, old Go/Node versions, data from uninstalled apps (e.g. Docker Desktop `Docker.raw` when OrbStack is the active context) | Only if the user says they don't use it |
| 🔴 Risky | Docker volumes, project source, Documents/Desktop files, non-installer Downloads, Mail/Messages/LINE data, other user accounts | Never act. List in Phase 4 only. |

## Gotchas (learned in practice)
- **Swap**: if `sysctl vm.swapusage` shows a high value and the Mac has been up for a long time, restarting frees that space. Suggest it and never force it, because the user may have work open. Swap also shrinks on its own after apps close.
- **Two Docker engines**: compare `docker context ls` with the modified time of `~/Library/Containers/com.docker.docker/Data/vms/0/data/Docker.raw`. `ls` shows that file's maximum size, so use `du` to get the real size.
- **App sandbox containers**: Finder refuses to delete them with "no permission". `rm` on the large files inside works, but the container's metadata plist stays. That leftover is harmless.
- **Trash**: the terminal gets "Operation not permitted". Measure it with `finder-size.sh`, and empty it with `osascript -e 'tell application "Finder" to empty trash'`.
- **VS Code** removes old extension versions itself when it reloads. Check again before deleting.
- **Side effects to mention**: Playwright needs `npx playwright install`, Rider re-indexes, and the first builds are slower.

## Phase 3–4 Report Shape
After cleaning: a table of `item | freed`, plus a progress table of `step | free GB`. Then the remaining items, grouped by tier, each with its size and the question the user needs to answer. Finish with a one-line health verdict.
