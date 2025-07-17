#!/bin/bash

#   __  __                                   _ _   _ _                  _
#  / _|/ _|_ __  _ __  ___ __ _    _ __ _  _| | |_(_) |__  __ _ _ _  __| |
# |  _|  _| '  \| '_ \/ -_) _' |  | '  \ || | |  _| | '_ \/ _' | ' \/ _` |
# |_| |_| |_|_|_| .__/\___\__, |  |_|_|_\_,_|_|\__|_|_.__/\__,_|_||_\__,_|
#               |_|       |___/                 by msx.gay
#  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
# 	FFmpeg Multiband - a bash script that uses FFmpeg to apply multiband
# compression to audio files. Includes auto-gain control with replaygain,
# 3-band compressor, stereo widening, and a limiter.
#
# 	This script needs FFmpeg, basic GNU tools, and a bash shell to
# work. rsgain is recomended, and will apply ReplayGain levels before AGC.
# If needed, install ffmpeg and rsgain using your package manager.
#
# 	To use, download ffmpeg-multiband.sh, copy it to the directory with
# the songs you want to convert, mark the script as executable with
# `chmod +x ffmpeg-multiband.sh`, and run the script by typing:
# 	`./ffmpeg-multiband.sh [in ext] [out ext] [out bitrate] [comp drive]
#	[limiter drive] [trim/notrim]`
#
# Parameters:
#	[in ext]: Input file extension (mp3, flac)
#	[out ext]: Output file extension (mp3, flac)
#	[out bitrate]: Output file bitrate, in kbps
#	[comp drive]: Input level to compressor in dB
#	[limiter drive]: Input level to limiter in dB
#	[trim/notrim]: Toggles silence trimming
#
# Examples:
#	FLAC input, MP3 320kbps output, no compressor or limiter drive, no
#	trimming:
#		./ffmpeg-multiband.sh flac mp3 320 0 0 notrim
#
#	FLAC input, FLAC output, no compressor drive, +3dB drive, trimming:
#		./ffmpeg-multiband.sh flac flac 1411 0 3 trim
#
#	M4A input, FLAC output, -3dB compressor drive, +3dB limiter drive,
#	trimming:
#		./ffmpeg-multiband.sh m4a flac 1411 -3 3 trim
#
#queer coded in 2025 by msx.gay - http://msx.gay

echo " - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  "
echo "  __  __                                   _ _   _ _                  _ "
echo " / _|/ _|_ __  _ __  ___ __ _    _ __ _  _| | |_(_) |__  __ _ _ _  __| |"
echo "|  _|  _| '  \| '_ \/ -_) _' |  | '  \ || | |  _| | '_ \/ _' | ' \/ _' |"
echo "|_| |_| |_|_|_| .__/\___\__, |  |_|_|_\_,_|_|\__|_|_.__/\__,_|_||_\__,_|"
echo "              |_|       |___/                 by msx.gay                "
echo " - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  "

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo " "
    echo "Usage:"
    echo "  ./ffmpeg-multiband.sh [Input extension] [Output extension] [Output bitrate] [Compressor drive] [Limiter drive] [trim/notrim]"
    echo ""
    echo "Parameters:"
    echo "	[Input extension]: The file extension of the input (ex: mp3, flac)"
    echo "	[Output extension]: The file extension of the output (ex: mp3, flac)"
    echo "	[Output bitrate]: The bitrate of the output files, in kbps."
    echo "	[Compressor drive]: The input level to the compressor, in dB."
    echo "		I recommend 9dB as a maximum."
    echo "	[Limiter drive]: The input level to the limiter, in dB."
    echo "		I recommend 3dB as a maximum."
    echo "	[trim/notrim]: Toggles silence trimming."
    echo ""
    echo "Examples:"
    echo "	FLAC input, MP3 320kbps output, no compressor or limiter drive, no trimming:"
    echo "		./ffmpeg-multiband.sh flac mp3 320 0 0 notrim"
    echo ""
    echo "	FLAC input, FLAC output, no compressor drive, +3dB drive, trimming:"
    echo "		./ffmpeg-multiband.sh flac flac 1411 0 3 trim"
    echo ""
    echo "	M4A input, FLAC output, -3dB compressor drive, +3dB limiter drive, trimming:"
	echo "		./ffmpeg-multiband.sh m4a flac 1411 -3 3 trim"
    exit 0
