#!/bin/bash


# define all local variables

seg_output_path="/home/feiqiao/test/output"
seg_output_file="results.zip"
docker_container_featuredb="mydb1"
mongodb_name="u24_test"
featuredb_executable_path="/home/feiqiao/test/pathomics_featuredb/script"

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
