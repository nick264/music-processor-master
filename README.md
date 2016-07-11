### Overview

This is an attempt to automatically produce cool light shows that react meaningfully to music, by taking beats and chords into account.  It works for any song (though some are more interesting than others).  

Given a url to a Youtube video, this program does the following:

1.  Downloads the video, extracts and saves the audio
2.  Queries Chordify for the beats/chords present in the Youtube video
3.  Chooses a color palette and mapping from chord -> color
4.  Plays the audio, while simulateneously streaming colors as USB serial data in real-time, as their corresponding chords occur in the music.

### Requirements

Tested in OSX and on a Raspberry Pi 2.  Meant to be used with an Arduino.

### Usage

Run start.rb, and optionally pass a url to a youtube video: e.g. `ruby start.rb --yt https://www.youtube.com/watch?v=FIzLbXz5Au4`.

If you don't pass a Youtube url, you'll be presented with a library of videos from which you can choose.  Every time you run `ruby start.rb` with a new Youtube url, it will save the audio to disk and add the video to the library.


__Note__: on Linux systems the music player is run with `sudo`.  GPIO pin access also may require root privileges.  Therefore I'd recommend running as root, e.g. `rvmsudo ruby start.rb`.

### Installing

1.  Install gems with `bundle install`
2.  Make sure you either have ffplay (OSX) or avplay (Linux) installed.  avplay should already be installed with most Linux dists.  On OSX, use Homebrew to install ffplay:

		brew install ffmpeg --with-ffplay

3.  Send arduino program to arduino

### Troubleshooting

If you have problems with Youtube video download, make sure to update with `youtube-dl -U`.  Updating the gem didn't update the binaries for me.

If ffplay isn't found, you probably didn't install ffmpeg with ffplay.  Run `brew uninstall ffmpeg` followed by `brew install ffmpeg --with-ffplay`.

If you're having problems communicating with the USB port, make sure nothing else is using it.  e.g. the serial monitor in the Arduino IDE.

If you get permissions errors, try running with `rvmsudo`.