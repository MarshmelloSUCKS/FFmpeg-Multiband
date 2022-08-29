# FFmpeg Multiband - A multiband compressor script using FFmpeg

## = = ABOUT = = 
This script was made so I could batch process a collection of music files. Audacity doesn't have a multiband compressor, so I used the best audio/video encoding tool on the open-source planet: FFmpeg!

You can use this tool to process most popular audio file formats. Multiple processing options are available, meaning you can have a bit of compression or lots of it.

## = = PREREQUISITES = = 

FFmpeg - Needed for compression and processing.

Sox - Needed for file normalization.

libsox-fmt-all - Needed by SoX for support of various audio formats

These can be installed on Debian systems by running `apt install ffmpeg sox libsox-fmt-all`.

## = = USAGE = =
Drop the bash script in a folder with music. All files you want to process have to be in the same folder as the script.

If need be, run `chmod +x FFmpeg-Multiband` to mark the file as executable.

Run `./FFmpeg-Multiband.sh`. You will be presented with several options. Here's an example:

```
= = = INPUT FILE EXTENSION = = =
What is the extension of the files you are converting?
ex. (mp3) or (flac)
mp3

= = = OUTPUT FILE FORMAT = = =
What format are you exporting to?
Example: mp3, ogg, flac
mp3

= = = OUTPUT FILE BITRATE = = =
What bitrate would you like to export to?
Values in kbps, ex. (128) for 128kbps
320

= = = POST-PROCESSING = = =
Post-process files? This may be helpful if you want extra amplification.
Enter [light], [heavy], [overdrive], or press enter for none. light is recommended.
overdrive

= = = SILENCE TRIMMING = = =
Trim silence from the beginning and end of files?
Enter (yes) to trim, or press enter for no trimming.
yes

= = = FILE NAME ADDITIONS = = =
Would you like to add anything to the end of the file name?
If so, enter it here. If not, press enter.
-overdrive
```

The script will make two folders, one named `Processing` and another named `Processed`. The `Processing` folder is used as temporary storage. When the script is done, all of the results will be in `Processed`. 

## = = TO-DO = =
- Make FFmpeg output silent while showing encode progress
- Use FFmpeg for normalization

## = = TO-DONE = =
- Move finished files to separate folder
- Delete temporary folder instead of files
- Add low-mid band to improve lower mids
