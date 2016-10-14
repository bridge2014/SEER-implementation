#!/bin/bash


# define all local variables
source /home/feiqiao/seer_test2/shellScript/seer_config.sh

echo "myhome=$myhome"
echo "image_file_path=$image_file_path"
echo "seg_output_path=$seg_output_path"
echo "seg_output_file=$seg_output_file"
echo "featuredb_executable_path=$featuredb_executable_path"
echo "segment_executable_path=$segment_executable_path"
echo "docker_container_featuredb=$docker_container_featuredb"
echo "docker_container_analysis=$docker_container_analysis"
echo "dbpath=$dbpath"
echo "qryport=$qryport"
echo "dbport=$dbport"
echo "mongodb_name=$mongodb_name"
echo "docker_image_featuredb=$docker_image_featuredb"
echo "docker_image_analysis=$docker_image_analysis"
#exit ;


#image_file="command_history.txt"
#image_file="TCGA-DU-8164-01Z-00-DX1.7a39faea-a8f4-4da9-a3e9-b899192445c8.svs" 
#image_file="TCGA-FG-6692-01Z-00-DX1.719e6a21-c620-46a4-a47e-fb0fccc34cec.svs "
image_file="TCGA-DU-5854-01Z-00-DX1.b4d00993-a322-4d5a-b7a1-06db7ad078ab.svs"
#image_file="TCGA-FG-5964-01Z-00-DX1.971827c7-4e41-4b8c-af02-01b340cf4cbd.svs"


if [[ "${image_file:0:4}" = "TCGA"  ]];then  
  subjectId=${image_file:0:12}
  caseId=${image_file:0:23}
  echo "subjectId=$subjectId"
  echo "caseId=$caseId"
else
  subjectId="TCGA-DU-8164"
  caseId="TCGA-DU-8164-01Z-00-DX1"
fi  

#inp_type="tiles"
#inp_type="img"


inp_type="onetile"
#inp_type="wsi"

cancerType="lgg"

#tile_minx=10000
#tile_miny=10000
#tile_width=512
#tile_height=512
#patch_width=256
#patch_height=256

if [[ "$inp_type"="wsi" ]];then
  tile_minx=0
  tile_miny=0
  tile_width=4096
  tile_height=4096
  patch_width=4096
  patch_height=4096
elif [[ "$inp_type" = "onetile" ]];then
 tile_minx=1000
 tile_miny=1000
 tile_width=512
 tile_height=512
 patch_width=256
 patch_height=256
else
  echo "Please select wsi or onetile method to segment image!"
  exit 1; 
fi



analysis_id="test1"

dbhost="localhost"

skip_step_3="no"
dbDockerContainerRuning="no"
analysisDockerContainerRuning="no"


#echo "Enter image file from prompt(y/n)?"
#read image_file_from_prompt

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


#echo "Enter tile_minx and tile_miny from prompt (y/n)?"
#read tile_minxy_from_prompt

if [[ "$tile_minxy_from_prompt" = "y" ]];then
  echo "Please enter tile_minx"
  read tile_minx
  echo "Please enter tile_miny"
  read tile_miny
fi

#assure the file format is svs.
basename=$(basename "$image_file")
#extension="${basename##*.}"
#if [[ "$extension" != "svs" ]]; then
#   echo "image file format must be svs type."
#   exit 1;
#fi

#find out featuredb docker container exists and is runing
echo "--> find out featuredb docker container exists and is runing"
runingDBcontainer=$(docker ps --filter="name=$docker_container_featuredb" -q | xargs)
[[ -n $runingDBcontainer ]] && dbDockerContainerRuning="yes"

# remove featuredb docker container if it exists but not runing
echo "--> remove featuredb docker container if it exists but not runing"
matching=$(docker ps -a --filter="name=$docker_container_featuredb" -q | xargs)
if [[ "$dbDockerContainerRuning" = "no" ]]; then
   [[ -n $matching ]] && docker rm $matching
fi


# find out analysis  docker container exists and is runing
echo "--> find out analysis  docker container exists and is runing"
matchingStarted=$(docker ps --filter="name=$docker_container_analysis" -q | xargs)
[[ -n $matchingStarted ]] && analysisDockerContainerRuning="yes"

#remove analysis docker container if it exists but not runing
echo "--> remove analysis docker container if it exists but not runing"
matching=$(docker ps -a --filter="name=$docker_container_analysis" -q | xargs)
if [[ "$analysisDockerContainerRuning" = "no" ]]; then
   [[ -n $matching ]] && docker rm $matching
fi

# check existing of  mongodb database with  assigned port open. 
dek_port_info=$(nmap -p $dbport localhost | grep $dbport| grep 'open')
if [[ "$dbDockerContainerRuning" = "no" ]]  && [[ -n $db_port_info ]] ; then
  echo "--> mongo db port $dbport exist, change port number and try again!" && exit 1;
fi

echo "--> step 1: Create container with docker image ,mongodb instance with port number and location of data file"
if [[ "$dbDockerContainerRuning" = "no" ]]; then
  #step 1: create container with docker image, mongodb instance with port number and location of data file.
  cd $featuredb_executable_path 
  ./run_docker_featuredb.sh start $docker_container_featuredb --dbpath $dbpath --qryport $qryport --dbport $dbport --image $docker_image_featuredb
  echo "--> ------------ complete step 1 ------------------ "
