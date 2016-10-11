#!/bin/bash


# define all local variables

image_file_path="/home/feiqiao/test/input"
seg_output_path="/home/feiqiao/test/output"
seg_output_file="results.zip"
featuredb_executable_path="/home/feiqiao/test/pathomics_featuredb/script"
segment_executable_path="/home/feiqiao/test/pathomics_analysis/nucleusSegmentation/script"
image_file="TCGA-DU-8164-01Z-00-DX1.7a39faea-a8f4-4da9-a3e9-b899192445c8.svs"
subjectId="TCGA-DU-8164"
caseId="TCGA-DU-8164-01Z-00-DX1"
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


echo "Enter image file from prompt(y/n)?"
read image_file_from_prompt

if [[ "$image_file_from_prompt" = "y" ]];then
  #prompt user to enter image file path and name
  echo "please enter your image file path: "
  read image_file_path_s
  echo "please enter the image file name: "
  read image_file_s
  echo "your image file you enter is in: "$image_file_path_s/$image_file_s
  cd $image_file_path_s
  cp $image_file_s $image_file_path/$image_file_s
  image_file=$image_file_s
  echo "your image file is moved to: "$image_file_path/$image_file
fi


echo "Enter tile_minx and tile_miny from prompt (y/n)?"
read tile_minxy_from_prompt
if [[ "$tile_minxy_from_prompt" = "y" ]];then
  echo "Please enter tile_minx"
  read tile_minx
  echo "Please enter tile_miny"
  read tile_miny
fi

#assure the file format is svs.
filename=$(basename "$image_file")
extension="${filename##*.}"
if [[ "$extension" != "svs" ]]; then
   echo "image file format must be svs type."
   exit 1;
fi


#find out featuredb docker container exists and is runing
echo "find out featuredb docker container exists and is runing"
runingDBcontainer=$(docker ps --filter="name=$docker_container_featuredb" -q | xargs)
[[ -n $runingDBcontainer ]] && dbDockerContainerRuning=yes

# remove featuredb docker container if it exists but not runing
echo "remove featuredb docker container if it exists but not runing"
matching=$(docker ps -a --filter="name=$docker_container_featuredb" -q | xargs)
if [[ "$dbDockerContainerRuning" = "no" ]]; then
   [[ -n $matching ]] && docker rm $matching
fi

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

# check existing of  mongodb database with  assigned port open. 
dek_port_info=$(nmap -p $dbport localhost | grep $dbport| grep 'open')
if [[ "$dbDockerContainerRuning" = "no" ]]  && [[ -n $db_port_info ]] ; then
  echo "mongo db port $dbport exist, change port number and try again!" && exit 1;
fi


if [[ "$dbDockerContainerRuning" = "no" ]]; then
  #step 1: create container with docker image, mongodb instance with port number and location of data file.
  cd $featuredb_executable_path
  echo "step 1: Create container with docker image ,mongodb instance with port number and location of data file"
  ./run_docker_featuredb.sh start $docker_container_featuredb --dbpath $dbpath --qryport $qryport --dbport $dbport --image $docker_image_featuredb
  echo "------------ after step 1 ------------------ "
else
  echo "---------------- skip step 1 ------------"
fi

#if databse not exist, then create it
current_db_path=$dbpath/$mongodb_name
if [[ ! -d $current_db_path ]]; then
   #step 2:create mongo db
   cd $featuredb_executable_path
   echo "step 2: Create mongo db"
   ./run_docker_featuredb.sh create $docker_container_featuredb $mongodb_name
   echo "----------------  after step 2 -----------------------"
else
  echo "---------------- skip step 2 ------------"
fi


#find out whole slide image metadata is in MongoDB or not,if yes, skip step3
return_str=$(mongo --eval "connect('$dbhost:$dbport/$mongodb_name').images.find({case_id:'$caseId'}).pretty()"| grep case_id)
[[ -n return_str ]] && echo "whole slide image metadata is in MongoDB already, skip step 3" && skip_step_3=yes

if [[ "$skip_step_3" = "no" ]];then
  #step 3: Load whole slide image metadata into MongoDB 
  cd $featuredb_executable_path
  echo "step 3: Load whole slide image metadata into MongoDB"
  ./run_docker_featuredb.sh imgmeta $docker_container_featuredb $mongodb_name  $image_file_path/$image_file --image $cancerType $subjectId $caseId
  echo "---------------------- after step 3 --------------------------"
else
  echo "---------------- skip step 3 ------------"
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


#if output zip file exist, then run step 6.
currentOutputZipFile=$seg_output_path/$seg_output_file
if [[ -f $currentOutputZipFile ]]; then
  #step 6:Load whole slide image featuredb data into MongoDB
  cd $featuredb_executable_path
  echo "step 6: Load whole slide image featuredb data into MongoDB"
  ./run_docker_featuredb.sh loadquip $docker_container_featuredb $mongodb_name $seg_output_path/$seg_output_file csv
  echo "------------  after step 6 ----------------"
else
  echo "---------------- skip step 6 ------------"
fi

# keep the two  containers 
:'
#step 7: kill and remove featuredb Docker instance
cd $featuredb_executable_path
echo "kill and remove featuredb Docker instance"
./run_docker_featuredb.sh remove $docker_container_featuredb
echo "------ after step 7 ----------------"


#step 8: kill and remove analysis Docker instance
cd $segment_executable_path
echo "kill and remove analysis Docker instance"
./run_docker_segment.py remove $docker_container_analysis
echo "------------- after step 8 ------------------"
'




