# Download [Grid v0.1](https://github.com/yannpom/Grid/releases/download/v0.1/Grid.app.zip)


**Grid** is a macOS **window managment** app that let you bind **custom shortcut** to **custom window positions** via an easy to copy/edit/share **YAML file**.

![](https://raw.githubusercontent.com/yannpom/Grid/master/demo.gif)

Grid UI is very minimalist, it only has a menu in the status bar:

![](https://raw.githubusercontent.com/yannpom/Grid/master/menu.png)

To get logs, run it form the command line: `/Applications/Grid.app/Contents/MacOS/Grid`


# YAML configuration file
A default configuration file is created in `~/.grid.yaml` is it does not exists.

The default config is a 9x9 grid with a larger center column (48%). Shortcuts only work with a keypad, but of course you can change/customize everything, and share your config file in a GitHub issue if you want.

## Example

```
- key: "CMD_ALT_KEYPAD7"    # combination of (CMD, ALT, CTRL) + 1 key
  name: "Top Left"          # optional
  positions:
    - y: 0                  # position 1: top left, size 26% width and 33% height
      x: 0
      w: 0.26
      h: 0.33333
    - y: 0                  # repeated shortcut press loop through positions
      x: 0
      w: 0.26
      h: 0.5
    - y: 0
      x: 0
      w: 0.26
      h: 0.66666

- key: "CMD_ALT_KEYPAD4"    # Define as many shortcut as you want
  name: "Left"
  positions:
    - y: 0.33333
      x: 0
      w: 0.26
      h: 0.33333
    - y: 0.05
      x: 0
      w: 0.26
      h: 0.90
      
- key: "CMD_ALT_KEYPAD1"
  name: "Bottom Left"
  positions:
    - y: 0.66666
      x: 0
      w: 0.26
      h: 0.33333
    - y: 0.5
      x: 0
      w: 0.26
      h: 0.5
    - y: 0.33333
      x: 0
      w: 0.26
      h: 0.66666
```

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
