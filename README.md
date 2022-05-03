# Install

```sh
brew install yannpom/repo/grid
```

Or download from [GitHub releases](https://github.com/yannpom/Grid/releases)

# Grid v0.2

**Grid** is a macOS **window managment** app that let you bind **custom shortcut** to **custom window positions** via an easy to copy/edit/share **YAML file**.

![](https://raw.githubusercontent.com/yannpom/Grid/master/demo.gif)

Grid UI is very minimalist, it only has a menu in the status bar:

![](https://raw.githubusercontent.com/yannpom/Grid/master/menu.png)

To get logs, run it form the command line: `/Applications/Grid.app/Contents/MacOS/Grid`

# YAML configuration file

A default configuration file is created in `~/.grid.yaml` if it does not exists.

The default config is a kind of 9x9 grid with a larger center column (48%). But of course you can change/customize everything, and share your config file in a GitHub issue if you want.

Config is reloaded on file change. It makes it easy to edit/save/test your changes in seconds.

## Basic Example

Config file: `~/.grid.yaml`

```yaml
actions:
  - key: "CMD_ALT_LEFTARROW" # combination of (CMD, ALT, CTRL) + 1 key
    name: "Center Left"      # optional
    positions:
      - [.18, 0, .32, 1]     # x=18%, y=0, width=32%, height=100%
      - [.10, 0, .40, 1]     # Repeated keypress loop through all positions
      - [0, 0, .50, 1]

  - key: ...
```


## Advanced Example

```yaml
define:
  - &x1 0.26    # YAML variables can be defined to be reused multiple times
  - &x2 0.74
  
  - &w0 0.26
  - &w1 0.48
  - &w2 0.26
  
  - &y1 0.33
  - &y2 0.50
  - &y3 0.66

  - &h1 0.33
  - &h2 0.5
  - &h3 0.66

actions:
  # Multiple hotkey for the same action
  # (I like to use the keypad but I need backup hotkey on laptop keyboard)
  - key: ["CMD_ALT_KEYPAD4", "CMD_ALT_H"]
    name: "Left"
    positions:
      - [0, *y1, *w0, *h1]    # use of variables
      - [0, .05, *w0, .90]

  - key: "CMD_ALT_1"
    name: "Scenario #1"
    # a 'scenario' moves multiple windows at the same time
    scenario:
    # based on the App Bundle Identifier:
      - app: 'com.apple.finder'
        # 5th position argument is the display number
        # 0 = screen with focus
        # 1 = main screen (laptop)
        # 2 = 1st external screen
        position: [0.0000, 0.0000, 0.5000, 0.4994, 1]
      - app: 'com.spotify.client'
        position: [0.0000, 0.0000, 0.2599, 0.3293, 2]
```

## Copy position from actual window

Focus on a window, then click on "Copy current window info":

![](https://raw.githubusercontent.com/yannpom/Grid/master/menu2.png)

A YAML snippet will get to your paperboard:

```yaml
- app: 'com.sublimetext.3'
  position: [0.1799, 0.0000, 0.3198, 1.0000, 1]
```

Copy paste the whole block to your config file, or only the position array, as you need.

## Keylist

`A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
0 1 2 3 4 5 6 7 8 9
LEFTARROW RIGHTARROW DOWNARROW UPARROW
RIGHTBRACKET LEFTBRACKET QUOTE SEMICOLON BACKSLASH COMMA SLASH PERIOD GRAVE RETURN TAB SPACE DELETE ESCAPE VOLUMEUP VOLUMEDOWN MUTE HELP HOME PAGEUP FORWARDDELETE END PAGEDOWN
KEYPADDECIMAL KEYPADMULTIPLY KEYPADPLUS KEYPADCLEAR KEYPADDIVIDE KEYPADENTER KEYPADMINUS KEYPADEQUALS KEYPAD0 KEYPAD1 KEYPAD2 KEYPAD3 KEYPAD4 KEYPAD5 KEYPAD6 KEYPAD7 KEYPAD8 KEYPAD9
F1 F2 F3 F4 F5 F6 F7 F8 F9 F10 F11 F12
`

# Accessibility permission

You need to grand ccessibility permission in `System Preferences` / `Security & Privacy` / `Accessibility` / Check `Grid.app`
