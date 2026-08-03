# Quest System for Don't Starve Together

Quest System is a gameplay expansion mod for Don't Starve Together that adds a full quest experience to the game. Players can accept quests from a quest board, track progress in a quest log, complete objectives, level up, and earn rewards. The mod also supports boss encounters, custom quest creation, and extensibility for other modders.

## Overview

This mod introduces:

- A quest board for accepting new quests
- A quest log UI to track active goals and progress
- A progression system with levels and rewards
- Boss encounters and special challenge content
- Configurable quest settings and reward scaling
- A public API for modders to add custom quests and custom goals

## Features

- Accept quests from the quest board or find request items in the world
- Complete objectives such as killing creatures, crafting items, or meeting custom conditions
- Earn rewards and gain experience toward higher levels
- Fight powerful boss creatures for special rewards
- Customize quest frequency, difficulty, reward amount, and UI options
- Extend the system with custom quests, rewards, bosses, and goals

## Installation

### Steam Workshop [Quest System [BETA]](https://steamcommunity.com/sharedfiles/filedetails/?id=2597204554)

1. Subscribe to the mod on the Steam Workshop.
2. Enable the mod in the Don't Starve Together mod settings.
3. Start or join a game with the mod enabled.

### Local Installation

1. Download or clone this repository into your Don't Starve Together mods folder.
2. Make sure the folder name is exactly `Quest_System`.
3. Enable the mod in the Don't Starve Together mod settings.
4. Start or join a game with the mod enabled.

For a typical installation path on Windows, this is usually:

`steamapps/common/Don't Starve Together/mods/Quest_System`

## Configuration

The mod includes several configuration options that can be adjusted from the in-game mod settings menu, including:

- Quest drop probability
- Difficulty and rank restrictions
- Quest board cost
- Reward scaling
- Crafting request availability
- Initial quest count
- Global quest requirements/rewards

## Modding and Extension

The mod is designed to be fairly open for other modders. It includes support for:

- Adding custom quests
- Creating custom quest goals
- Registering custom rewards
- Defining bosses and boss rewards
- Using the built-in quest component API from other mods

Useful entry points include:

- `scripts/own_quests_template.lua`
- `scripts/quests.lua`
- `quest_system/Quest_Board_Util.lua`
- `quest_system/tuning_strings.lua`

## Development Notes

This project is a Lua-based mod for Don't Starve Together and is structured around:

- Core game integration in the top-level Lua files
- Quest logic and data under `quest_system/`
- Shared helper code under `mod_util/`
- Quest content and scripts under `scripts/`

## Credits

- Author: Monti
- Compatibility: Don't Starve Together (DST), API version 10

## Notes

This project is currently marked as beta. Some content may change over time as the system evolves.

If you want to contribute, improve the modding API, or add new quest content, feel free to explore the included templates and helper files.
