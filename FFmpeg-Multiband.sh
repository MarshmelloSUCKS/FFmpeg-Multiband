#!/bin/bash

# # # FFmpeg Multiband Script - Version 0.0 # # #
# # # Made by IowanEASFan - msx.gay # # # # # # #

# # TO-DO # # 
# Reduce reliance on Sox, ideally do normalization with FFmpeg
# Change FFmpeg output to quiet while showing progress

# # TO-DONE # # 
# Move finished files to separate independent folder
# Delete entire temp folder instead of files
# Add low-mid band to improve sound quality

# BEFORE RUNNING:
# This script requires FFmpeg, Sox, and libsox-fmt-all. Install using:
# # sudo apt install ffmpeg sox libsox-fmt-all #For Debian systems

echo "= = = INPUT FILE EXTENSION = = ="
echo "What is the extension of the files you are converting?"
echo "ex. (mp3) or (flac)"
read ext

echo -e "\n= = = OUTPUT FILE FORMAT = = ="
echo "What format are you exporting to?"
echo "Example: mp3, ogg, flac"
read export

echo -e "\n= = = OUTPUT FILE BITRATE = = ="
echo "What bitrate would you like to export to?"
echo "Values in kbps, ex. (128) for 128kbps"
read bitrate

echo -e "\n= = = POST-PROCESSING = = ="
echo "Post-process files? This may be helpful if you want extra amplification."
echo "Enter [light], [heavy], [overdrive], or press enter for none. light is recommended."
read postprocess

echo -e "\n= = = SILENCE TRIMMING = = ="
echo "Trim silence from the beginning and end of files?"
echo "Enter (yes) to trim, or press enter for no trimming."
read trimming

echo -e "\n= = = FILE NAME ADDITIONS = = ="
echo "Would you like to add anything to the end of the file name?"
echo "If so, enter it here. If not, press enter."
read additional
	
echo "Making Processed/"
mkdir Processed

# # # BATCH PROCESSING BEGINS HERE # # #
for i in *.$ext
do 	
	#Make directories required for processing
	echo "Making Processing/"
	mkdir Processing
	
	echo "= = = Processing $i = = ="

	#Use Sox to normalize files
		echo Running Sox, may take a second...
		sox --norm "$i" "Processing/${i%.*}.flac"

	#Low-band compression
	/usr/bin/ffmpeg -y -i "Processing/${i%.*}.flac" -filter:a "lowpass=frequency=75,anequalizer=c0 f=55 w=55 g=2|c1 f=60 w=35 g=2, acompressor=threshold=-23dB:ratio=3:attack=25:release=250:makeup=11dB" "Processing/${i%.*}-lo.flac"

	#Low-Mid band compression
	/usr/bin/ffmpeg -y -i "Processing/${i%.*}.flac" -filter:a "highpass=frequency=350, lowpass=frequency=750, acompressor=threshold=-19dB:ratio=3:attack=75:release=450:makeup=4dB" "Processing/${i%.*}-lomid.flac"

	#Mid-band compression
	/usr/bin/ffmpeg -y -i "Processing/${i%.*}.flac" -filter:a "lowpass=frequency=3750,highpass=frequency=500,anequalizer=c0 f=450 w=250 g=-4|c1 f=450 w=250 g=-4, acompressor=threshold=-19dB:ratio=3:attack=75:release=450:makeup=5dB" "Processing/${i%.*}-mid.flac"
	
	#High-band compression
	/usr/bin/ffmpeg -y -i "Processing/${i%.*}.flac" -filter:a "highpass=frequency=7000,acompressor=threshold=-30dB:ratio=2.5:attack=25:release=100:makeup=8dB" "Processing/${i%.*}-hi.flac"

	#Combine low, mids, and high
	/usr/bin/ffmpeg -y -i "Processing/${i%.*}-lo.flac" -i "Processing/${i%.*}-lomid.flac" -i "Processing/${i%.*}-mid.flac" -i "Processing/${i%.*}-hi.flac" -filter_complex "amix=inputs=4:duration=first:dropout_transition=4" -ac 2 "Processing/${i%.*}-preamp.flac"

	#Use Sox to normalize files (I'd use FFmpeg but its normalization is shit)
		echo Running Sox, may take a second...
		sox --norm "Processing/${i%.*}-preamp.flac" "Processing/${i%.*}-prepost.flac"

	#Add post-processing, but only if selected
	if [[ $postprocess = light ]]; then
		/usr/bin/ffmpeg -y -i "Processing/${i%.*}-prepost.flac" -filter:a "extrastereo=m=1.5, acompressor=threshold=-8dB:ratio=4:attack=75:release=500:makeup=2dB" "Processing/${i%.*}-prelimit.flac"
	elif [[ $postprocess = heavy ]]; then
		/usr/bin/ffmpeg -y -i "Processing/${i%.*}-prepost.flac" -filter:a "extrastereo=m=2, acompressor=threshold=-14dB:ratio=5:attack=50:release=250:makeup=5dB" "Processing/${i%.*}-prelimit.flac"
	elif [[ $postprocess = overdrive ]]; then
		/usr/bin/ffmpeg -y -i "Processing/${i%.*}-prepost.flac" -filter:a "extrastereo=m=2, acompressor=threshold=-16dB:ratio=3:attack=50:release=150:makeup=10dB" "Processing/${i%.*}-prelimit.flac"
	else 
		/usr/bin/ffmpeg -y -i "Processing/${i%.*}-prepost.flac" -filter:a "volume=1dB" "Processing/${i%.*}-prelimit.flac" 
	fi
	
	#Final Export
	if [[ $trimming = yes ]]; then
		#Limiting and trimming
		/usr/bin/ffmpeg -y -i "Processing/${i%.*}-prelimit.flac" -filter:a "volume=-1.5dB, silenceremove=start_periods=1: start_duration=0: start_threshold=-50dB: detection=peak,aformat=dblp,areverse,silenceremove=start_periods=1: start_duration=0: start_threshold=-45dB: detection=peak,aformat=dblp,areverse" -ab "$bitrate"k "Processed/${i%.*}$additional.$export"
	else
		#Limiting only
		/usr/bin/ffmpeg -y -i "Processing/${i%.*}-prelimit.flac" -filter:a "volume=-1.5dB" -ab "$bitrate"k "Processed/${i%.*}$additional.$export"
	fi
	

	#acompressor=threshold=-9dB:ratio=5:attack=125:release=750:makeup=6dB
	
	#Remove temporary files
	rm -r "Processing/"
	
	echo "= = = Done processing $i = = ="
	
	sleep 2
	
done
# # # BATCH PROCESSING ENDS HERE # # # 

echo "= = = Done processing files! = = ="
echo "The processed files will be under Processed/"