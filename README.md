# fsduplicates
Command line tool to detect duplicate songs in OS X/macOS based on their Audio Fingerprints.

**Important Notice**

This is a work in progress, but some core functionality has been finished to let people use this tool to help users in finding duplicates in their music libraries. I cannot be held responsible if this tool somehow destroys your music library, sets fire on your computer, or starts a intergalactic war in the Galactic Federation on your behalf. Keep backups!

Eventually, a binary will be made available for people to easily download and install this tool. In the meantime, you will need to build it yourself.

This tool currently only works for OS X and macOS and there's no plans to port it to other platforms. It was written in Swift 3, so the possibility to port it by third parties is open. Let me know if you port it so you can be featured in this page.

## Introduction

If you have a big music library, identifying song duplicates can be *hard*. Even if you keep your music library properly organized, you can still find some duplicates lingering around. Probably some copy of a song you download years ago with no metadata is still hanging around your iTunes Library. Or you could have amased gigantic amounts of music in the past years, and you didn't care about duplicates at first. But you do now, and cleaning them is not going to be an easy task.

Many tools have appeared in the past years that help you with this task. The problem is none of them (if any) use audio fingerprinting, and they relay on song metadata alone. By using audio fingerprinting against a database, you can have better luck finding true duplicates of your songs, without them being considered equal if they are remixes or other variations. If you have ever used iTunes "Show Duplicates" feature, you know the results are never too accurate.

## How it works

