# CCTV camera image processing
Camera file collecting and processing to video output

## Purposes
I've couple of CCTV cameras on my house, and don't have any NVR. All cameras can upload files to FTP server, all the stuff to watch them online over RTSP protocol.
But I would like to have some records to watch what happend during last couple of days.

## Setup camers
Cameras have the ability to set motion detection, but image capture is not always ideal. 
There is a delay between capturing motion and creating the first record. 
Since the cameras can store only one frame per second, it happens that the capture of motion is usually in the phase when the object leaves the field of view of the camera.

I decided to record all day after one second. Images are uploaded to the FTP server.
- Set FTP connection on every camera with different directory.
- Set the image name patter where will be day in this format YYYYMMDD
- Set capturing the images by 1 second every day for all week.

## Setup server
I run VSFTPD server in Docker on my Ubuntu 19.10. It's very easy to run.

If you are running Docker then use this command to install VSFTPD server
```
docker run -d -v /my/data/directory:/home/vsftpd \
-p 20:20 -p 21:21 -p 21100-21110:21100-21110 \
-e FTP_USER=myuser -e FTP_PASS=mypass \
-e PASV_ADDRESS=127.0.0.1 -e PASV_MIN_PORT=21100 -e PASV_MAX_PORT=21110 \
--name vsftpd --restart=always fauria/vsftpd
```
where ```/my/data/directory``` is path where your data is physically. ```myuser``` and ```mypass``` are credentials for default user.

If you want to add another user to FTP just use
```
docker exec -i -t vsftpd bash
mkdir /home/vsftpd/myuser
echo -e "myuser\nmypass" >> /etc/vsftpd/virtual_users.txt
/usr/bin/db_load -T -t hash -f /etc/vsftpd/virtual_users.txt /etc/vsftpd/virtual_users.db
exit
docker restart vsftpd
```
When you have done all of this, then is time to download the ```cctv_camera_image_processing.sh``` script

## Setup the script
First of all you need to change the paths of source and destination.
```
source=/mnt/data/vsftpd/data/ufo/images/$dir_name
dest=/mnt/data/media/cameras/$dir_name
```
You cant putt it wherever you want in your file system. It is not super smart script. 
It does only moving files and changing from images to mp4 video and retains files for the specified days.

### Run script
You can run it in three options.
- Transform images to video ```./camera_daily_files_moving.sh <camera directory name>``` Name of the directory is without **PATH**
- Transform images to video and keep video file history ```./camera_daily_files_moving.sh <camera directory name> <days to history>```
- Transform images to video by defined day and keep video file history ```./camera_daily_files_moving.sh <camera directory name> <days to history> <day in YYYYMMDD format>```

## Repeatability
If you want to execute the script every day at some time then is neccessary to set up for example CRON.
To setup CRON use command ```crontab -e``` which will be open in your favorite terminal editor like **vi** or **nano**.
Then set this line
```
59 23 * * * /PATH/camera_daily_files_moving.sh <camera directory name> <days to keep videos into history>
```
This sets the script to run every day at 23:59

When you have more then one cameras, then just set more rows in cron with differend **camera directory names**
