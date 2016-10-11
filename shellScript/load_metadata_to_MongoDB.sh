#!/bin/bash

image_file=$1;
subjectId=$2;
caseId=$3;
cancer_type=$4;

if [[ "$image_file" != "" ]]; then
  echo "image file is provided by user!"
else
   echo "image file is required!"
   image_file="TCGA-DU-8164-01Z-00-DX1.7a39faea-a8f4-4da9-a3e9-b899192445c8.svs"
   subjectId="TCGA-DU-8164"
   caseId="TCGA-DU-8164-01Z-00-DX1"
   cancerType="lgg"
fi


# define all local variables

image_file_path="/home/feiqiao/test/input"
seg_output_path="/home/feiqiao/test/output"
#image_file="TCGA-DU-8164-01Z-00-DX1.7a39faea-a8f4-4da9-a3e9-b899192445c8.svs"
seg_output_file="results.zip"
featuredb_executable_path="/home/feiqiao/test/pathomics_featuredb/script"
segment_executable_path="/home/feiqiao/test/pathomics_analysis/nucleusSegmentation/script"
#subjectId="TCGA-DU-8164"
#caseId="TCGA-DU-8164-01Z-00-DX1"
#cancerType="lgg"
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
ship_step_3="no"
dbhost="localhost"
dbDockerContainerRuning=no
analysisDockerContainerRuning=no



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
[[ -n $runingDBcontainer ]] && dbDockerContainerRuning="yes"

# remove featuredb docker container if it exists but not runing
echo "remove featuredb docker container if it exists but not runing"
matching=$(docker ps -a --filter="name=$docker_container_featuredb" -q | xargs)
if [[ "$dbDockerContainerRuning" =  "no" ]]; then
   [[ -n $matching ]] && docker rm $matching
fi

# find out analysis  docker container exists and is runing
echo "find out analysis  docker container exists and is runing"
matchingStarted=$(docker ps --filter="name=$docker_container_analysis" -q | xargs)
[[ -n $matchingStarted ]] && analysisDockerContainerRuning="yes"

#remove analysis docker container if it exists but not runing
echo "remove analysis docker container if it exists but not runing"
matching=$(docker ps -a --filter="name=$docker_container_analysis" -q | xargs)
if [[ "$analysisDockerContainerRuning" =  "no" ]] ; then
   [[ -n $matching ]] && docker rm $matching
fi

# check existing of  mongodb database with  assigned port open. 
dek_port_info=$(nmap -p $dbport localhost | grep $dbport| grep 'open')
if [[ "$dbDockerContainerRuning" = "no" ]]  && [[ -n $db_port_info ]] ; then
  echo "mongo db port $dbport exist, change port number and try again!" && exit 1;
fi


if [[ "$dbDockerContainerRuning" =  "no" ]]; then
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
return_str=$(mongo --eval "connect('$dbhost:$dbport/$mongodb_name').images.find({case_id:'$caseId'}).pretty()"| grep case_id | xargs)
echo "return_value:"$return_str
size=${#return_str}
echo "size is "$size
if [[ $size -gt 0 ]];then 
 echo "whole slide image metadata is in MongoDB already, skip step 3" 
 skip_step_3="yes"
fi
 
#echo "skip_step_3 is "$skip_step_3 

if [[ "$skip_step_3" =  "no" ]];then
  #step 3: Load whole slide image metadata into MongoDB 
  cd $featuredb_executable_path
  echo "step 3: Load whole slide image metadata into MongoDB"
  ./run_docker_featuredb.sh imgmeta $docker_container_featuredb $mongodb_name  $image_file_path/$image_file --image $cancerType $subjectId $caseId
  echo "---------------------- after step 3 --------------------------"
else
  echo "---------------- skip step 3 ------------"
fi


