# Mousable for macOS

Control your mouse cursor entirely from the keyboard. Move, click, scroll, and drag — no mouse or trackpad needed.

Mousable is a macOS menu bar utility inspired by [Mouseable for Windows](https://github.com/wirekang/mouseable) (now archived). It intercepts keyboard input to give you full mouse control with smooth, physics-based acceleration.

## Download

[Download latest version](https://github.com/rootdevelop/mousable-macos/releases/tag/1.0.0.0)

## Getting Started

### 1. Grant Accessibility Permission

Mousable needs Accessibility access to intercept keyboard events and move the cursor. On first launch, macOS will prompt you to grant permission:

1. Open **System Settings → Privacy & Security → Accessibility**
2. Enable the toggle for **Mousable**
3. If the prompt doesn't appear, you can add Mousable manually with the **+** button

> Mousable will poll for permission every 2 seconds until granted. You don't need to restart the app.

### 2. Activate and Go

Once permission is granted, Mousable lives in your **menu bar** (it won't appear in the Dock).

Press **⌘J** to activate mouse control. Press **;** to deactivate. That's it.

## Controls

### Activation

| Action | Default Key |
|--------|-------------|
| Activate mouse control | **⌘J** (Cmd+J) |
| Deactivate | **;** |

Both keybindings can be customized in Settings.

### Cursor Movement

While activated, use WASD to move the cursor:

| Key | Direction |
|-----|-----------|
| **W** | Up |
| **A** | Left |
| **S** | Down |
| **D** | Right |

Hold multiple keys for diagonal movement. The cursor accelerates smoothly the longer you hold a direction and decelerates when you release.

### Mouse Clicks

| Key | Action |
|-----|--------|
| **J** | Left click |
| **L** | Right click |

Hold a click key and move with WASD to **drag**. Double-click by pressing quickly twice (within 300ms, matching macOS behavior).

### Scrolling

| Key | Direction |
|-----|-----------|
| **R** | Scroll up |
| **F** | Scroll down |
| **Q** | Scroll left |
| **E** | Scroll right |

Scrolling has its own independent acceleration curve — it starts slow and speeds up the longer you hold.

### Turbo Mode

Hold **H** while moving to activate turbo mode for fast, large cursor movements across the screen.

### Quick Reference

```
        R (scroll up)
        W (up)
Q  A  S  D  E       J (left click)   L (right click)   H (turbo)
   (scroll left/right)
        F (scroll down)
```

## Settings

Click the Mousable menu bar icon and select **Settings** (or press **⌘,** while the menu is open) to configure:

### Cursor Speed

| Setting | Default | Description |
|---------|---------|-------------|
| Acceleration | 0.575 | How quickly the cursor reaches max speed |
| Max Speed | 11.5 | Top cursor speed in normal mode |
| Start Speed | 1.5 | Initial speed when you begin moving |
| Turbo Speed | 75 | Top cursor speed while holding H |

### Scroll Speed

| Setting | Default | Description |
|---------|---------|-------------|
| Acceleration | 4.6 | How quickly scrolling reaches max speed |
| Max Speed | 46 | Top scroll speed |
| Start Speed | 2 | Initial scroll speed |

### Keybindings

Both the activate and deactivate keys can be remapped to any key with any combination of modifiers (Ctrl, Option, Shift, Cmd). Click the keybinding button in Settings and press your desired key combination.

### General

- **Launch at Login** — Start Mousable automatically when you log in (macOS 13+)
- **Reset to Defaults** — Restore all settings to their original values

## How It Works

Mousable uses a physics-based movement model running at 50Hz:

- **Acceleration** — Holding a direction key smoothly increases speed up to the configured max
- **Deceleration** — Releasing a key decays speed at 2x the acceleration rate for a responsive stop
- **Momentum** — Changing direction preserves your current speed for fluid transitions
- **Diagonal correction** — Diagonal movement is normalized (÷ √2) so it doesn't feel faster than cardinal movement
- **Screen clamping** — The cursor stays within your display bounds across all connected monitors

## Requirements

- macOS 11.0 (Big Sur) or later
- Accessibility permission

## Building from Source

1. Clone the repository
2. Open `Mousable.xcodeproj` in Xcode
3. Build and run (⌘R)

No external dependencies are required.

## License

See [LICENSE](LICENSE) for details.

## Acknowledgments

- Inspired by [Mouseable](https://github.com/wirekang/mouseable) by wirekang
