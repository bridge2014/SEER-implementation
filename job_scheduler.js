
// main page to manage the queue
var kue = require('kue') ;
var queue = kue.createQueue();
var shell_script_location =__dirname + "/shellScript";


function execute_job0(image_file,done){
    var subjectId=image_file.slice(0,12);
    var caseId=image_file.slice(0,23);
   var job0 = queue.create('LOADMETADATA2MONGOJOB', {
	  author:'bwang',
	  execute_date:'9_28_2016',
      image_file:image_file,
       subjectId:subjectId,
       caseId:caseId
   }).priority('medium').attempts(3);

  job0
      .on('enqueue',function(){
       //console.log('------ The LOADMETADATA2MONGOJOB is now queued. ------------\n');   
      })
	
	.on('start',function(){
       //console.log('---------------- The LOADMETADATA2MONGOJOB is now running. ---------------\n');   
    })
	
	.on('promotion',function(){
       // console.log('---------------- The LOADMETADATA2MONGOJOB is promoted from delayed status to queued. ---------------\n');
     })
	  
	.on('complete', function(result){
         console.log('----- LOADMETADATA2MONGOJOB completed with data ----- \n', result);
        // execute_job1(image_file,done);
		 done();
     })
	 
     .on('failed attempt', function(errorMessage, doneAttempts){
         console.log('---------- LOADMETADATA2MONGOJOB failed --------\n');
		 done();
     })
	 
	 .on('failed', function(errorMessage){
        console.log('------------ LOADMETADATA2MONGOJOB failed -----------------\n');
		done();
      })
	  
	  .on('progress', function(progress, data){
          console.log('\r  LOADMETADATA2MONGOJOB #' + job0.id + ' ' + progress + '% complete with data ', data );
		  done();
      });


   job0.save( function(err){
       if( !err ){
	       console.log("LOADMETADATA2MONGOJOB id is: "+ job0.id );
           //console.log("how many jobs in queue? "+ queue.testMode.jobs.length );
         }else {console.error(err);}	   
    });
}



function execute_job1(image_file,done){
    var subjectId=image_file.slice(0,12);
    var caseId=image_file.slice(0,23);
   var job1 = queue.create('RUNSEGMENTATIONJOB', {
	  author: 'bwang',
	  execute_date:'9_28_2016',
      image_file:image_file,
       subjectId:subjectId,
       caseId:caseId
   }).priority('medium').attempts(3);

  job1
      .on('enqueue',function(){
       //console.log('------ The RUNSEGMENTATIONJOB is now queued. ------------\n');   
      })
	
	.on('start',function(){
        // console.log('---------------- The RUNSEGMENTATIONJOB is now running. ---------------\n');   
    })
	
	.on('promotion',function(){
        //console.log('---------------- The RUNSEGMENTATIONJOB is promoted from delayed status to queued. ---------------\n');
     })
	  
	.on('complete', function(result){
         console.log('----- RUNSEGMENTATIONJOB completed with data ----- \n', result);
         //execute_job2(image_file,done);
		 done();
     })
	 
     .on('failed attempt', function(errorMessage, doneAttempts){
         console.log('---------- RUNSEGMENTATIONJOB failed --------\n');
		 done();
     })
	 
	 .on('failed', function(errorMessage){
        console.log('------------ RUNSEGMENTATIONJOB failed -----------------\n');
		done();
      })
	  
	  .on('progress', function(progress, data){
          console.log('\r  RUNSEGMENTATIONJOB #' + job1.id + ' ' + progress + '% complete with data ', data );
		  done();
      });


   job1.save( function(err){
       if( !err ){
	       console.log("RUNSEGMENTATIONJOB id is: "+ job1.id );
           //console.log("how many jobs in queue? "+ queue.testMode.jobs.length );
         }else {console.error(err);}	   
    });
}



