#!/bin/bash

dbDockerName="mydb1"
image_file_path="/home/feiqiao/test/input"

#image_file="TCGA-FG-5964-01Z-00-DX1.971827c7-4e41-4b8c-af02-01b340cf4cbd.svs"
image_file="command_history.txt"

baseName=$(basename $image_file_path/$image_file)
echo $baseName

tempDir="staging"$$"-"$RANDOM
docker exec $dbDockerName mkdir /tmp/$tempDir
docker cp $image_file_path/$image_file $dbDockerName:/tmp/$tempDir/$baseName
docker exec -it $dbDockerName run_docker_validate_image_file.sh /tmp/$tempDir $baseName






       
		
		



