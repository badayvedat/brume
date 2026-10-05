# Changelog

What changes in each version of Brume. The newest version comes first.

## 0.1.0 - Unreleased

### Added
- A terminal built on the Ghostty engine: tabs in the top bar or in a vertical sidebar, splits grouped inside a tab, search, text zoom, and your windows and tabs restored on relaunch.
- Tabs with a name, a color and an icon, reordered by dragging, with ⌘1 to ⌘9 shown while ⌘ is held.
- A badge on each tab that follows Claude Code and long commands: progress, finished, bell.
- Command highlighting, suggestions from history and a Tab completion menu, on by default.
- Settings inside the window: glass effect, 10 accent colors, 12 fonts, 16 command color palettes, English and French.
- A welcome screen in every new terminal: a pixel-art visual tinted with your accent color, a word in large letters, and your Mac's information.
- Full Path in Tabs (Settings › General) shows a tab's folder from your home folder, like ~/Desktop/project, instead of its name alone. Renamed tabs keep their name.
- Keyboard shortcuts you can change in Settings › Shortcuts, for tabs, splits and vertical tabs, with a warning when a combination is already taken.
- ⌃Tab and ⌃⇧Tab switch tabs, Clear Screen (⌘K) in the Edit menu, and a Help menu with links to Brume on GitHub and to report an issue.
- A confirmation before closing a terminal where a command is still running.
- Drop files or folders from Finder onto a terminal to type their paths at the cursor, escaped for the shell. In a split, they go to the terminal under the pointer. Dropped text is pasted as is.
- Reset Window (⌥⌘R, or Settings › General) brings a window back to a single tab with default names, colors and size, after a confirmation. Your settings are kept.
- SSH sessions keep working with servers that don't know Ghostty's terminal type.
- An app icon and a DMG to install Brume by dragging it to Applications.
- Automatic updates, and a button to check for updates in Settings › General.

### Fixed
- With vertical tabs on, a new window opens wider to make room for the sidebar, so the terminal and its welcome screen keep their full size.