function execute_job2(done){
	
  var job2 = queue.create('LOADFEATUREDB2MONGOJOB', {
      author: 'bwang',
	  execute_date:'9_28_2016'
  }).priority('medium').attempts(3);
  
  job2.on('enqueue',function(){
   //console.log('------ The LOADFEATUREDB2MONGOJOB is now queued. ------------\n');
   
  }).on('start',function(){
   //console.log('---------------- The LOADFEATUREDB2MONGOJOB is now running. ---------------\n');
   
  }).on('promotion',function(){
   //console.log('------ The LOADFEATUREDB2MONGOJOB is promoted from delayed status to queued.------\n');
   done();

  }).on('complete', function(result){
    console.log('----- LOADFEATUREDB2MONGOJOB completed with data ----- \n', result);
    //done();
      response.end('');
  
  }).on('failed attempt', function(errorMessage, doneAttempts){
    console.log('------ LOADFEATUREDB2MONGOJOB failed ----------\n');
	done();

  }).on('failed', function(errorMessage){
    console.log('---------- LOADFEATUREDB2MONGOJOB failed -----------\n');

  }).on('progress', function(progress, data){
    console.log('\r  LOADFEATUREDB2MONGOJOB #' + job2.id + ' ' + progress + '% complete with data ', data );
    done();
  });
  
  job2.save( function(err){
     if( !err ) {
	  console.log("LOADFEATUREDB2MONGOJOB id is: "+ job2.id );
      //console.log("how many jobs in queue? "+ queue.testMode.jobs.length );	  
     }else {console.error(err);}
  });
}


queue.process('LOADMETADATA2MONGOJOB', function(job, done){
	 /* carry out all the LOADMETADATA2MONGOJOB functions here */
    runJob0(job.data, done);
});

queue.process('RUNSEGMENTATIONJOB', function(job, done){
	 /* carry out all the RUNSEGMENTATIONJOB functions here */
    runJob1(job.data, done);
});

queue.process('LOADFEATUREDB2MONGOJOB', function(job, done){
	/* carry out all the LOADFEATUREDB2MONGOJOB functions here */
    runJob2(job.data, done);
});


function runJob0(data, done){
        //You can use the job's data object to pass your external script parameters
		console.log('author: ' + data.author);
        var image_file = data.image_file;
        var subjectId =data.subjectId;
        var caseId=data.caseId;
        var shell_command=shell_script_location+'/load_metadata_to_MongoDB.sh ' + image_file+' '+subjectId+' '+caseId;
        var exec = require('child_process').exec, child;
        child = exec(shell_command,
            function (error, stdout, stderr) {
                //console.log('stdout: ' + stdout);
                //console.log('stderr: ' +  stderr);
                if (error !== null) {
                    console.log('exec error: ' + error);
                    done(error); //callback with error for your publisher code
                }else{
                    done(null, stdout); // callback with the results, which you can potentially use on your publisher code
                }
            });
}


function runJob1(data, done){
        //You can use the job's data object to pass your external script parameters, such as data.xx
		console.log('author: ' + data.author);
        var image_file = data.image_file;
        var subjectId =data.subjectId;
        var caseId=data.caseId;
        var shell_command=shell_script_location+'/run_segmentation.sh ' + image_file+' '+subjectId+' '+caseId;
        var exec = require('child_process').exec, child;
        child = exec(shell_command,
            function (error, stdout, stderr) {
                //console.log('stdout: ' + stdout);
                //console.log('stderr: ' +  stderr);
                if (error !== null) {
                    console.log('exec error: ' + error);
                    done(error); //callback with error for your publisher code
                }else{
                    done(null, stdout); // callback with the results, which you can potentially use on your publisher code
                }
            });
}


function runJob2(data, done){
        //You can use the job's data object to pass your external script parameters
		console.log('author: ' + data.author);
        var shell_command=shell_script_location+'/load_featuredb_data_to_MongoDB.sh';
        var exec = require('child_process').exec, child;
        child = exec(shell_command,
            function (error, stdout, stderr) {
                //console.log('stdout: ' + stdout);
                //console.log('stderr: ' +  stderr);
                if (error !== null) {
                    console.log('exec error: ' + error);
                    done(error); //callback with error for your publisher code
                }else{
                    done(null, stdout); // callback with the results, which you can potentially use on your publisher code
                }
            });
}

// launch the job scheduler
module.exports = {
    start: function(request, response) {
        var image_file =request.body.image_file;
        console.log("file_name is :"+image_file);

        execute_job0(image_file,function(){});
    }
}



