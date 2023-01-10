# Background

My personal goal for my Wii U is to essentially turn it into a Gamecube. I want to play all of my old Gamecube games (which I still have) with a native HDMI output and newer controllers (Wii U Pro Controllers).

The requirements I set for myself for this project are:

1. Launch Gamecube games directly from the Wii U Home Menu (injected Nintendont autoboot).
2. Launch a game, play it, quit the game with the Wii U Pro Controller (without picking up the Gamepad or a Wiimote).
3. Be able to use the Wii U Gamepad as a controller if necessary (to support additional players).

Some games (e.g. Super Smash Bros Melee) don't really care which slot a controller is in, but for other games (e.g. Mario Kart Double Dash) the first controller is the only one that can navigate the menu.

This means that in order to accomplish requirement 2, I need to be able to be able to configure `Nintendont` to assign a Wii U Pro Controller as controller slot 1.

After setting up tiramisu and installing `Nintendont`, I discovered 2 things:

1. There is a setting in `Nintendont` to configure which controller slot the Wii U Gamepad occupies (🥹).
2. The setting does not work for games installed with an injector (😞).

I beat my head against a wall trying a bunch of different things to get it to work (different builds of TeconMoon's injector, different injectors alltogether, different config files, different builds of `Nintendont`), but no matter what I tried, the Wii U Gamepad always took up controller slot 1.

I was almost resigned to just launching games directly from `Nintendont`, but I decided that I really wanted to accomplish all of my goals, so I set out to try to figure out how I could get this to work.

This is a chronicle of the things I learned as I took this journey, the fixes I implemented, and at the end, a call to action to hopefully get this fixed for the community once and for all.

First, some background about the `WiiUGamepadSlot` setting.

# WiiUGamepadSlot

In 2018, a [request](https://github.com/FIX94/Nintendont/issues/620) was made in the `Nintendont` repo to allow disabling the Wii U Gamepad or choosing its controller slot. Eventually someone made a [fork](https://github.com/NazarSurm/Nintendont---No-gamepad-on-Player-1#) of `Nintendont` with a [change](https://github.com/FIX94/Nintendont/commit/3decbfaeed21e21f28259e015c95a77f6116a8d0) to disable the gamepad entirely.

> 📓 This actually helps get me pretty dang close to my goals, except for the 3rd one. And I almost just stopped here with the intention of buying more Pro Controllers so I wouldn't have to use the Gamepad at all.

3 years later, a [PR](https://github.com/FIX94/Nintendont/pull/887) was opened to allow choosing the controller slot for the Wii U Gamepad. This added a new configuration for `Nintendont` called `WiiUGamepadSlot` in the `nincfg.bin` format.

After that change was made, it was determined that it had introduced a bug where the Wii U Gamepad was disabled when `Nintendont` was in `autoboot` mode. A [workaround](https://github.com/FIX94/Nintendont/commit/fd5e85c4fe4c4015936e21b16242fa0f15449e99) was put into place to always make the `WiiUGamepadSlot` be 0 if it was detected that `Nintendont` was running in `autoboot` mode.

```
if (((NIN_CFG*)0x93004000)->Config & NIN_CFG_AUTO_BOOT)
{
  if(HIDPad == HID_PAD_NONE)
    WiiUGamepadSlot = 0;
  else
    WiiUGamepadSlot = 1;
}
```

> 📓 This means that when in `autoboot` mode, `WiiUGamepadSlot` will never work! This is the first real clue for how things might be treated differently in `autoboot` vs `normal` mode.

Let's look at how `Nintendont` configuration works next. Maybe that will provide some additional insight.

# Nintendont configuration

## nincfg.bin

`Nintendont` requires a `nincfg.bin` file in the root of your SD card to define the `Nintendont` configuration.

From what I can tell, the `nincfg.bin` file format is simply a binary representation of the `NIN_CFG` struct defined in `Nintendont` in [`common/include/CommonConfig.h`](https://github.com/FIX94/Nintendont/blob/master/common/include/CommonConfig.h#L12).

When you launch `Nintendont` and change some setting, it updates the `nincfg.bin` with your changed configuration. There is also a tool called [Nicoe](https://github.com/libertyernie/Nicoe) which can read and modify a `nincfg.bin` file from a Windows PC (and without having to launch `Nintendont` on a Wii U).

## Initializing NIN_CFG

In `normal` mode (i.e. not `autoboot` / injected mode, i.e. launching a game from the `Nintendont` menu) `Nintendont` [loads](https://github.com/FIX94/Nintendont/blob/fd5e85c4fe4c4015936e21b16242fa0f15449e99/loader/source/global.c#L333) `sizeof(NIN_CFG)` bytes of the file `nincfg.bin` into a memory block that is the same size as the `NIN_CFG` struct.

In `autoboot` mode, whatever is initializing `Nintendont` (the forwarder) passes the `NIN_CFG` bytes as an argument, and `Nintendont` [copies](https://github.com/FIX94/Nintendont/blob/d64d0da20d5db8326539c07f5898b8601131095c/loader/source/main.c#L573) those bytes into a memory block that is the same size as the `NIN_CFG` struct.

> 📓 This is another critical difference in functionality that hints at why `WiiUGamepadSlot` works in `normal` mode but not `autoboot` mode.

## Versioning and backwards compatibility

`Nintendont` makes some provisions to sanitize config files that may not be fully up-to-date with the latest version of the config format. The `NIN_CFG` struct contains a `Version` [member](https://github.com/FIX94/Nintendont/blob/c0e97a5efba3c3d184d7c20d6036916b2877703b/common/include/CommonConfig.h#L15), and when `Nintendont` detects that the version of the config that was loaded is [older than the current version](https://github.com/FIX94/Nintendont/blob/fd5e85c4fe4c4015936e21b16242fa0f15449e99/loader/source/global.c#L417), it sets some defaults for members that did not exist in previous versions and updates the `Version` to the latest.

The important thing to note for our purposes is this:

```
  if (ncfg->Version == 9) {
    ncfg->WiiUGamepadSlot = 0;
    ncfg->Version = 10;
  }
```

The [current version](https://github.com/FIX94/Nintendont/blob/c0e97a5efba3c3d184d7c20d6036916b2877703b/common/include/CommonConfig.h#L8) of `NIN_CFG` is `10` (`0xA` in hex)

If the `Version` in the `NIN_CFG` struct is `9`, `WiiUGamepadSlot` gets initialized to 0.

So the expectation is that if you have a `NIN_CFG` of version `10`, the `WiiUGamepadSlot` value is already defined, and it doesn't need to be initialized with some default value.

> 📓 This points to a liklihood that `Nintendont` is being initialized with a `NIN_CFG` of version `10`, but no (valid) `WiiUGamepadSlot` is set.

Here's the `nincfg.bin` I'm using. It's version `10`, and `WiiUGamepadSlot` is 2 (this is 0-indexed so it's really the third controller slot).

!!! ADD IMAGE !!!

The `nincfg.bin` is fine. Remember, launching a game from `Nintendont` directly results in the `WiiUGamepadSlot` in controller slot 3 as expected.

So maybe there's something about the injection / autoboot process that's going wrong? How do those injectors work anyway?

# Autoboot forwarding

> 📓 I'm going to focus on TeconMoon's Wii VC injector. There are other injectors (e.g. `UWUVCI` and I believe `Wii U USB Helper` has some injection capabilities), but I'm most familiar with TeconMoon's at the moment. Also TeconMoon's injector supports custom forwarders which is important for helping us fix the issue with `WiiUGamepadSlot` and `autoboot`.

There is a ton of detail I'm going to skip over related to Wii VC injection (mostly because I don't actually know all of the details), but for our purposes and at a very high level, an injector creates an installable file or files (likely WUP format) that you can install as a Title to your Wii U Home Menu (using e.g. WUP Installer) , which places an icon on your Wii U home page to launch some application (in our case it needs to launch the Wii VC with a GCN game and `Nintendont`).

We need _something_ to tell `Nintendont` to automatically launch a game instead of booting to the `Nintendont` menu. E.g.

```
a forwarder for Wii VC to autoboot an included game
```

Enter [`nintendont-autoboot-forwarder`](https://github.com/FIX94/nintendont-autoboot-forwarder).

Now I don't know all of the technical details, but from what I can gather, TeconMoon's injector "injects" this forwarder in the Wii VC so that when Wii VC is launched, it automatically starts `Nintendont` via the autoboot forwarder (my terminology is probably not quite right here, but hopefully it's close enough). If you download the [TOOLDIR](https://github.com/piratesephiroth/TeconmoonWiiVCInjector/blob/main/TeconMoon's%20WiiVC%20Injector/Resources/TOOLDIR.zip) from the source and unzip it, you'll find compiled `dol` files from the [releases](https://github.com/FIX94/nintendont-autoboot-forwarder/releases/tag/v1.2) page of the `nintendont-autoboot-forwarder` repo.

If we go look at the [`main.c`](https://github.com/FIX94/nintendont-autoboot-forwarder/blob/master/source/main.c) file for the forwarder, we can see a couple things:

1. It [reads nincfg.bin](https://github.com/FIX94/nintendont-autoboot-forwarder/blob/master/source/main.c#L77) from the sd card (kind of like how [`Nintendont` does](https://github.com/FIX94/Nintendont/blob/master/loader/source/global.c#L328))
    ```
    f = fopen("sd:/nincfg.bin","rb");
    ```

2. It [loads the contents of the file into memory](https://github.com/FIX94/nintendont-autoboot-forwarder/blob/master/source/main.c#L85) (also similar to how [`Nintendont` does](https://github.com/FIX94/Nintendont/blob/master/loader/source/global.c#L333))
    ```
    fread(&nincfg,1,sizeof(NIN_CFG),f);
    ```

3. And then after potentially making some changes to the config (e.g. disabling all widescreen bits), it [writes the config bytes back to some memory address](https://github.com/FIX94/nintendont-autoboot-forwarder/blob/master/source/main.c#L110) for `Nintendont` to eventually [read from](https://github.com/FIX94/Nintendont/blob/master/loader/source/main.c#L573).
    ```
    memcpy(CMD_ADDR+full_fPath_len, &nincfg, sizeof(NIN_CFG));
    ```

> 📓 Notice how we're consistently using `sizeof(NIN_CFG)` to determine how many bytes to read in and out of memory. This is the crux of the problem.

`nintendont-autoboot-forwarder` also has a [`/source/CommonConfig.h`](https://github.com/FIX94/nintendont-autoboot-forwarder/blob/master/source/CommonConfig.h) file that looks awfully familiar.

```c

#ifndef __COMMON_CONFIG_H__
#define __COMMON_CONFIG_H__

//#include "NintendontVersion.h"
//#include "Metadata.h"

#define NIN_CFG_VERSION		0x00000008

#define NIN_CFG_MAXPAD 4

typedef struct NIN_CFG
{
	unsigned int		Magicbytes;		// 0x01070CF6
	unsigned int		Version;		// 0x00000001
	unsigned int		Config;
	unsigned int		VideoMode;
	unsigned int		Language;
	char	GamePath[255];
	char	CheatPath[255];
	unsigned int		MaxPads;
	unsigned int		GameID;
	unsigned char		MemCardBlocks;
	signed char			VideoScale;
	signed char			VideoOffset;
	unsigned char		Unused;
} NIN_CFG;

...
```

Yes that is the same (almost) `CommonConfig.h` file that `Nintendont` has! In fact, you can tell it was probably copied from a previous version of `Nintendont` because it has some commented out lines that reference header files in `Nintendont` that we don't have here.

There are a few things different about this file though:

1. It's out of date. This file supports `NIN_CFG` only up to version `8`.

    ```c
    #define NIN_CFG_VERSION		0x00000008
    ```

    But the version in `Nintendont` is `10`.

    ```c
    #define NIN_CFG_VERSION		0x0000000A
    ```

2. The `NIN_CFG` struct is a different size. It's 1 unsigned int (4 bytes if I'm not mistaken that Wii U is a 32-bit hardware) shorter than the `NIN_CFG` defined in `Nintendont`. And that unsigned int is `WiiUGamepadSlot`.

# The problem

Now that we're (somewhat?) up to speed on configuring and autobooting `Nintendont`, we can start to see what the source of the problem is.

I'm going to refer to `NIN_CFG` in `Nintendont` as `NIN_CFG_10` and the one in `nintendont-autoboot-forwarder` as `NIN_CFG_8`.

1. When `nintendont-autoboot-forwarder` reads `nincfg.bin` into memory, it reads `sizeof(NIN_CFG_8)` bytes of the file (missing the last 4 bytes of `WiiUGamepadSlot`).
2. When `nintendont-autoboot-forwarder` copies `NIN_CFG` for `Nintendont` to read, it writes `sizeof(NIN_CFG_8)` bytes into memory (again, missing the `WiiUGamepadSlot` bytes)
3. Because the version of the file that `nintendont-autoboot-fowarder` loaded is `10`, the Version member of the `NIN_CFG` struct that it writes to memory is `10` (even though it's missing the expected `WiiUGamepadSlot` bytes).
4. When `Nintendont` loads `NIN_CFG` from memory in autoboot mode, it copies `sizeo(NIN_CFG_10)` bytes from memory. That means it's copying an extra 4 bytes that were never written by the forwarder. When this happens, it is `UNDEFINED BEHAVIOR` (scary) which basically means "who knows what happens". I think what's most likely is that whatever bytes are in memory at those next memory addresses are copied into the 4 bytes of the `WiiUGamepadSlot`, so it likely is some value between 0 and 4,294,967,295. Now I don't think `Nintendont` is really equiped to handle a couple billion controllers, so it breaks in unexpected ways (like being disabled all together).
5. When `Nintendont` goes to apply a backwards compatibility fix (and set `WiiUGamepadSlot` to something more sane, like 0) it sees that the config file is version `10`, so it skips all of that logic.

So in autoboot mode, `Nintendont` ends up with a `NIN_CFG` that has garbage bytes for `WiiUGamepadSlot`. If we can fix this, I can accomplish all of my goals, and finally beat my time trial record on Baby Park from 10 years ago.

# The fix

There's already a workaround fix in place that sets the `WiiUGamepadSlot` to 0 in autoboot mode. But we want to be able to actually use `WiiUGamepadSlot` in autoboot mode, so we need to replace that.

1. Fix the backwards compatibility
2. Remove the workaround fix

1. Upgrade forwarder to support version `10` of `NIN_CFG` struct
