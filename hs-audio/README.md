# Instructions

## Infrastructure

### Necessary Software

Install `stack` (look it up oops). At the time of me writing this, I'm using ghc version 9.4.8, and hls is running on version 2.9.0.0

### Running Tests

Provided you have `stack` installed, running `stack test` will test your lab code.

## Lab Introduction
In this lab, we will be manipulating audio files to produce some neat effects. This set's distribution contains not only a template file that you should use for developing your code (`src/Lib.hs`) but also several audio files in the sounds directory, with names ending with .wav (you can try opening these files in an audio editing program to hear their contents).

Over the course of this lab, we will refresh ourselves on some important features and structures within Haskell, use command line tools to help debug our code and improve its style, and familiarize ourselves with interactions with files on disk (and create some really neat sound effects as well).

## Representing Sound
In physics, when we talk about a sound, we are talking about waves of air pressure. When a sound is generated, a sound wave consisting of alternating areas of relatively high pressure ("compressions") and relatively low air pressure ("rarefactions") moves through the air.

When we use a microphone to capture a sound digitally, we do so by making periodic measurements of an electrical signal proportional to this air pressure. Each individual measurement (often called a "sample") corresponds to the air pressure at a single moment in time; by taking repeated measurements at a constant rate (the "sampling rate," usually measured in terms of the number of samples captured per second), these measurements together form a representation of the sound by approximating how the air pressure was changing over time.

When a speaker plays back that sound, it does so by converting these measurements back into waves of alternating air pressure (by moving a diaphragm in a speaker proportionally to those captured measurements). In order to faithfully represent a sound, we need to know two things: both the sampling rate and the samples that were actually captured.

For sounds recorded in mono, each sample is a positive or negative number corresponding to the air pressure at a point in time. For sounds recorded in stereo, each sample can be thought of as consisting of two values: one for the left speaker and one for the right.

