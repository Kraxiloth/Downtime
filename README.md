# Downtime

**Downtime** is a lightweight experience and leveling efficiency tracker for World of Warcraft, developed by [Ancient Workshop](https://ancient.dev).

## Features

- Session XP/hour, including time spent traveling, managing inventory, or waiting between XP gains
- Time since the last XP gain and estimated time to next level
- Rolling XP/hour averages over 5, 15, and 30 minutes
- Optional gradual performance colors comparing rolling averages with the session average
- Individually configurable metrics, compact/comfortable layouts, and adjustable background opacity
- Movable, lockable panel that can anchor above the Blizzard Player Frame
- Per-character sessions that survive `/reload` but restart on a fresh login; offline time is excluded

## Installation

1. Download **Downtime-v0.2.0.zip** from the [latest release](https://github.com/Kraxiloth/Downtime/releases/latest), under **Assets**. Do not use GitHub's automatically generated **Source code (zip)** archive.
2. Extract the ZIP into your WoW client's `Interface\AddOns` directory.
3. Verify that `Downtime.toc` is directly inside the `Downtime` folder, not inside an additional `Downtime-main` directory.
4. Restart the game and enable **Downtime** in the AddOns menu.

Example Retail installation path:

`World of Warcraft\_retail_\Interface\AddOns\Downtime\`

For WoW: Forever, use its own client's `Interface\AddOns` directory.

The installed files should be arranged as follows:

```text
Interface/
└── AddOns/
    └── Downtime/
        ├── Downtime.toc
        ├── Downtime_Mainline.toc
        ├── Core.lua
        ├── Errors.lua
        ├── Experience.lua
        ├── Interface.lua
        └── Settings.lua
```

## Commands

| Command | Description |
| --- | --- |
| `/downtime` | Show session XP statistics in chat |
| `/downtime config` or `/downtime settings` | Open display settings |
| `/downtime lock` | Prevent dragging |
| `/downtime unlock` | Allow dragging |
| `/downtime reset` | Restore the default panel position |
| `/downtime resetsettings` | Restore display defaults without changing position or session |
| `/downtime errors` | List recorded addon errors |

## Compatibility

Tested in World of Warcraft Retail (Midnight). WoW: Forever compatibility is intended but has not yet been verified in the live game.

## Feedback

[GitHub repository](https://github.com/Kraxiloth/Downtime) · [Ancient Workshop](https://ancient.dev)
