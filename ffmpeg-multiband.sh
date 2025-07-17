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

###AGC settings###
#AGC threshold (default: -16dB)
agcthreshold=-16dB
#AGC attack/release (default: 1000, 5000)
agcattack=1000
agcrelease=5000
#AGC highpass (default: 0, 30)
agchpstart=0
agchpend=30
#AGC lowpass (default: 20000, 22000)
agclpstart=20000
agclpend=22000

###Band 1 settings###
#Band 1 threshold (default: -21dB)
band1threshold=-21dB
#Band 1 ratio (default: 6)
band1ratio=6
#Band 1 attack/release (default: 200, 600)
band1attack=200
band1release=600
#Band 1 lowpass (defaults: 150, 600)
band1lpstart=150
band1lpend=600
#Band 1 makeup gain (default: 9dB)
band1gain=9dB

###Band 2 settings###
#Band 2 threshold (default: -21dB)
band2threshold=-21dB
#Band 2 ratio (default: 6)
band2ratio=6
#Band 2 attack/release (default: 200, 600)
band2attack=200
band2release=600
#Band 2 highpass (defaults: 62, 250)
band2hpstart=62
band2hpend=250
#Band 2 lowpass (defaults: 3000, 12000)
band2lpstart=3000
band2lpend=12000
#Band 2 makeup gain (default: 6dB)
band2gain=6dB

###Band 3 settings###
#Band 3 threshold (default: -27dB)
band3threshold=-27dB
#Band 3 ratio (default: 6)
band3ratio=6
#Band 3 attack/release (default: 100, 600)
band3attack=100
band3release=600
#Band 3 highpass (defaults: 875, 3000)
band3hpstart=875
band3hpend=3000
#Band 3 makeup gain (default: 6dB)
band3gain=6dB

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
	ffmpeg -hide_banner -y -i "$i" -filter_complex "[0:a] volume=replaygain=track, firequalizer=gain_entry='entry($agchpstart,-50); entry($agchpend, 0); entry($agclpstart,0); entry($agclpend, -50)', acompressor=detection=rms:threshold=$agcthreshold:ratio=20:attack=$agcattack:release=$agcrelease, volume="$compdrive"dB, asplit=3 [agc1][agc2][agc3],\
	[agc1] adelay=10|10, firequalizer=gain_entry='entry($band1lpstart,0); entry($band1lpend, -50)', acompressor=threshold=$band1threshold:ratio=$band1ratio:attack=$band1attack:release=$band1release:makeup=$band1gain [mb1],\
    [agc2] firequalizer=gain_entry='entry($band2hpstart,-50); entry($band2hpend, 0); entry($band2lpstart,0); entry($band2lpend, -50)', acompressor=threshold=$band2threshold:ratio=$band2ratio:attack=$band2attack:release=$band2release:makeup=$band2gain [mb2],\
    [agc3] firequalizer=gain_entry='entry($band3hpstart,-50); entry($band3hpend, 0)', acompressor=threshold=$band3threshold:ratio=$band3ratio:attack=$band3attack:release=$band3release:makeup=$band3gain [mb3],\
    [mb1][mb2][mb3] amix=inputs=3:normalize=0, extrastereo=m=1.5, volume="$limitdrive"dB, alimiter=attack=0.1:release=1:limit=-3dB:level=0" "Processing/${i%.*}-pretrim.flac"

    #Remove ReplayGain tags since they're no longer valid
    rsgain custom -s i "Processing/${i%.*}-pretrim.flac"
	
	#Final Export
	if [[ $trimming = trim ]]; then
		#Limiting and trimming
		ffmpeg -hide_banner -y -i "Processing/${i%.*}-pretrim.flac" -filter:a "silenceremove=start_periods=1: start_duration=0: start_threshold=-45dB: detection=peak,aformat=dblp,areverse,silenceremove=start_periods=1: start_duration=0: start_threshold=-35dB: detection=peak,aformat=dblp,areverse, volume="$limitdrive"dB, alimiter=attack=0.1:release=1:limit=-3dB:level=0" -ab "$bitrate"k "Processed/${i%.*}.$export"
	else
		#Limiting only
		ffmpeg -hide_banner -y -i "Processing/${i%.*}-pretrim.flac" -ab "$bitrate"k "Processed/${i%.*}.$export"
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
