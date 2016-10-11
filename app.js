/*
  this project test the tmplating function with engin nunjucks
  and it works!!!
*/


var express = require('express'),
    bodyParser = require('body-parser'),
    nunjucks = require('nunjucks');   

// Set up express
app = express();
app.set('view engine', 'html');
app.set('views', __dirname + './');
app.use(bodyParser.urlencoded({ extended: true }));
// parse application/json
app.use(bodyParser.json());


/*
 Configure nunjucks to work with express
 Not using consolidate because I'm waiting on better support for template inheritance with
 nunjucks via consolidate. See: https://github.com/tj/consolidate.js/pull/224
*/
var env = nunjucks.configure('views', {
    autoescape: true,
    express: app
});

var nunjucksDate = require('nunjucks-date');
nunjucksDate.setDefaultFormat('MMMM Do YYYY, h:mm:ss a');
env.addFilter("date", nunjucksDate);


var helper = require('./helper');
var job_scheduler = require('./job_scheduler');

// Hardcoded USERID for use with the shopping cart portion
var USERID = "558098a65133816958968d88";  
    
var router = express.Router();

 // Homepage
 router.get("/", function(req, res) {             
        res.render('home', { myname: 'bwang',
                             userid: USERID});
 });

 // upload a image to server
 router.post('/upload', function(req, res) {
 helper.upload(req, res);
 });

// select image downloaded so far
router.get('/selectimage', function(req, res) {
    helper.selectimage(req, res);
});

// validate image file
router.post('/validate', function(req, res) {
    helper.validate(req, res);
});


// start job scheduler
router.get('/job_scheduler', function(req, res) {
    job_scheduler.start(req, res);
});

// Use the router routes in our application
app.use('/', router);

// Start the server listening
var server = app.listen(3008, function() {
    var port = server.address().port;
    console.log('seer_test2 server listening on port %s.', port);
});

    
    

