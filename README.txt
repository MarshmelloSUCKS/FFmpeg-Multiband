#   __  __                                   _ _   _ _                  _
#  / _|/ _|_ __  _ __  ___ __ _    _ __ _  _| | |_(_) |__  __ _ _ _  __| |
# |  _|  _| '  \| '_ \/ -_) _' |  | '  \ || | |  _| | '_ \/ _' | ' \/ _` |
# |_| |_| |_|_|_| .__/\___\__, |  |_|_|_\_,_|_|\__|_|_.__/\__,_|_||_\__,_|
#               |_|       |___/                 by msx.gay
#  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
# 	FFmpeg Multiband - a bash script that uses FFmpeg to apply multiband
# compression to audio files. Includes auto-gain control with replaygain,
# 3-band compressor, stereo widening, and a 4x oversampled limiter.
#
# 	This script needs FFmpeg, basic GNU tools, and a bash shell to
# work. rsgain is recomended, and will apply ReplayGain levels before AGC.
# If needed, install ffmpeg and rsgain using your package manager.
#
# To use:
#   - download ffmpeg-multiband.sh
#   - copy it to the directory with the songs you want to convert
#   - open the script in a text editor, and adjust Basic Settings if
#     desired
#   - mark the script as executable with `chmod +x ffmpeg-multiband.sh`
#   - run the script with:
# 	  `./ffmpeg-multiband.sh [in ext] [out ext] [out bitrate] [trim/notrim]`
#
# Parameters:
#	[in ext]: Input file extension (mp3, flac)
#	[out ext]: Output file extension (mp3, flac)
#	[out bitrate]: Output file bitrate, in kbps
#	[trim/notrim]: Toggles silence trimming
#
# Examples:
#	FLAC input, MP3 320kbps output, no trimming:
#		./ffmpeg-multiband.sh flac mp3 320 notrim
#
#	FLAC input, FLAC output, trimming:
#		./ffmpeg-multiband.sh flac flac 1411 trim
#
#queer coded in 2026 by msx.gay - http://msx.gay
