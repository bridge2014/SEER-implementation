// helper.js
// ========



var formidable = require("formidable"),
    util = require("util");
var AdmZip = require('adm-zip'),
    document;

var fs = require('fs-extra');

var image_file_input_path = "/home/feiqiao/test/input/";
/*
var express = require('express');
var app = express();
var server = require('http').createServer(app);
var io = require('socket.io')(server);
io.on('connection', function (socket) {
    console.log('CONNECTED');
    socket.join('sessionId');
});
*/


module.exports = {
    upload: function(request, response) {
       
        var fields = [];
        var form = new formidable.IncomingForm();
      
        form.on('field', function (field, value) {
            fields[field] = value;
        });

        //Call back when each file in the form is parsed.
        form.on('file', function (name, file) {
            fields[name] = file;
        });

        // Change default upload dir from temp to X.
        form.on('fileBegin', function(name, file) {
            file.path =__dirname + "/upload/" + file.name;
        });

        // Check for upload errors
        form.on("error", function(err) {
            console.error(err);
        });

        //Call back for file upload progress.
        form.on('progress', function (bytesReceived, bytesExpected) {
            //console.log(progress);
            console.log('Progress so far: '+(bytesReceived / bytesExpected * 100).toFixed(0)+"%");
        });

       form.on("end", function(fields, files) {
            var location =__dirname + "/upload/";
            // The file name of the uploaded file
            var file_name = this.openedFiles[0].name;

            console.log("uploaded file name is :"+file_name);
            console.log("uploaded file location is :"+location);
        });

        form.parse(request, function(err, fields, files) {
            var file_name = files.imageFile.name;
            var file_path = files.imageFile.path;
            var file_size = files.imageFile.size;

            console.log("file_name is :"+file_name);
            console.log("file_path is :"+file_path);
            console.log("file_size is :"+file_size);


            // move uploaded file to input folder of image processing component
            var dest_path = image_file_input_path + file_name;

            var duplicate_file = findFile(image_file_input_path, file_name);


            if ( duplicate_file ==0) // no duplicate_file
            {
              fs.move(file_path, dest_path, function (err) {
                if (err)
                    return console.error(err) ;
                else {
                      console.log("your image file has been moved successfully!")
                      //look for uploaded files so far
                      var input_file_list = getFilesSimple(image_file_input_path);

                      response.render('uploadDone',{file_name:file_name,
                                                    file_size:file_size,
                                                    file_list:input_file_list});
                     }
              })
            } else{
                //look for uploaded files so far
                var input_file_list = getFilesSimple(image_file_input_path);

                response.render('uploadDone',{file_name:file_name,
                    file_size:file_size,
                    file_list:input_file_list});
            }

        });

    }
    ,
    selectimage: function(request, response) {
         //look for uploaded files so far
        var input_file_list = getFilesSimple(image_file_input_path);
        response.render('selectImage',{file_list:input_file_list});
    }
    ,
    validate: function(request, response) {
        var image_file =request.body.image_file;
        console.log("file_name is :"+image_file);
        response.render('validateImage',{file_name:image_file});
    }

}; //end of module.exports

//helper functions
function getFiles (dir, files_){
    files_ = files_ || [];
    var files = fs.readdirSync(dir);
    for (var i in files){
        var name = dir + '/' + files[i];
        if (fs.statSync(name).isDirectory()){
            getFiles(name, files_);
        } else {
            files_.push(name);
        }
    }
    return files_;
}


function getFilesSimple (dir, files_){
    files_ = [];
    var files = fs.readdirSync(dir);
    for (var i in files){
        var name = files[i];
            files_.push(name);
    }
    return files_;
}



//helper functions
function findFile (dir, target_file){
    var files = fs.readdirSync(dir);
    for (var i in files){
         var name = files[i];
         if (name === target_file){
            return 1;
          }
    }
    return 0;
}



