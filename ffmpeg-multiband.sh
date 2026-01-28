#!/bin/bash

#===Basic Settings===

#===Sound settings===
# AGC drive (default: 0)
agcdrive=0
# Compressor drive (default: 0)
compdrive=0
# Limiter drive (default: 0)
limitdrive=0
#Stereo width (default: 1.5)
width=1.5

#===AGC settings===
# AGC attack speed (default: 1000)
agcattack=1000
# AGC release speed (default: 5000)
agcrelease=5000

#===Multiband settings===
# Compressor attack speed (default: 100)
compattack=100
# Compressor release speed (default: 500)
comprelease=500
# Compressor ratio (default: 6)
compratio=6

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
# 	  `./ffmpeg-multiband.sh [in ext] [out ext] [out bitrate] [comp drive]
#	  [limiter drive] [trim/notrim]`
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
    echo "  ./ffmpeg-multiband.sh [Input extension] [Output extension] [Output bitrate] [trim/notrim]"
    echo ""
    echo "Parameters:"
    echo "	[Input extension]: The file extension of the input (ex: mp3, flac)"
    echo "	[Output extension]: The file extension of the output (ex: mp3, flac)"
    echo "	[Output bitrate]: The bitrate of the output files, in kbps."
    echo "	[trim/notrim]: Toggles silence trimming."
    echo ""
    echo "Examples:"
    echo "	FLAC input, MP3 320kbps output, no trimming:"
    echo "		./ffmpeg-multiband.sh flac mp3 320 notrim"
    echo ""
    echo "	FLAC input, FLAC output, trimming:"
    echo "		./ffmpeg-multiband.sh flac flac 1411 trim"
    exit 0
fi

#Get the input values

#Input file extension
ext=$1
#Output file extension
export=$2
#Output file bitrate
bitrate=$3
#Silence trimming
trimming=$4

###AGC settings###
#AGC threshold (default: -16dB)
agcthreshold=-16dB
#AGC highpass (default: 0, 30)
agchpstart=0
agchpend=30
#AGC lowpass (default: 20000, 22000)
agclpstart=20000
agclpend=22000

###Band 1 settings###
#Band 1 threshold (default: -18dB)
band1threshold=-18dB
#Band 1 lowpass (defaults: 150, 600)
band1lpstart=150
band1lpend=600
#Band 1 makeup gain (default: 9dB)
band1gain=9dB

###Band 2 settings###
#Band 2 threshold (default: -21dB)
band2threshold=-21dB
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

	#Get samplerate of input file, we'll use this for re-sampling later
	sample=$(ffprobe -v error -show_entries stream=sample_rate -of default=nw=1:nk=1 "$i")
	oversample=$((sample*4))

	#Make directories required for processing
	mkdir Processing

	#Apply ReplayGain track data
	rsgain custom -s i "$i"

	#AGC and Multiband compression
	ffmpeg -hide_banner -y -i "$i" -filter_complex "[0:a] volume=replaygain=track, firequalizer=gain_entry='entry($agchpstart,-50); entry($agchpend, 0); entry($agclpstart,0); entry($agclpend, -50)', volume="$agcdrive"dB, acompressor=detection=rms:threshold=$agcthreshold:ratio=20:attack=$agcattack:release=$agcrelease, volume="$compdrive"dB, asplit=3 [agc1][agc2][agc3],\
	[agc1] adelay=10|10, firequalizer=gain_entry='entry($band1lpstart,0); entry($band1lpend, -50)', acompressor=threshold=$band1threshold:ratio=$compratio:attack=$compattack:release=$comprelease:makeup=$band1gain [mb1],\
    [agc2] firequalizer=gain_entry='entry($band2hpstart,-50); entry($band2hpend, 0); entry($band2lpstart,0); entry($band2lpend, -50)', acompressor=threshold=$band2threshold:ratio=$compratio:attack=$compattack:release=$comprelease:makeup=$band2gain [mb2],\
    [agc3] firequalizer=gain_entry='entry($band3hpstart,-50); entry($band3hpend, 0)', acompressor=threshold=$band3threshold:ratio=$compratio:attack=$compattack:release=$comprelease:makeup=$band3gain [mb3],\
    [mb1][mb2][mb3] amix=inputs=3:normalize=0, extrastereo=m=$width, volume="$limitdrive"dB, aresample=$oversample, alimiter=attack=0.1:release=1:limit=-3.1dB:level=0, aresample=$sample" "Processing/${i%.*}-pretrim.flac"

    #Remove ReplayGain tags since they're no longer valid
    rsgain custom -s i "Processing/${i%.*}-pretrim.flac"
	
	#Final Export
	if [[ $trimming = trim ]]; then
		#Trimming
		ffmpeg -hide_banner -y -i "Processing/${i%.*}-pretrim.flac" -filter:a "silenceremove=start_periods=1: start_duration=0: start_threshold=-45dB: detection=peak,aformat=dblp,areverse,silenceremove=start_periods=1: start_duration=0: start_threshold=-35dB: detection=peak,aformat=dblp,areverse" -ab "$bitrate"k "Processed/${i%.*}.$export"
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
