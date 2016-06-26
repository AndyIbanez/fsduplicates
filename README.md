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
