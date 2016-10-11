#!/bin/bash


image_file=$1;
subjectId=$2;
caseId=$3;

if [[ "$image_file" != "" ]]; then
  echo "image file is provided by user!"
else
   echo "image file is required!"
   image_file="TCGA-DU-8164-01Z-00-DX1.7a39faea-a8f4-4da9-a3e9-b899192445c8.svs"
   subjectId="TCGA-DU-8164"
   caseId="TCGA-DU-8164-01Z-00-DX1"
fi

# define all local variables

image_file_path="/home/feiqiao/test/input"
seg_output_path="/home/feiqiao/test/output"
seg_output_file="results.zip"
featuredb_executable_path="/home/feiqiao/test/pathomics_featuredb/script"
segment_executable_path="/home/feiqiao/test/pathomics_analysis/nucleusSegmentation/script"
#image_file="TCGA-DU-8164-01Z-00-DX1.7a39faea-a8f4-4da9-a3e9-b899192445c8.svs"
#subjectId="TCGA-DU-8164"
#caseId="TCGA-DU-8164-01Z-00-DX1"
cancerType="lgg"
docker_container_featuredb="mydb1"
docker_container_analysis="myseg1"
dbpath="/home/feiqiao/test/db"
qryport=3000
dbport=27018
mongodb_name="u24_test"
docker_image_featuredb="database_docker:1.0"
docker_image_analysis="analysis_docker:1.0"
tile_minx=13000
tile_miny=13000
tile_width=512
tile_height=512
patch_width=256
patch_height=256
analysis_id="test1"
ship_step_3=no
dbhost="localhost"
dbDockerContainerRuning=no
analysisDockerContainerRuning=no




# find out analysis  docker container exists and is runing
echo "find out analysis  docker container exists and is runing"
matchingStarted=$(docker ps --filter="name=$docker_container_analysis" -q | xargs)
[[ -n $matchingStarted ]] && analysisDockerContainerRuning=yes

#remove analysis docker container if it exists but not runing
echo "remove analysis docker container if it exists but not runing"
matching=$(docker ps -a --filter="name=$docker_container_analysis" -q | xargs)
if [[ "$analysisDockerContainerRuning" = "no" ]] ; then
   [[ -n $matching ]] && docker rm $matching
fi


if [[ "$analysisDockerContainerRuning" = "no" ]]; then
  #step 4:create image analysis container with docker image 
  cd $segment_executable_path
  echo "step 4: Create image analysis container with docker image"
  ./run_docker_segment.py start $docker_container_analysis $docker_image_analysis
  echo "---------- after step 4 ----------------------------"
else
  echo "---------------- skip step 4 ------------"
fi

#step 5:Run whole slide image segmentation script.
cd $segment_executable_path
echo "step 5: Run whole slide image segmentation script."
./run_docker_segment.py segment $docker_container_analysis  $image_file_path/$image_file  $seg_output_path/$seg_output_file -s $tile_minx,$tile_miny -b $tile_width,$tile_height -d $patch_width,$patch_height -a $analysis_id -c $caseId -p $subjectId
echo "--------------  after step 5 ------------------"






