#!/bin/bash

tempDir=$1
imgFile=$2

#echo $pwd
#echo $imgFile
#echo $tempDir

cd $tempDir
return_info=$(validate_image_file $imgFile) 
echo $return_info
rm -rf $tempDir



