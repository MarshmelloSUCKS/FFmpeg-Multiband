   __  __                                   _ _   _ _                  _
  / _|/ _|_ __  _ __  ___ __ _    _ __ _  _| | |_(_) |__  __ _ _ _  __| |
 |  _|  _| '  \| '_ \/ -_) _' |  | '  \ || | |  _| | '_ \/ _' | ' \/ _` |
 |_| |_| |_|_|_| .__/\___\__, |  |_|_|_\_,_|_|\__|_|_.__/\__,_|_||_\__,_|
               |_|       |___/                 by msx.gay
  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

 	FFmpeg Multiband - a bash script that uses FFmpeg to apply multiband
 compression to audio files. Includes auto-gain control with replaygain,
 3-band compressor, stereo widening, and a limiter.

 	This script needs FFmpeg, basic GNU tools, and a bash shell to
 work. rsgain is recomended, and will apply ReplayGain levels before AGC.
 If needed, install ffmpeg and rsgain using your package manager.

 	To use, download ffmpeg-multiband.sh, copy it to the directory with
 the songs you want to convert, mark the script as executable with
 `chmod +x ffmpeg-multiband.sh`, and run the script by typing:
 	`./ffmpeg-multiband.sh [in ext] [out ext] [out bitrate] [comp drive]
	[limiter drive] [trim/notrim]`

 Parameters:
	[in ext]: Input file extension (mp3, flac)
	[out ext]: Output file extension (mp3, flac)
	[out bitrate]: Output file bitrate, in kbps
	[comp drive]: Input level to compressor in dB
	[limiter drive]: Input level to limiter in dB
	[trim/notrim]: Toggles silence trimming

 Examples:
	FLAC input, MP3 320kbps output, no compressor or limiter drive, no
	trimming:
		./ffmpeg-multiband.sh flac mp3 320 0 0 notrim

	FLAC input, FLAC output, no compressor drive, +3dB drive, trimming:
		./ffmpeg-multiband.sh flac flac 1411 0 3 trim

	M4A input, FLAC output, -3dB compressor drive, +3dB limiter drive,
	trimming:
		./ffmpeg-multiband.sh m4a flac 1411 -3 3 trim

queer coded in 2025 by msx.gay - http://msx.gay
