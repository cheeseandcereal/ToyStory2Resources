# Toy Story 2 Resources

This repository contains various resources for Toy Story 2 reverse engineering/speedrunning.

Feel free to fork/contribute if desired.

## Autosplitter

The source for the autosplitter used by [livesplit](http://livesplit.org/) is contained in the [AutoSplitter](AutoSplitter) folder.

The autosplitter currently works on PC US and PC UK versions as well as Project64 1.7.0.50 Ver.23.

I know that PJ64 is oddly specific (and old), but that's the version of project64 that best emulates Toy Story 2, and is the version used to speedrun the game.

## Linux Steam Installer

The [linux install script](Linux/install-ts2-steam.sh) installs the PC game from an iso and adds it to Steam as a non-Steam library entry. It downloads and configures/uses [ToyStory2Fix](https://github.com/cheeseandcereal/ToyStory2Fix/releases/latest) and [D7VK](https://github.com/WinterSnowfall/d7vk) by default.

Requirements:

- An iso of any regional variant of the PC game
- Steam, with at least one Proton version installed
  - (I recommend Proton GE 11-11 or later for best results, but other versions including the native steam Proton version(s) will work, although you may not be able to view the video cutscenes)

### Desktop launcher (i.e. Steam Deck)

1. (If on steam deck) open the Power menu and select **Switch to Desktop**. A mouse and keyboard make this easier; otherwise, use the right trackpad as a mouse and **X** to open the on-screen keyboard.
2. Download [install-ts2-steam.desktop](https://github.com/cheeseandcereal/ToyStory2Resources/releases/latest/download/install-ts2-steam.desktop)
3. Open your file manager and find the downloaded file. If downloading with Firefox, it may name it `install-ts2-steam.desktop.download` - In this case, first rename it to `install-ts2-steam.desktop` (right click, rename, delete the .download part).
3. Drag **one PC game iso onto the launcher icon**. It downloads the latest install script and runs it with that iso in a terminal.

### Terminal

Copy/paste this into a terminal to download and run in one command:

```bash
curl --fail --location --show-error https://github.com/cheeseandcereal/ToyStory2Resources/releases/latest/download/install-ts2-steam.sh | bash -s -- path/to/ts2.iso
```

Alternatively, download the [latest install script](https://github.com/cheeseandcereal/ToyStory2Resources/releases/latest/download/install-ts2-steam.sh)

Then, from the directory containing the script, run:

```bash
bash install-ts2-steam.sh path/to/ts2.iso
```

### Installation options

The destination defaults to `~/.local/share/toy-story-2`, or `$XDG_DATA_HOME/toy-story-2` when configured. It must be absent or empty.

Options:

- `--install-dir DIR`: choose the destination.
- `-f/--fix URL_OR_ZIP`: use a different ToyStory2Fix URL or local ZIP.
- `-d/--d7vk URL_OR_ZIP`: use a different D7VK URL or local ZIP.
- `-i/--fix-ini FILE`: use your own `ToyStory2Fix.ini`, copied unchanged.
- `-h/--help`: show usage and defaults.

Supplying local ZIPs for both `--fix` and `--d7vk` avoids downloads. Steam manages Proton and the game's Wine prefix.

## Cheat Engine

There are currently 2 cheat tables for the PC US version of the game in [CheatEngine](CheatEngine).

`toy2base` simply contains some addresses for common useful things in the game.

`toy2trainer` contains the forms and addresses for the [trainer](https://www.speedrun.com/toys2/thread/n8y8a) which contains some useful tools for practicing various things within the game.

## Project 64

The [Project64](Project64) folder contains some additional cheats for the US N64 ROM of the game to be added to (or simply replace) the Project64.cht file for the emulator running the game.