fi

#Get the input values

#Input file extension
ext=$1
#Output file extension
export=$2
#Output file bitrate
bitrate=$3
#Compressor drive
compdrive=$4
#Limiter drive
limitdrive=$5
#Silence trimming
trimming=$6

#Make a place to put the result
echo "Making Processed/"
mkdir Processed

# # # that good stuff # # #
for i in *.$ext
do 	
	
	echo "= = = Processing $i = = ="
	sleep 1

	#Make directories required for processing
	mkdir Processing

	#Apply ReplayGain track data
	rsgain custom -s i "$i"

	#AGC and Multiband compression
	ffmpeg -hide_banner -y -i "$i" -filter_complex "[0:a] volume=replaygain=track, firequalizer=gain_entry='entry(0,-50); entry(30, 0); entry(20000,0); entry(22000, -50)', acompressor=detection=rms:threshold=-16dB:ratio=20:attack=1000:release=5000, volume="$compdrive"dB, asplit=3 [agc1][agc2][agc3],\
	[agc1] adelay=10|10, firequalizer=gain_entry='entry(150,0); entry(600, -50)', acompressor=threshold=-21dB:ratio=6:attack=200:release=600:makeup=9dB [mb1],\
    [agc2] firequalizer=gain_entry='entry(62,-50); entry(250, 0); entry(3000,0); entry(12000, -50)', acompressor=threshold=-21dB:ratio=6:attack=200:release=600:makeup=6dB [mb2],\
    [agc3] firequalizer=gain_entry='entry(875,-50); entry(3500, 0)', acompressor=threshold=-27dB:ratio=6:attack=100:release=600:makeup=6dB [mb3],\
    [mb1][mb2][mb3] amix=inputs=3:normalize=0, extrastereo=m=1.5" "Processing/${i%.*}-preamp.flac"
	
	#Final Export
	if [[ $trimming = trim ]]; then
		#Limiting and trimming
		ffmpeg -hide_banner -y -i "Processing/${i%.*}-preamp.flac" -filter:a "silenceremove=start_periods=1: start_duration=0: start_threshold=-45dB: detection=peak,aformat=dblp,areverse,silenceremove=start_periods=1: start_duration=0: start_threshold=-35dB: detection=peak,aformat=dblp,areverse, volume="$limitdrive"dB, alimiter=attack=0.1:release=1:limit=-3dB:level=0" -ab "$bitrate"k "Processed/${i%.*}.$export"
	else
		#Limiting only
		ffmpeg -hide_banner -y -i "Processing/${i%.*}-preamp.flac" -filter:a "volume="$limitdrive"dB, alimiter=attack=0.1:release=1:limit=-3dB:level=0" -ab "$bitrate"k "Processed/${i%.*}.$export"
	fi

	#Remove temporary files
	rm -r "Processing/"
	
	echo "= = = Finished processing $i = = ="
	sleep 1
	
done
# # # BATCH PROCESSING DONE # # #
echo " - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  "
echo "                            _              __ _      _    _           _ "
echo " _ __ _ _ ___  __ ___ _____(_)_ _  __ _   / _(_)_ _ (_)__| |_  ___ __| |"
echo "| '_ \ '_/ _ \/ _/ -_|_-<_-< | ' \/ _' | |  _| | ' \| (_-< ' \/ -_) _' |"
echo "| .__/_| \___/\__\___/__/__/_|_||_\__, | |_| |_|_||_|_/__/_||_\___\__,_|"
echo "|_|                               |___/                                 "
echo " - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  "
echo "The processed files will be under Processed/"
echo "thank you for using! ^.^"
