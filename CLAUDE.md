# TokenTracker iOS App

## Simulator

Always run/test on **iPhone 17 Pro, iOS 26.4**.

Simulator ID: `A7C379CB-F8F9-45B6-99DC-D86831629AB8`

Build command:
```bash
xcodebuild build -scheme TokenTracker \
  -destination "id=A7C379CB-F8F9-45B6-99DC-D86831629AB8" \
  -sdk iphonesimulator \
  -configuration Debug CODE_SIGNING_ALLOWED=NO
```

## Project Structure

- `TokenTracker/TokenTrackerApp.swift` — entry point, auto-syncs on launch
- `TokenTracker/Models/TokenModels.swift` — data models
- `TokenTracker/Views/` — DashboardView, SettingsView, ContentView, etc.
- `TokenTracker/ViewModels/TokenStore.swift` — all state, sync logic, persistence
- `TokenTracker/Services/APIService.swift` — fetches from Mac server (port 8765)
- `TokenTracker/Services/KeychainService.swift` — secure API key storage

## Mac Server

The local sync server lives at `~/.claude/tokentracker/server.py` and must be running on the Mac.
It reads `~/.claude/projects/**/*.jsonl` and serves token usage at `http://<machost>:8765/usage.json`.

- Weekly reset: every **Friday at 6pm local time** (matches Claude Code)
- 5-hour window: rolling
- Default host in app: `Jiradets-MacBook-Pro.local`
