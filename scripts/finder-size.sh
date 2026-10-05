#!/usr/bin/env bash
# Read-only: asks Finder for folder sizes the terminal can't read (macOS privacy protection).
# Usage: bash finder-size.sh "<path>" ["<path>" ...]   (paths relative to $HOME or absolute)

[ $# -eq 0 ] && set -- \
  "Library/Group Containers/HUAQ24HBR6.dev.orbstack" \
  "Library/Group Containers/group.com.docker" \
  "Library/Group Containers/VUTU7AKEUR.jp.naver.line.mac" \
  ".Trash" "Library/Mail" "Library/Messages" \
  "Library/Group Containers/UBF8T346G9.Office" \
  "Library/Group Containers/UBF8T346G9.com.microsoft.teams" \
  "Library/Metadata/CoreSpotlight"

for targetPath in "$@"; do
  case "$targetPath" in /*) fullPath="$targetPath" ;; *) fullPath="$HOME/$targetPath" ;; esac
  [ -e "$fullPath" ] || { echo "missing	$targetPath"; continue; }
  osascript - "$fullPath" "$targetPath" <<'EOF'
on run argv
	set fullPath to item 1 of argv
	set displayPath to item 2 of argv
	tell application "Finder"
		set folderItem to (POSIX file fullPath) as alias
		open information window of folderItem
		set sizeBytes to missing value
		repeat 120 times
			set sizeBytes to physical size of folderItem
			if sizeBytes is not missing value then exit repeat
			delay 1
		end repeat
		try
			close information window of folderItem
		end try
	end tell
	if sizeBytes is missing value then return "timeout" & tab & displayPath
	return ((round (sizeBytes / 1.0E+7)) / 100 as text) & " GB" & tab & displayPath
end run
EOF
done
