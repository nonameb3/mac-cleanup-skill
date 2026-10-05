# mac-disk-cleanup

A Claude Code skill that finds what is filling your Mac's disk and frees space **safely**. It analyzes first, deletes only what you approve, and never touches risky data.

Built for developer Macs: Docker / OrbStack, `node_modules`, Xcode, Android, Go, and npm/yarn/pnpm/brew caches.

## How it works

Every run follows the same four steps:

| Step | What happens |
|---|---|
| 1. **Summary** | Read-only scan, then a "who uses the disk, by type" table (GB and %) |
| 2. **Confirm** | You choose which safe items to clean. Nothing is deleted before this. |
| 3. **Summary after** | Space freed per item, measured before and after each step |
| 4. **Summary remaining** | What's left, grouped by risk. Risky items are listed only. |

## Safety rules

- The analysis is **100% read-only**.
- Nothing is deleted without your explicit approval for that item.
- The caches of open apps are skipped (for example Chrome, VS Code, Bruno).
- Each tool's own clean command is used first (`npm cache clean`, `brew cleanup`, `docker builder prune`).
- 🔴 **Never touched**: Docker volumes, project source, Documents/Desktop files, Mail/Messages/LINE data, and anything in Downloads that isn't an installer.

## Risk tiers

| Tier | Examples |
|---|---|
| 🟢 Safe | Package manager caches, Xcode DerivedData, JetBrains caches, `.hprof` crash dumps, `.dmg`/`.pkg` installers, Trash, Docker build cache |
| 🟡 Redo later | Old `node_modules` (shown as a list first), unused Docker images, Gradle cache |
| 🟠 Ask first | iOS simulators, Android emulators, old Go/Node versions, data from uninstalled apps |
| 🔴 Never | Docker volumes, your files, personal app data |

## Install

Clone straight into your Claude Code skills folder:

```bash
git clone https://github.com/nonameb3/mac-cleanup-skill.git ~/.claude/skills/mac-disk-cleanup
```

To update, run `cd ~/.claude/skills/mac-disk-cleanup && git pull`.

## Usage

In Claude Code, run:

```
/mac-disk-cleanup
```

Or just say *"my disk is almost full"*, and the skill loads automatically.

You can also run the scripts on their own. Both are read-only:

```bash
bash scripts/analyze.sh                 # full scan, takes ~3–4 min
bash scripts/finder-size.sh ".Trash"    # size of protected folders, read through Finder
```

## Files

```
mac-disk-cleanup/
├── SKILL.md              # Workflow and rules Claude follows
├── README.md
├── LICENSE
└── scripts/
    ├── analyze.sh        # Read-only full disk scan
    └── finder-size.sh    # Measures folders the terminal can't read
```

## Requirements

- macOS (tested on macOS 26, Apple Silicon)
- Claude Code
- Optional: `docker` CLI (OrbStack or Docker Desktop), `python3` (for the VS Code extension check)

## Notes

- **Protected folders**: macOS blocks the terminal from reading Mail, Messages, Trash and some app containers. `finder-size.sh` asks Finder for their sizes instead, and you may see a one-time *"Terminal wants to control Finder"* prompt. Allowing it lets the script read sizes only.
- **Swap**: if your Mac has been running for weeks, swap can use 20–40 GB. A restart frees it. The skill suggests this but never forces it.
- **After cleaning**: the first `npm install`, `go build` or Docker build will be slower while caches refill. Playwright needs `npx playwright install`.

## License

MIT. See [LICENSE](LICENSE). Provided as-is: review what the skill proposes before approving any deletion.
