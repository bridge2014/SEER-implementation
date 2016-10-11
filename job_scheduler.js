
// main page to manage the queue
var kue = require('kue') ;
var queue = kue.createQueue();
var shell_script_location =__dirname + "/shellScript";

var dateFormat = require('dateformat');

 

function execute_job0(req,res,done){
     var image_file =req.body.image_file;
     var cancer_type =req.body.cancer_type;
     var subjectId=image_file.slice(0,12);
     var caseId=image_file.slice(0,23);
     var current_time= dateFormat(new Date()); 
    
     var job0 = queue.create('LOADMETADATA2MONGOJOB', {
	    author:'bwang',
	    execute_time:current_time,
      image_file:image_file,
      subjectId:subjectId,
      caseId:caseId,
      cancer_type:cancer_type
   }).priority('medium').attempts(0);

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
         execute_job1(req,res,done);
		     //done();
     })
	 
     .on('failed attempt', function(errorMessage, doneAttempts){
         console.log('---------- LOADMETADATA2MONGOJOB failed --------\n');
	   	  //done();
         res.render('schedulerDone',{message:'LOADMETADATA2MONGOJOB failed.'});
     })
	 
	 .on('failed', function(errorMessage){
        console.log('------------ LOADMETADATA2MONGOJOB failed -----------------\n');
	     //	done();
        res.render('schedulerDone',{message:'LOADMETADATA2MONGOJOB failed.'});
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



function execute_job1(req,res,done){
     var image_file =req.body.image_file;
     var cancer_type =req.body.cancer_type;
     var subjectId=image_file.slice(0,12);
     var caseId=image_file.slice(0,23);
     var current_time= dateFormat(new Date());  
     var job1 = queue.create('RUNSEGMENTATIONJOB', {
	         author: 'bwang',
	         execute_time:current_time,
           image_file:image_file,
           subjectId:subjectId,
           caseId:caseId,
           cancer_type:cancer_type
   }).priority('medium').attempts(0);

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
         execute_job2(req,res,done);
		    // done();
     })
	 
     .on('failed attempt', function(errorMessage, doneAttempts){
         console.log('---------- RUNSEGMENTATIONJOB failed --------\n');
		    // done();
         res.render('schedulerDone',{message:'RUNSEGMENTATIONJOB failed.'});
     })
	 
	 .on('failed', function(errorMessage){
        console.log('------------ RUNSEGMENTATIONJOB failed -----------------\n');
		    //done();
        res.render('schedulerDone',{message:'RUNSEGMENTATIONJOB failed.'});
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



function execute_job2(req,res,done){	
  var current_time= dateFormat(new Date()); 
  var job2 = queue.create('LOADFEATUREDB2MONGOJOB', {
      author: 'bwang',
	    execute_time:current_time
  }).priority('medium').attempts(0);
  
  job2.on('enqueue',function(){
   //console.log('------ The LOADFEATUREDB2MONGOJOB is now queued. ------------\n');
   
  }).on('start',function(){
   //console.log('---------------- The LOADFEATUREDB2MONGOJOB is now running. ---------------\n');
   
  }).on('promotion',function(){
   //console.log('------ The LOADFEATUREDB2MONGOJOB is promoted from delayed status to queued.------\n');
   done();

  }).on('complete', function(result){
    console.log('----- LOADFEATUREDB2MONGOJOB completed with data ----- \n', result);
       // done();     
    res.render('schedulerDone',{message:'LOADFEATUREDB2MONGOJOB is completed.'});    
  
  }).on('failed attempt', function(errorMessage, doneAttempts){
    console.log('------ LOADFEATUREDB2MONGOJOB failed ----------\n');
	   //done();
    res.render('schedulerDone',{message:'LOADFEATUREDB2MONGOJOB failed.'});

  }).on('failed', function(errorMessage){
    console.log('---------- LOADFEATUREDB2MONGOJOB failed -----------\n');
    res.render('schedulerDone',{message:'LOADFEATUREDB2MONGOJOB failed.'});

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
        console.log('execute_time: ' + data.execute_time);
        var image_file = data.image_file;
        var subjectId =data.subjectId;
        var caseId=data.caseId;
        var cancer_type =data.cancer_type;
        var params=image_file+' '+subjectId+' '+caseId+' '+cancer_type;
        var shell_command=shell_script_location+'/load_metadata_to_MongoDB.sh '+params;
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
        console.log('execute_time: ' + data.execute_time);
        var image_file = data.image_file;
        var subjectId =data.subjectId;
        var caseId=data.caseId;
        var cancer_type =data.cancer_type;
        var params=image_file+' '+subjectId+' '+caseId+' '+cancer_type;
        var shell_command=shell_script_location+'/run_segmentation.sh '+params;
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
        console.log('execute_time: ' + data.execute_time);
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
    start: function(req, res) {
       // var image_file =request.body.image_file;
       // console.log("file_name is :"+image_file);
       // var cancer_type =request.body.cancer_type;
        execute_job0(req,res,function(){});
        //response.render('job_scheduler_done',{});              
    }
}



