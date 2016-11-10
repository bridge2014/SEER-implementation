// [feiqiao@tahsin191 ~]$ mongo < ~/script/mongoscript.js

print("define local variables\n");

var host="129.49.249.191";
var port="27015";
var dbname="u24_luad";
var case_id="TCGA-55-7994-01Z-00-DX1";
var subject_id = "TCGA-55-7994";
var merge_execution_id="merge_seq_1";
var user="tester"


//show dbs;
//use u24_luad  
//show collections
//db = connect("localhost:27020/myDatabase");

db = connect(host+":"+ port+"/"+ dbname);

//db.getCollectionNames();

db.createCollection("newcollection");
 
db.newcollection.remove({});

print("get segmentations within irregular annotation ... \n");
//get segmentations within irregular annotation 
db.objects.find({"provenance.image.case_id":case_id,
                    "provenance.image.subject_id":subject_id,
                    "provenance.analysis.execution_id":"humantest",
                    "geometry.type":null
                  }).forEach( function(annotation)
                   {db.objects.aggregate([ { $match: {"provenance.image.case_id":case_id,
                                                      "provenance.image.subject_id":subject_id,
                                                      "provenance.analysis.execution_id":annotation.algorithm,                                                      
                                                      "geometry": {
                                                                   $geoWithin: {
                                                                                $geometry: {
                                                                                            type : "Polygon" ,
                                                                                            coordinates: annotation.geometry.coordinates
                                                                                           }
                                                                               }
                                                                  }                                                       
                                                      } }, { $out: "tmpCollection" } ]);  
                    db.tmpCollection.copyTo("newcollection");                                                       
                   } );  
 
 db.newcollection.find().count();
 
 print("get segmentations within rectangle annotation ... \n");
//get segmentations within rectangle annotation 
db.objects.find({"provenance.image.case_id":case_id,
                    "provenance.image.subject_id":subject_id,
                    "provenance.analysis.execution_id":"humantest",
                    "geometry.type": {$exists : true, $ne : ""}
                  }).forEach( function(annotation)
                   {db.objects.aggregate([ { $match: {"provenance.image.case_id":case_id,
                                                      "provenance.image.subject_id":subject_id,
                                                      "provenance.analysis.execution_id":annotation.algorithm,                                                      
                                                       x : { '$gte':annotation.geometry.coordinates[0][0][0], '$lte':annotation.geometry.coordinates[0][2][0]},
                                                       y : { '$gte':annotation.geometry.coordinates[0][0][1], '$lte':annotation.geometry.coordinates[0][2][1]}                                                    
                                                      } }, { $out: "tmpCollection" } ]);  
                    db.tmpCollection.copyTo("newcollection");                                                       
                   } ); 
 
 print("composite dataset record count:");                                    
db.newcollection.find().count();
  
 print("update execution_id for this new collection:");   
// update execution_id for this new collection
db.newcollection.update({},
                        {$set : {"provenance.analysis.execution_id":merge_execution_id}},
                        {upsert:false, multi:true});
                        
 
print("delete all old composite dataset of segmentations:");  
// delete all merged segmentations
 db.objects.deleteMany({"provenance.image.case_id":case_id,
                         "provenance.image.subject_id":subject_id,
                         "provenance.analysis.execution_id":merge_execution_id                                                     
                       } );

print("insert new dataset from newcollection as array:");  
 //insert from newcollection as array
 db.objects.insert( db.newcollection.find({ },{"_id":0}).toArray() ); 


//print("insert new metadate document of merging dataset to the metadata collection:");
// insert new metadate document of merging dataset to the metadata collection 
var merge_execution_id_records= db.metadata.find({"image.case_id":case_id,"image.subject_id":subject_id,"provenance.analysis_execution_id":merge_execution_id}).count();
		
if(merge_execution_id_records == 0){
 print("insert new metadate document of merging dataset to the metadata collection:");  
   db.metadata.insertOne(
   { 
    "title" : "merge_seq_1", 
     "user":user,
     "provenance" : {
        "analysis_execution_id" : merge_execution_id, 
        "type" : "human"
                   }, 
    "image" : {
        "case_id" : case_id, 
        "subject_id" : subject_id
     }
  });
}	


exit;
	


