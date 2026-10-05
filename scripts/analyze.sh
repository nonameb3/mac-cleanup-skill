#!/usr/bin/env bash
# Read-only disk analysis for macOS. Never deletes or modifies anything.

dataVolume="/System/Volumes/Data"

printSection() { printf "\n== %s ==\n" "$1"; }
sizeOf() { du -sh "$@" 2>/dev/null | sort -rh; }
existingPaths() { for candidatePath in "$@"; do [ -e "$candidatePath" ] && echo "$candidatePath"; done; }

printSection "Disk"
df -h / "$dataVolume" | sed 1d
diskutil apfs list 2>/dev/null | grep -E "Name:|Capacity Consumed" | sed 's/^[ |]*//' | paste - -

printSection "Swap and uptime"
sysctl -n vm.swapusage
uptime

printSection "Data volume top-level (du can't see protected folders)"
(cd "$dataVolume" && du -shx -- * 2>/dev/null | sort -rh | head -10)

printSection "Home top 25"
(cd "$HOME" && du -sh -- * .[!.]* 2>/dev/null | sort -rh | head -25)

printSection "Library breakdown"
sizeOf "$HOME"/Library/{Containers,Application\ Support,Caches,Developer,Android,pnpm} | head -10
sizeOf "$HOME"/Library/Caches/* | head -15
sizeOf "$HOME"/Library/Application\ Support/* | head -10

printSection "Applications top 15"
sizeOf /Applications/* | head -15

printSection "Docker / OrbStack"
docker context ls 2>/dev/null
docker system df 2>/dev/null
dockerDesktopDisk="$HOME/Library/Containers/com.docker.docker/Data/vms/0/data/Docker.raw"
if [ -f "$dockerDesktopDisk" ]; then
  echo "Docker Desktop disk: $(du -sh "$dockerDesktopDisk" | cut -f1) real, last modified $(stat -f '%Sm' "$dockerDesktopDisk")"
  [ -d /Applications/Docker.app ] || echo "Docker.app is NOT installed (orphaned data)"
fi

printSection "Developer caches"
sizeOf $(existingPaths "$HOME/.npm" "$HOME/.gradle/caches" "$HOME/.nuget/packages" "$HOME/.cache"/* \
  "$HOME/Library/Developer/Xcode/DerivedData" "$HOME/Library/Developer/CoreSimulator/Devices" \
  "$HOME/.android/avd" "$HOME/Library/Android/sdk"/* "$HOME/go"/* "$HOME/.goenv/versions"/* "$HOME/.nvm/versions/node"/*) | head -20

printSection "VS Code extensions"
sizeOf "$HOME/.vscode/extensions"
python3 - <<'EOF' 2>/dev/null
import json, os, re
extensionsDir = os.path.expanduser("~/.vscode/extensions")
activeFolders = {entry["relativeLocation"] for entry in json.load(open(os.path.join(extensionsDir, "extensions.json")))}
versionPattern = re.compile(r"^(.+?)-(\d+\.\d+\.\d+.*)$")
activeIds = {versionPattern.match(name).group(1) for name in activeFolders if versionPattern.match(name)}
oldFolders = [name for name in os.listdir(extensionsDir)
              if versionPattern.match(name) and name not in activeFolders and versionPattern.match(name).group(1) in activeIds]
print(f"{len(oldFolders)} old extension versions not in extensions.json")
for name in sorted(oldFolders): print("  old:", name)
EOF

printSection "Installers and crash dumps"
find "$HOME/Downloads" -maxdepth 2 -type f \( -iname "*.dmg" -o -iname "*.pkg" -o -iname "*.pkg.zip" \) -exec du -sh {} + 2>/dev/null | sort -rh
find "$HOME" -maxdepth 2 -type f -iname "*.hprof" -exec du -sh {} + 2>/dev/null

printSection "node_modules by last project change (oldest first)"
find "$HOME/Documents" -name node_modules -type d -prune 2>/dev/null | grep -vE "/\.(next|cxx)/" | while read -r nodeModulesPath; do
  projectPath=$(dirname "$nodeModulesPath")
  lastChange=$(find "$projectPath" -path "*/node_modules" -prune -o -path "*/.git" -prune -o -type f -print0 2>/dev/null \
    | xargs -0 stat -f "%m" 2>/dev/null | sort -rn | head -1)
  sizeKb=$(du -sk "$nodeModulesPath" 2>/dev/null | cut -f1)
  printf "%s\t%6.1f GB\t%s\n" "$(date -r "${lastChange:-0}" +%Y-%m-%d)" "$(echo "$sizeKb/1048576" | bc -l)" "${projectPath/#$HOME/~}"
done | sort

printSection "Running apps (skip their caches)"
for appName in "Google Chrome" Rider Xcode "Visual Studio Code" "Android Studio" Bruno Docker OrbStack Slack; do
  pgrep -fq "/$appName.app/Contents/MacOS" && echo "RUNNING: $appName"
done

printSection "Protected (measure with finder-size.sh)"
du -sh "$HOME" 2>&1 >/dev/null | grep -E "not permitted|denied" | sed -E 's#^du: ##; s#: (Operation not permitted|Permission denied)##' \
  | grep -E "/\.Trash$|/Library/(Mail|Messages|Safari)$|Group Containers/" | grep -v "group\.com\.apple\." | head -25
