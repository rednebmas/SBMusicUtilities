SBMusicUtilities
================

This is a collection of classes that I use in apps that I'm working on. This library is dependent on the amazing audio library [EZAudio](https://github.com/syedhali/EZAudio) by Syed Haris Ali.


# Classes

## SBNote
Lots of math/music stuff.

- Calculate note name for frequency
	- E.g. 133 hz to C3 + 29 cents
- Calculate frequency for note name
	- E.g. "A4" to 440 hz
- And much more...

#### SBPlayableNote
Used by SBAudioPlayer.

## SBRandomNoteGenerator

Generates random notes within a specified range.

## SBAudioPlayer
Play a sinewave, or instrument samples, from a SBNote instance.