fsduplicates works by locally generating a fingerprint and sending it off to [AcoustID's](acoustid.org) database to properly identify it and then it returns an `AcoustID` value that is unique for each song. fsduplicates will search for all the songs recursively inside a user-given directory, send them off to AcoustID, and then save the `AcoustID` values along with the songs that matched that value in a file within a user-specified directory. This way you can easily see which songs are duplicates of each other.

## Getting Started

Before you start using this tool, you should take proper precautions. The current version of this tool (`v.0.0.1`) will *not* touch your existing computer files at all. It will however create new files inside directories you specify. Make backups if you want to, and then keep reading.

## Installation Guide

*(This section is currently incomplete)*

fsduplicates was designed to not rely on dependencies, but due to the nature of the project, you will need to install one.

### Installing Chromaprint

Chromaprint is a core component of the AcoustID project. Chromaprint includes a command line tool called `fpcalc` which fsduplicates a lot. You can follow the instructions [here](https://acoustid.org/chromaprint) to install it, or, if you have [Homebrew](brew.sh) installed on your Mac, you can install it easily using the following command in your Terminal:

```Bash
brew install chromaprint
```

### Installing fsduplicates

*(Come back later).*

## Usage Guide

fsduplicates' commands were designed to be as simple as possible. Typing `fsduplicates -h` will give you the help info, which you can use to get started:

```Text
fsduplicates ver. 0.0.1

usage: fsduplicates [OPTIONS]

Options:

 -i                                  When specified for supported commands, makes interaction interactive.
 -f DIR_TO_SEARCH DIR_TO_OUTPUT      Find duplicates in DIR_TO_SEARCH recursively. Output to DIR_TO_OUTPUT
 -fpcalc-path FPCALC_PATH            fpcalc executable path. Default is /usr/local/bin/fpcalc
 -v                                  Verbose mode.
 -s [-i] DIR_TO_OUTPUT               Show all the duplicates for the specified library (DIR_TO_OUTPUT)
```

Of course this is an Alpha release, so some functionality is incomplete at the time of this writing. The `-i` and `-s` are currently not working.

### fsduplicates Concepts and Files

It's good to know some concepts I have defined in the development of fsduplicates to use it more effectively.

Whenever you see a command that takes a `DIR_TO_OUTPUT` parameter, this parameter is called a *Library Path*. When you are executing operations with fsduplicates, it will generate files and put them in this *Library*. You need to manually create this *Library*, either using finder or the Shell's `mkdir` dir, and pass it on to fsduplicates flags that need it.

The process of going through your music library and getting their `AcoustID`s is called *Indexing*. The indexing process will not move or delete any of your files. It will simply generate new text files with their data.

Depending on the commands, fsduplicates will generate some files inside the Library you passed it.

* `library`: This is a plain text file that has all the files it has indexed in a folder you passed as a `DIR_TO_SEARCH` parameter. For example, it can list all the songs it has proceeded in your `Music` folder in your Mac User Directory. This file helps fsduplicates avoid reindexing songs and make it more efficient.
* `fps_library`: Contains a list of song files and the `AcoustID`s returned by AcoustID. Each line has this format: `ACOUSTID:SONG_PATH`. For discovering duplicates, you'd use this file.
* `no_fps_library`: If AcoustID did not return a an `AcoustID` for one or more song files, their paths will be stored here. Consider contributing the fingerprints of the files listed here to AcoustID to improve their database.

You can open these files, but you should **never** edit them manually.

### Indexing Songs and Finding Duplicates

You can index your songs with the following command:

```Bash
fsduplicates -f DIR_TO_SEARCH DIR_TO_OUTPUT
```

For example, if you had music by the band Nightwish in the directory `/Volumes/iTunes/Music/Nightwish`, and you wanted to index them in a new library `~/Documents/fsduplicates_nightwish`, you would execute something like this:

```Bash
mkdir ~/Documents/fsduplicates_nightwish
fsduplicates -f /Volumes/iTunes/Music/Nightwish ~/Documents/fsduplicates_nightwish
```

Please note that **the indexing process can take a very long time** if the folder you want to index contains many songs or if you have a slow internet connection. fsduplicates needs to contact AcoustID's database for *every song* and return the results. And not only that, but AcoustID's rules force developers to not make more than three requests per second. For this reason fsduplicate calls `sleep(3)` which makes it wait 3 seconds for every 3 requests. Why three seconds instead of one? I do not want the app to appear like a crawler or like a spammy app in general, so I added a longer waiting time. On the plus side, you can start an indexing process and stop it before it completes. Next time you start the scanning process in the same Library, it will skip the files that have already been indexed, saving you some time.

You can try to calculate how long till an scanning operation completes. For example, if a folder contains 180 songs, it would take *at least* one minute for fsduplicates to finish indexing them. This is a rough estimate, because `fpcalc` doesn't return immediately either, and it can take a few seconds to finish, depending on the song length.

### Working with Duplicates

#### Automatic Analysis

*(Coming soon to a fsduplicates near you)*

#### Manual Analysis

In the very near future (hopefully), fsduplicate will have the ability to help you directly with your duplicates (actually there's some code already written for that), but until then, you will have to do some manual work.

After the indexing process is done, fsduplicates will create the three files in the Library I talked about earlier. Following the example above, these files would be:

* `~/Documents/fsduplicates_nightwish/library`
* `~/Documents/fsduplicates_nightwish/fps_library`
* `~/Documents/fsduplicates_nightwish/no_fps_library`

Having these files now, we can use some Shell commands to analyze them better. You don't need to install any new command line tools, as OS X/macOS already comes with the tools you need.

`cd` to the library (in this case, `~/Documents/fsduplicates_nightwish`), and execute these commands:

`cat fps_library`

This is the basic command to open a file and display it in your Terminal in any UNIX system. Here is a sample of its output:

```Text
d038b70a-7298-476f-a1d8-0a8dfdc0e831:/Volumes/iTunes/Music/Nightwish/Wishsides/2-08 A Return To The Sea.m4a
5cf10542-7fad-407c-995c-cd4b2ff0f8f0:/Volumes/iTunes/Music/Nightwish/Wishsides/2-09 Swanheart (Live).m4a
eda19d4e-38e4-496f-a107-c1217971d42f:/Volumes/iTunes/Music/Nightwish/Wishsides/2-10 Deep Sient Complete (Live).m4a
e8b0c206-3b72-43e9-a91b-6d4fbbdf8054:/Volumes/iTunes/Music/Nightwish/Wishsides/2-11 Dead Boys Poem (Live).m4a
5cae6bc9-47ff-4b8a-a4d2-8acdf774432d:/Volumes/iTunes/Music/Nightwish/Wishsides/2-12 Crimson Tide Deep Blue Sea (Live).m4a`
```

This will show you the list of indexed songs with their fingerprints in the order they were indexed. Not very useful on its own, but the `cat` command is the basis of many things you can do.

The following is a good command you can type to have a better idea of what songs are duplicates:

`cat fps_library | cut -d":" -f1 | sort | uniq -c | sort`

This command will show you just the `AcoustID`s of all the songs it indexed and how many times this show up. This is a sample on my own machine:

```Text
   3 dc663a4b-504a-433a-8460-470e14dbea63
   3 dd383e78-9abc-4b8a-b3e1-8c127322b657
   3 e783d332-254c-4e16-ad58-5c5298416b4e
   4 4a8cbe8e-01b9-415f-bf83-168c4efceacf
   4 b2f77e43-ed0d-4a1e-93b0-24cd08b3d9cf
   4 c22d1eb9-66cd-4566-b41d-6e68f79665a0
   4 c280a720-e92b-4ca0-aecf-3a4fe64386f3
   4 caef6e27-dc4b-45ad-9019-f16ab26830dd
   4 d3f69aac-af0a-4295-b419-47ecb61677e3
   5 772cd814-856e-4181-ab46-49d75bd6b080
   5 78718f73-162f-406e-9d87-276fa56998ed
   5 8278b2e9-eb61-48e7-aef0-254e2a59e739
   5 9552ca9a-94ca-41c6-a008-e90006f89b03
   5 d038b70a-7298-476f-a1d8-0a8dfdc0e831
   5 e9ffe05f-ad4a-4906-afca-26cbbf628787
   6 08fcc296-7d3f-483f-86ea-cfbe725d291d
   6 3b2ccbd5-3ed4-498a-bbd1-d915335927f4
```

Now you can tell that the `AcoustID` `3b2ccbd5-3ed4-498a-bbd1-d915335927f4` appears on your library *6 times!* With this knowledge in hand, you can now `cat fps_library` again and then `ctrl + f` to find the songs that share that ID. You can decide what to do with them (delete them? Move them? up to you).

I reiterate that fsduplicates will have tools to help you better manage duplicates in your library in the near future. In the meantime, this solution should be good for many people.

> **Warning!**
>
> Even if the `AcoustID`s are the same, you should take some care and listen to them before deleting them to ensure they really are the same song. Audio Fingerprinting works great and it has a strong mathematical background, but there's still a chance it will bring back inaccurate results. Still, AcoustID is used by many popular apps used by audiophiles, so there's probably little to worry about.

## For Developers

If you want to build upon this tool or submit pull requests, clone the `git clone` the project like you normally would.

You will have to do two additional steps, namely:

1. Get an AcoustID API key
2. Add that API key to the project.

To get an AcoustID API key, head over to the [AcoustID website](acoustid.org) and [register an application](https://acoustid.org/new-application). You will instantly get your API key. Please ensure that any changes you do to this project play by their rules.

To add the API key to the project, open the project file, extend the `Meta` group, and create a new `plist` there. Name it `client_id.plist`. Ensure that navigate to the physical `Meta` directory when the prompt asks you where to save the file, otherwise Xcode won't be able to find it.

Your `client_id.plist` should be like this:

```Text
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>client_id</key>
	<string>YOUR_API_KEY</string>
</dict>
</plist>
```

Replace `YOUR_API_KEY` with the API key you just got from AcoustID. You should be able to build the project now.
