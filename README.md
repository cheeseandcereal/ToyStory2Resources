# Toy Story 2 Resources

This repository contains various resources for Toy Story 2 reverse engineering/speedrunning.

Feel free to fork/contribute if desired.

## Autosplitter

The source for the autosplitter used by [livesplit](http://livesplit.org/) is contained in the [AutoSplitter](AutoSplitter) folder.

The autosplitter currently works on PC US and PC UK versions as well as Project64 1.7.0.50 Ver.23.

I know that PJ64 is oddly specific (and old), but that's the version of project64 that best emulates Toy Story 2, and is the version used to speedrun the game.

## Cheat Engine

There are currently 2 cheat tables for the PC US version of the game in [CheatEngine](CheatEngine).

`toy2base` simply contains some addresses for common useful things in the game.

`toy2trainer` contains the forms and addresses for the [trainer](https://www.speedrun.com/toys2/thread/n8y8a) which contains some useful tools for practicing various things within the game.

## Project 64

The [Project64](Project64) folder contains some additional cheats for the US N64 ROM of the game to be added to (or simply replace) the Project64.cht file for the emulator running the game.

## Linux installation

The [Linux install script](https://github.com/cheeseandcereal/ToyStory2Resources/releases/latest/download/install-ts2-steam.sh) installs the PC game from an ISO and requests a non-Steam library entry. It downloads [ToyStory2Fix](https://github.com/cheeseandcereal/ToyStory2Fix/releases/latest/download/ToyStory2Fix.zip) and [D7VK](https://github.com/WinterSnowfall/d7vk/releases/download/v2.3/d7vk-v2.3.zip) by default.

Requirements:

- An ISO of any regional variant of the PC game.
- Up-to-date Steam, with at least one Proton version installed.

On Steam Deck, switch to Desktop Mode and open Konsole. Drag and drop the script into Konsole, then the ISO, and press Enter on the virtual keyboard to run it.

From the directory containing the script, run:

```bash
./install-ts2-steam.sh /path/to/ts2.iso
```

The destination defaults to `~/.local/share/toy-story-2`, or `$XDG_DATA_HOME/toy-story-2` when configured. It must be absent or empty.

Options:

- `--install-dir DIR`: choose the destination.
- `-f/--fix URL_OR_ZIP`: use a different ToyStory2Fix URL or local ZIP.
- `-d/--d7vk URL_OR_ZIP`: use a different D7VK URL or local ZIP.
- `-i/--fix-ini FILE`: use your own `ToyStory2Fix.ini`, copied unchanged.
- `-h/--help`: show usage and defaults.

Supplying local ZIPs for both `--fix` and `--d7vk` avoids downloads. Steam manages Proton and the game's Wine prefix.
