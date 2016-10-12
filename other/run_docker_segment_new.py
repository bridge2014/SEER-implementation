#! /usr/bin/env python

import sys
import os
import subprocess
import getopt
import random

def print_help():
    print 'run_docker_segment [-h|command <arguments>]'
    print '   Commands: '
    print '     start   - Start a docker instance for segmentation. '
    print '     remove  - Kill and remove docker instance. '
    print '     segment - Run image analysis pipeline. '
    print '   run_docker_segment command for help on command arguments. '

def print_help_start():
    print 'run_docker_segment start <docker name> [<docker image>]'
    print '    <docker name>  - unique name for the docker container instance. '
    print '    The docker container with this <docker name> will be started.  '
    print '    <docker image> - optional name of the docker image to start.   '

def print_help_remove():
    print 'run_docker_segment remove <docker name> ' 
    print '    <docker name> - unique name for the docker container that was '
    print '                    provided with the start command. '
    print '    Running docker container instance will be killed and removed. '

def print_help_segment():
    print 'run_docker_segment segment <docker name> <tissue image file> <output zip file> <segmentation type> <other arguments> '
    print '    <docker name> - the name of the running docker container. '
    print '    <image file>  - input whole tissue image file. '
    print '    <zip file>    - zip file that will store the result files. '
	print '    <segmentation type>    - how to segment the image file, choices are wsi,tiles,onetile and img. '
    print '    Required arguments: for onetile only '
    print '          -s <tile_minx,tile_miny> '
    print '          -b <tile_width,tile_height> '
    print '          -d <patch_width,patch_height> '
    print '          -a <analysis_id: string> '
    print '          -c <case_id: string> '
    print '          -p <subject_id: string> '
    print '    Optional arguments: '
    print '          -r <otsuRatio> '
    print '          -w <curvatureWeight> '
    print '          -l <sizeLowerThld> '
    print '          -u <sizeUpperThld> '
    print '          -k <msKernel> '
    print '          -n <levelsetNumberOfIterations> '
    print '          -m <mpp> '
    print '          -e <analysis desc: string> '
    print '          -v <output level: mask|mask:img|mask:img:overlay> '

def print_helps(argv):
    if (len(argv)==0 or argv[0]=='-h'):
        print_help()
        sys.exit(2);
    command = argv[0]
    if (command=='start' and len(argv)==1):
        print_help_start()
        sys.exit(2);
    if (command=='remove' and len(argv)==1):
        print_help_remove()
        sys.exit(2)
    if (command=='segment' and len(argv)==1):
        print_help_segment()
        sys.exit(2);

def run_start(argv):
    if (len(argv)>1):
        run_cmd = "docker run --name " + argv[0] + " -it -d " + argv[1] + " /bin/bash"
    else:
        run_cmd = "docker run --name " + argv[0] + " -it -d sbubmi/pathomics_nucleus:1.0 /bin/bash"
    print "Starting docker container." 
    subprocess.call(run_cmd,shell=True)
    print "Use docker name: " + argv[0] + " in commands segment and remove."

def run_remove(docker_name):
    run_cmd = "docker kill " + docker_name
    subprocess.call(run_cmd,shell=True)
    run_cmd = "docker rm " + docker_name
    subprocess.call(run_cmd,shell=True)

def run_segment(argv,docker_name,inp_file,zip_file,inp_type):
    try:
        opts, args = getopt.getopt(argv, "s:b:d:a:c:p:r:w:l:u:k:n:m:e:v")
    except getopt.GetoptError:
        print_help_segment()
        sys.exit(2)

    s_option = 0
    b_option = 0
    d_option = 0
    a_option = 0
    c_option = 0
    p_option = 0
    for opt, arg in opts:
        if opt in ("-s"):
            s_option = 1
        if opt in ("-b"):
            b_option = 1
        if opt in ("-d"):
            d_option = 1
        if opt in ("-a"):
            a_option = 1
        if opt in ("-c"):
            c_option = 1
        if opt in ("-p"):
            p_option = 1
    all_option  = s_option&b_option
    all_option &= d_option&a_option
    all_option &= c_option&p_option
    if (inp_type=='onetile' and all_option!=1):
        print_help_segment()
        sys.exit(2)

    inp_file_base = os.path.basename(inp_file)
    zip_file_base = os.path.basename(zip_file)

    print inp_file_base
    print zip_file_base

    print "Copying the input file to docker [",docker_name,"]."
    random.seed()
    rnd_val = random.randrange(1000000)
    tmp_input  = "/tmp/input"  + `rnd_val`
    tmp_output = "/tmp/output"  + `rnd_val`
    tmp_zip    = "/tmp/zip" + `rnd_val`
    run_cmd = "docker exec " + docker_name + " mkdir -p " + tmp_input 
    print run_cmd
    subprocess.call(run_cmd,shell=True)
    run_cmd = "docker exec " + docker_name + " mkdir -p " + tmp_output 
    print run_cmd
    subprocess.call(run_cmd,shell=True)
    run_cmd = "docker exec " + docker_name + " mkdir -p " + tmp_zip 
    print run_cmd
    subprocess.call(run_cmd,shell=True)
    run_cmd = "docker cp " + inp_file + " " + docker_name + ":" + tmp_input + "/."
    print run_cmd
    subprocess.call(run_cmd,shell=True)

    print "Running the analysis pipeline."
	run_cmd = "mainSegmentFeatures"
	run_cmd = run_cmd + " -t " + inp_type
    run_cmd = run_cmd + " -o " + tmp_output
    run_cmd = run_cmd + " -i " + tmp_input + "/" + inp_file_base
    run_cmd = run_cmd + " -z " + tmp_zip   + "/" + zip_file_base
    i = 0
    while (i<len(argv)):
       run_cmd += " "
       run_cmd += argv[i]
       i += 1
    run_cmd = "docker exec " + docker_name + " " + run_cmd
    print run_cmd
    subprocess.call(run_cmd,shell=True)

    print "Copying the zip file to destination folder."
    run_cmd = "docker cp " + docker_name + ":" + tmp_zip + "/" + zip_file_base + " " + zip_file
    print run_cmd
    subprocess.call(run_cmd,shell=True)
    
    print "Cleaning up temp folders in the docker container."
    run_cmd = "docker exec " + docker_name + " rm -rf " + tmp_output  
    print run_cmd
    subprocess.call(run_cmd,shell=True)
    run_cmd = "docker exec " + docker_name + " rm -rf " + tmp_input  
    print run_cmd
    subprocess.call(run_cmd,shell=True)
    run_cmd = "docker exec " + docker_name + " rm -rf " + tmp_zip  
    print run_cmd
    subprocess.call(run_cmd,shell=True)

def main(argv):
    if (len(argv)<2 or argv[0]=='-h'):
        print_helps(argv)

    if (argv[0]=='start'):
        if (len(argv)>=2):
            run_start(argv[1:])
            sys.exit(0)
        else:
            print_help_start()
            sys.exit(2)
    elif (argv[0]=='remove'):
        if (len(argv)==2):
           run_remove(argv[1])
           sys.exit(0)
        else:
            print_help_remove()
            sys.exit(2)
    elif (argv[0]=='segment'):
        if (len(argv)>5):
            run_segment(argv[5:],argv[1],argv[2],argv[3],argv[4])
            sys.exit(0)
        else:
            print_help_segment()
            sys.exit(2)
    else:
        print_helps(argv)
        sys.exit(2)

if __name__ == '__main__':
	main(sys.argv[1:])
