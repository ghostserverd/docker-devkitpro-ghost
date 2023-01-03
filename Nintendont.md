# Background

My personal goal for my Wii U is to essentially turn it into a Gamecube. I want to play all of my old Gamecube games (which I still have) with a native HDMI output and newer controllers (Wii U Pro Controllers).

The requirements I set for myself for this project are:

1. Launch Gamecube games directly from the Wii U Home Menu (injected Nintendont autoboot).
2. Launch a game, play it, quit the game with the Wii U Pro Controller (without picking up the Gamepad or a Wiimote).
3. Be able to use the Wii U Gamepad as a controller if necessary (to support additional players).

Some games (e.g. Super Smash Bros Melee) don't really care which slot a controller is in, but for other games (e.g. Mario Kart Double Dash) the first controller is the only one that can navigate the menu.

This means that in order to accomplish requirement 2, I need to be able to be able to configure `Nintendont` to assign a Wii U Pro Controller as controller slot 1.

# WiiUGamepadSlot

In 2018, a [request](https://github.com/FIX94/Nintendont/issues/620) was made in the `Nintendont` repo to allow disabling the Wii U Gamepad or choosing its controller slot. Eventually someone made a [fork](https://github.com/NazarSurm/Nintendont---No-gamepad-on-Player-1#) of `Nintendont` with a [change](https://github.com/FIX94/Nintendont/commit/3decbfaeed21e21f28259e015c95a77f6116a8d0) to disable the gamepad entirely.

3 years later, a [PR](https://github.com/FIX94/Nintendont/pull/887) was opened to allow choosing the controller slot for the Wii U Gamepad. This added a new configuration for `Nintendont` called `WiiUGamepadSlot` in the `nincfg.bin` format.

After that change was made, it was determined that it introduced a bug where the Wii U Gamepad was disabled when `Nintendont` was in autoboot mode. A [workaround](https://github.com/FIX94/Nintendont/commit/fd5e85c4fe4c4015936e21b16242fa0f15449e99) was put into place to always make the `WiiUGamepadSlot` be 0 if it was determined that `Nintendont` was running in autoboot mode.

# Nintendont configuration

## nincfg.bin

`Nintendont` requires a `nincfg.bin` file in the root of your SD card to define the `Nintendont` configuration.

From what I can tell, the `nincfg.bin` file format is simply a binary representation of the `NIN_CFG` struct defined in `Nintendont` in [`common/include/CommonConfig.h`](https://github.com/FIX94/Nintendont/blob/master/common/include/CommonConfig.h#L12).

When you launch `Nintendont` and change some setting, it updates the `nincfg.bin` with your changed configuration. There is also a tool called [Nicoe](https://github.com/libertyernie/Nicoe) which can read and modify a `nincfg.bin` file from a Windows PC (and without having to launch `Nintendont` on a Wii U).

## Initializing NIN_CFG

In `normal` mode (i.e. not autoboot mode) `Nintendont` [loads](https://github.com/FIX94/Nintendont/blob/fd5e85c4fe4c4015936e21b16242fa0f15449e99/loader/source/global.c#L333) `sizeof(NIN_CFG)` bytes of `nincfg.bin` into a memory block that is the same size as the `NIN_CFG` struct.

In `autoboot` mode, whatever is initializing `Nintendont` (the forwarder) passes the `NIN_CFG` bytes as an argument, and `Nintendont` [copies](https://github.com/FIX94/Nintendont/blob/d64d0da20d5db8326539c07f5898b8601131095c/loader/source/main.c#L573) those bytes into a memory block that is the same size as the `NIN_CFG` struct.

## Backwards compatibility

`Nintendont` makes some provisions to sanitize config files that may not be fully up-to-date with the latest version of the config format. The `NIN_CFG` defines a `Version` [member](https://github.com/FIX94/Nintendont/blob/c0e97a5efba3c3d184d7c20d6036916b2877703b/common/include/CommonConfig.h#L15), and when `Nintendont` detects that the version of the config that was loaded is [older than the current version](https://github.com/FIX94/Nintendont/blob/fd5e85c4fe4c4015936e21b16242fa0f15449e99/loader/source/global.c#L417), it sets some defaults for members that did not exist in previous versions and updates the `Version` to the latest.


