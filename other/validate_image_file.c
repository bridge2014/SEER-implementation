#define _GNU_SOURCE

#include "openslide.h"
#include "openslide-features.h"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <inttypes.h>
#include <time.h>

int main(int argc, char **argv) {

	if (argc!=2) {
		fprintf(stderr,"Usage: %s <image file> \n",argv[0]);
		exit(1);
	}

	char *inp_file = argv[1];
	
	openslide_t *osr = openslide_open(inp_file); 
 	if (osr==NULL) { 
 		fprintf(stdout,"Error: openslide cannot read file: %s\n",inp_file); 
 		return -1; 
 	 } else 
	    return 1;	
}