### Haskell Representation
We will be working with files stored in the [WAV](https://en.wikipedia.org/wiki/WAV) format. However, you won't need to understand that format in detail, as we have provided some "helper functions" in `src/Lib.hs` to load the information from those files into Haskell-usable format, as well as to take sounds in that Haskell-usable representation and save them as WAV files.

In Haskell, we'll represent a sound as a data type with two constructors as follows (which you can also see in your `src/Lib.hs` file):
```
data Sound = MkMonoSound Rate [Sample] | MkStereoSound Rate [Sample] [Sample]
  deriving (Show)
```
A _mono_ sound, created with the first constructor, takes a Rate (which is a type alias for Int) as the number of samples to play per second, and a list of Samples (which is a type alias for Doubles). A _stereo_ sound, created with the second constructor, still takes a Rate and interprets it as the number of samples to play per second, but has two lists of Samples. The first list contains samples coming from the left speaker, while the second speaker contains samples coming from the right speaker.

For example, the following is a valid sound:

```
s :: Sound
s = MkMonoSound 8000 [1.00, 0.91, 0.67, 0.31, -0.10, -0.50, -0.81, -0.98, -0.98, -0.81]
```

## Manipulations
In this lab, we will examine the effects of various kinds of manipulations of audio represented in this form.

### Backwards Audio
We'll implement our first manipulation via a function called `backwards`. This function should take a sound (using the representation described above) as its input, and it should return a new sound that is the reversed version of the original.

Reversing real-world sounds can create some neat effects. For example, consider a crash cymbal (which you can find in at `sounds/crash.wav`). When reversed, it sounds like the WAV file in `sounds/backwards_crash.wav`.

When we talk about reversing a sound in this way, we are really just talking about reversing the order of its samples (in both the left and right channels) but keeping the sampling rate the same.

Go ahead and implement the backwards function in your `src/Lib.hs` file. After doing so, navigate to the lab's directory in your terminal and run `stack test --ta '-p "Backwards"'`. If your code is correct you should see that the two backwards test cases are successfully passing.

It can also be fun to play around with these things a little bit. For example, mystery.wav is a recording of one of the instructors speaking nonsense. Let's try using our new function to produce a modified version of that file.

Note that we have provided some example code in the `app/Main.hs` file, which demonstrates how to use the `getSound` and `writeSound` functions. This is a good place to put code for generating files, or other quick tests. Note that `getSound` takes in a `String` which is the filepath of the `.wav` file to read, and also a `Bool`. This `Bool` should be `True` when you want to parse a stereo file, and `False` when you want to parse a mono file.

Try using some similar code to create a reversed version of mystery.wav by: loading mystery.wav, calling backwards on it to produce a new sound, and saving that sound with a different filename (ending with .wav). If you listen to that new file, you might be able to interpret the secret message (I wasn't able to though lmao still makes no sense to me)!

### Mixing Audio
Next, we'll look at mixing two sounds together to create a new sound. We'll implement this behavior as a function called mix. mix should take three inputs: two sounds (in out `data Sound` type) and a "mixing parameter" $p$ (a `Float` such that $0 \leq p \leq 1$).

The resulting sound should take $p$ times the samples in the first sound and $1-p$ times the samples in the second sound, and add them together to produce a new sound.

The two input sounds should have the same sampling rate. If you are provided with sounds of two different sampling rates, you should return `Nothing` instead of returning a sound.

However, despite having the same sampling rate, the input sounds might have different durations. The length of the resulting sound should be the minimum of the lengths of the two input sounds, so that we are guaranteed a result where we can always hear both sounds (it would be jarring if one of the sounds cut off in the middle).

### Echo
Next, we'll implement a classic effect: an echo filter. We simulate an echo by starting with our original sound, and adding one or more additional copies of the sound, each delayed by some amount and scaled down so as to be quieter.

We will implement this filter as a function called `echo :: Sound -> Int -> Float -> Float -> Sound`. This function should take the following arguments:

- `sound`: a `data Sound` instance representing the original sound
- `numEchoes`: the number of additional copies of the sound to add
- `delay`: the amount (in **seconds**) by which each "echo" should be delayed
- `scale`: the amount by which each echo's samples should be scaled

A good first place to start is by determining how many samples each copy should be delayed by. To make sure your results are consistent with our checker, you should use Haskell's `round` function: `sampleDelay = round $ delay * rate`, where `rate` is the rate of the input sound.

We should add in a delayed and scaled-down copy of the sound's samples (scaled by the given `scale` value and offset by `sampleDelay` samples). Note that each new copy should be scaled down more than the one preceding it (the first should be multiplied by `scale`, the second by a total of `scale^2`, the third by a total of `scale^3`, and so on).

All told, the output should be `numEchoes * sampleDelay` samples longer than the input in order to avoid cutting off any of the echoes.

Implement the echo filter by filling in the definition of the `echo` function in `src/Lib.hs`.


## Stereo Effects
For the last few audio effects in this lab, we'll focus on stereo sounds (files that have separate lists of samples for the left and right speakers).

### Pan

For our first effect using stereo sound, we'll create a really neat spatial effect. **Note** that this effect is most noticeable if you are wearing headphones; it may not be too apparent through laptop speakers.

We achieve this effect by adjusting the volume in the left and right channels separately, so that the left channel starts out at full volume and ends at 0 volume (and vice versa for the right channel).

In particular, if we start with a stereo sound that is $N$ samples long, then:

- We scale the first sample in the left channel by $1$, the second by $\frac{1}{N-1}$, the third by $\frac{2}{N-1}$, ... and the last by $0$.

- At the same time, we scale the first sample in the right channel by $0$, the second by $\frac{1}{N-1}$, the third by $\frac{2}{N-1}$, ... and the last by $1$.

Go ahead and implement this as a function pan in your `src/Lib.hs` file. The function should take a stereo sound as described above, and return a new stereo sound.

### Removing Vocals from Music

The final example for this lab is a little trick for (kind of) removing vocals from a piece of music, creating a version of the song that would be appropriate as a backing track for karaoke night.

This effect will take a stereo sound as input, but it will produce a mono sound as output. For each sample in the (stereo) input sound, we compute (`left-right`), i.e., the difference between the left and right channels at that point in time, and use the result as the corresponding sample in the (mono) output sound.

That might seem like a weird approach to take, but we can hear that the results are pretty good. Although some of the instruments are a little bit distorted, and some trace of the vocal track remains, this approach did a pretty good job of removing the vocals while preserving most everything else.

It may seem weird that subtracting the left and right channels should remove vocals! But it did work, so...how does this work? And why does it only work on certain songs? Well, it comes down to a little bit of a trick of the way songs tend to be recorded. Typically, many instruments are recorded so that they favor one side of the stereo track over the other (for example, the guitar track might be slightly off to one side, the bass slightly off to the other, and various drums at various "positions" as well). By contrast, vocals are often recorded mono and played equally in both channels. When we subtract the two, we are removing everything that is the same in both channels, which often includes the main vocal track (and often not much else). However, there are certainly exceptions to this rule; and, beyond differences in recording technique, certain vocal effects like reverb tend to introduce differences between the two channels that make this technique less effective.

Anyway, now would be a good time to go ahead and implement this manipulation by filling in the definition of the `removeVocals` function in `src/Lib.hs`. After implementing remove_vocals, running `stack test` in the command line should result in all test cases passing.