else
  echo "--> ------------ skip step 1 ------------"
fi

echo "--> step 2: Create mongo db"
#if databse not exist, then create it
current_db_path=$dbpath/$mongodb_name
if [[ ! -d $current_db_path ]]; then
   #step 2:create mongo db
   cd $featuredb_executable_path  
   ./run_docker_featuredb.sh create $docker_container_featuredb $mongodb_name
   echo "--> --------------- complete step 2 -----------------------"
else
  echo "--> ---------------- skip step 2 ------------"
fi


# validate the image file
echo "--> step 3a: validate the image file"
tempDir="staging"$$"-"$RANDOM
docker exec $docker_container_featuredb mkdir /tmp/$tempDir
docker cp $image_file_path/$image_file $docker_container_featuredb:/tmp/$tempDir/$basename
return_value=$(docker exec -it $docker_container_featuredb run_docker_validate_image_file.sh /tmp/$tempDir $basename)
if [[ $return_value == *"Error"* ]];then
  echo "--> Error: Your image file can NOT be opened by openSlide library!";
  exit 1;
else 
  echo "--> Your image file can be opened by openSlide library!";
fi


#find out whole slide image metadata is in MongoDB or not,if yes, skip step3b
return_str=$(mongo --eval "connect('$dbhost:$dbport/$mongodb_name').images.find({case_id:'$caseId'}).pretty()"| grep case_id)
echo "return_str is :"$return_str
[[ -n $return_str ]] && echo "--> whole slide image metadata is in MongoDB already, skip step 3b" && skip_step_3="yes"

echo "--> step 3b: Load whole slide image metadata into MongoDB"
if [[ "$skip_step_3" = "no" ]];then
  #step 3b: Load whole slide image metadata into MongoDB 
  cd $featuredb_executable_path 
  ./run_docker_featuredb.sh imgmeta $docker_container_featuredb $mongodb_name  $image_file_path/$image_file --image $cancerType $subjectId $caseId
  echo "--> ---------------- complete step 3b --------------------------"
else
  echo "--> ---------------- skip step 3b ------------"
fi


echo "--> step 4: Create image analysis container with docker image"
if [[ "$analysisDockerContainerRuning" = "no" ]]; then
  #step 4:create image analysis container with docker image 
  cd $segment_executable_path 
  ./run_docker_segment_new.py start $docker_container_analysis $docker_image_analysis
  echo "--> ---------- complete step 4 ----------------------------"
else   
  echo "--> ---------- skip step 4 ------------"
fi


#step 5:Run whole slide image segmentation script.
echo "--> step 5:Run whole slide image segmentation script."
cd $segment_executable_path
if [[ "$inp_type" = "onetile" ]];then
   ./run_docker_segment_new.py segment $docker_container_analysis  $image_file_path/$image_file  $seg_output_path/$seg_output_file $inp_type -s $tile_minx,$tile_miny -b $tile_width,$tile_height -d $patch_width,$patch_height -a $analysis_id -c $caseId -p $subjectId
elif [[ "$inp_type" = "wsi" ]];then
  ./run_docker_segment_new.py segment $docker_container_analysis  $image_file_path/$image_file  $seg_output_path/$seg_output_file $inp_type -s $tile_minx,$tile_miny -b $tile_width,$tile_height -d $patch_width,$patch_height -a $analysis_id -c $caseId -p $subjectId
else
  echo "--> Error: You must select one of segmentation methods wsi or onetile!";
  exit 1;
fi
echo "--> --------------  complete step 5 ------------------"


#step 6:Load whole slide image featuredb data into MongoDB
echo "--> step 6:Load whole slide image featuredb data into MongoDB"
#if output zip file exist, then run step 6.
currentOutputZipFile=$seg_output_path/$seg_output_file
if [[ -f $currentOutputZipFile ]]; then
 #validate output zip file includes at least one json,one csv and one png file
 cd $seg_output_path/
 unzip $seg_output_file
 find . -name "*-algmeta.json" -print > json_file.list
 find . -name "*-features.csv" -print > csv_file.list
 find . -name "*-seg.png" -print > png_file.list
 json_file_size=$(du -h json_file.list)
 json_firstletter=${json_file_size:0:1}
 
 csv_file_size=$(du -h csv_file.list)
 csv_firstletter=${csv_file_size:0:1}
 
 png_file_size=$(du -h png_file.list)
 png_firstletter=${png_file_size:0:1}
 
 if [[ $json_firstletter -eq 0 ]]; then
  echo "--> Miss json file from result.zip file."
  exit 1;
 elif [[ $csv_firstletter -eq 0 ]]; then
   echo "--> Miss csv file from result.zip file."
   exit 1;
 elif  [[ $png_firstletter -eq 0 ]]; then
   echo "--> Miss png file from result.zip file."
   exit 1;
 else
   echo "--> The output result.zip file does include json, csv and png files."
 fi  
  
  cd $featuredb_executable_path
   ./run_docker_featuredb.sh loadquip $docker_container_featuredb $mongodb_name $seg_output_path/$seg_output_file csv
  echo "--> ------------  complete step 6 ----------------"
  exit 0;
else
  echo "--> Error: results.zip does NOT exist, skip step 6 ------------"
  exit 1;
fi



