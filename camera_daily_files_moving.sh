#!/bin/bash

#################################################################
# Script moving camera files on daily purposes and converting
# them to the video.
# Can holding predefined days back to the past
#
# 27.10.2020
# horalek.jiri@gmail.com
#
#################################################################

dir_name=$1 # directory name source nad destination is same
day_history=$2 # number of days for data backup
custom_date=$3

if [ -z "$dir_name" ]; then
	echo  "Directory is not set"
	exit 1
fi

source=/mnt/data/vsftpd/data/ufo/images/$dir_name
dest=/mnt/data/media/cameras/$dir_name

curr_date=$(date '+%Y%m%d')

# when custom date is presented, then override the curr_date
if [ ! -z "$custom_date" ]; then
	curr_date=$custom_date
fi

if [ ! -d "$dest/$curr_date" ]; then
	mkdir "$dest/$curr_date"
fi

#################################################################
# Moving the files from source directory to destination
#################################################################
find $source/ -iname "*$curr_date*" -exec mv {} $dest/$curr_date/ \;

#################################################################
# Create movie from images
#################################################################
ffmpeg -framerate 25 -pattern_type glob -i  "$dest/$curr_date/*.jpg" -c:v libx264 -r 30 -pix_fmt yuv420p "$dest/$curr_date.mp4"

#################################################################
# When video is existing, then we can delete images
#################################################################
if [ -f "$dest/$curr_date.mp4" ]; then
	echo "Deleting files from $dest/$curr_date/ destination"
	rm -rf "$dest/$curr_date/"
fi

#################################################################
# Deleting old files older then today - day_history
#################################################################

if [ -z "$day_history" ]; then
	exit 1
fi

source=/mnt/data/vsftpd/data/ufo/images/$dir_name
dest=/mnt/data/media/cameras/$dir_name

# array with all existing video files
existing_files=()

for image in "$dest/*.mp4"
do
        # get the file name from the path
        file_name=$(basename $image)
        # add the name of the file without postfix
        existing_files=(${existing_files[@]} ${file_name%.*})
done

# array of all dates which will be persisted
dates=()

for i in $(seq 0 $[day_history -1])
do
        i_date=$(date -d "$curr_date-$i days" "+%Y%m%d")
        dates=(${dates[@]} $i_date)
done

# loop through existing files and looking for those, which are not
# in dates array. They will be deleted immediately.
files_to_delete=()

# iterate through array with index. INDEX IS !
for x in "${!existing_files[@]}"
do
        f_name=${existing_files[x]}
        # when file is not dates array, then should be deleted
        if [[ ! " ${dates[@]} " =~ " $f_name " ]]; then
                files_to_delete=(${files_to_delete[@]} $f_name)
        fi
done

# delete all files in array files_to_delete
for f in "${files_to_delete[@]}"
do
        rm "$dest/$f.mp4"
done
