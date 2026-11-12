> 100% Vibecode: planned, implemented and documented by Claude Opus 5.5

# ZoneFlip

**Several extra time zones in one menu bar slot, flipping like a rotating license plate.**

A second-clock app shows one extra time zone next to the system clock. ZoneFlip shows several of them in the same spot, one at a time: every few seconds the label flips over and the next zone appears.

```
NY 09:32   →   TYO 23:32   →   UTC 14:32   →   NY 09:32 ...
```

Inspired by [Second Clock](https://sindresorhus.com/second-clock), which shows a single extra zone.

## What It Does

- Shows `<label> <time>` in the menu bar, for example `NY 09:32`
- Switches to the next zone every 5 seconds (configurable, 1–120 s) with a flip animation
- Updates the time in place, without flipping, when the minute changes
- Click the label to see all zones at once, open Settings or quit
- Follows the system 12/24-hour setting

## Build

Requires the Xcode Command Line Tools (Swift 5.10 or later).

```bash
./build.sh
```

This produces an ad-hoc signed `ZoneFlip.app` next to the script.

## Install

```bash
cp -R ZoneFlip.app /Applications/
open /Applications/ZoneFlip.app
```

There is no Dock icon: the app lives only in the menu bar. Quit it from its menu.

## Settings

Click the label → **Настройки…** (the UI is in Russian).

- **Label** — free text shown before the time, for example `NY` or a flag emoji (⌃⌘Space opens the emoji picker)
- **Time zone** — any zone from the system list
- **↑ / ↓** — change the order
- **Interval** — seconds between flips
- **Launch at login** — registers the app as a login item

## Compatibility

- Built and tested on macOS 26 (Tahoe)
- The deployment target is macOS 14, but it has not been tested there

## License

MIT
