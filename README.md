# TokenTracker

An iOS app built with SwiftUI that shows your Claude Code token usage in real time — matching the same 5-hour and weekly limits displayed in Claude Code itself.

![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-blue)
![Swift](https://img.shields.io/badge/swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

---

## Screenshots

| Plan Usage | Settings |
|---|---|
| <img src="docs/dashboard.png" width="220"/> | <img src="docs/settings.png" width="220"/> |

---

## How It Works

```
~/.claude/projects/**/*.jsonl   ←  Claude Code writes token usage here
         ↓
  Mac server (port 8765)        ←  Python script reads & aggregates
         ↓
   TokenTracker iOS app         ←  Fetches over local Wi-Fi, displays live
```

1. **Mac server** — a lightweight Python HTTP server reads Claude Code's JSONL session files and serves aggregated token counts as JSON.
2. **iOS app** — connects to the Mac over your local network, displays usage against your plan limits with progress bars and reset timers.

Both the 5-hour rolling window and weekly reset (every **Friday at 6 pm local time**) match Claude Code's exact rate-limit behavior.

---

## Requirements

- **Mac** running the sync server (macOS 12+, Python 3.9+)
- **iPhone** with iOS 17+ on the same Wi-Fi network
- Xcode 15+ to build the app

---

## Setup

### 1. Start the Mac server

```bash
python3 ~/.claude/tokentracker/server.py
```

The server reads `~/.claude/projects/**/*.jsonl` and serves usage data at:

```
http://<your-mac-hostname>.local:8765/usage.json
```

To auto-start on login, add it as a Launch Agent:

```bash
cp docs/com.tokentracker.server.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.tokentracker.server.plist
```

### 2. Build & run the iOS app

```bash
open TokenTracker.xcodeproj
```

Select your iPhone or simulator and press **⌘R**.

### 3. Configure in Settings

| Setting | Description |
|---|---|
| **Mac IP / Hostname** | Your Mac's local hostname (e.g. `MacBook-Pro.local`) or IP address |
| **5-hour limit** | Your plan's 5-hour token limit (e.g. `350000`) |
| **Weekly limit** | Your plan's weekly token limit (e.g. `2000000`) |

Tap the **↺** button on the dashboard or relaunch the app to sync.

---

## Project Structure

```
TokenTracker/
├── TokenTrackerApp.swift          # Entry point — auto-syncs on launch
├── Models/
│   └── TokenModels.swift          # TokenBudget, UsageEntry, API response models
├── ViewModels/
│   └── TokenStore.swift           # All state, sync logic, persistence
├── Views/
│   ├── ContentView.swift          # Tab bar root
│   ├── DashboardView.swift        # Plan usage cards with progress bars
│   └── SettingsView.swift         # Mac host + limit configuration
└── Services/
    ├── APIService.swift            # HTTP client for local Mac server
    └── KeychainService.swift       # Secure storage

TokenTrackerTests/
├── TokenStoreTests.swift          # Unit tests for store logic & reset times
├── TokenModelsTests.swift         # Codable round-trip, computed properties
└── LocalSyncServiceTests.swift    # JSON decoding, error handling
```

---

## Running Tests

```bash
xcodebuild test \
  -scheme TokenTracker \
  -destination "id=A7C379CB-F8F9-45B6-99DC-D86831629AB8" \
  CODE_SIGNING_ALLOWED=NO
```

---

## Token Counting

Tokens counted toward plan limits:

| Token type | Counted |
|---|---|
| Input tokens | ✅ |
| Output tokens | ✅ |
| Cache creation tokens | ✅ |
| Cache read tokens | ❌ |

This matches how Claude Code calculates usage against rate limits.

---

## License

MIT
