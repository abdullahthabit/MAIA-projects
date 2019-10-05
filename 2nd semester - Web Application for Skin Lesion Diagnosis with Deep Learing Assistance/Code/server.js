

var express=require("express");
var session = require('express-session');
var bodyParser=require('body-parser');
var flash = require('connect-flash');
var fileupload = require("express-fileupload");
var connection = require('./config');
var app = express();

var authenticateController=require('./controllers/authenticate_controller');
var registerController=require('./controllers/register_controller');
var patientProfile=require('./controllers/profile_controller');
var doctorProfile=require('./controllers/doctor_controller');

app.use(session({
    cookie: { maxAge: 3600000 }, //session expires after one hour
	secret: 'user_patient',
	resave: true,
	saveUninitialized: true
})); 

/* app.use(function(req, res, next){    
    res.locals.fname = req.session.firstname;
    next();
}); */

app.use(express.static(__dirname + '/public')); //Each file inside this folder will be accessible from the root URL
app.set('view engine', 'ejs');

app.use(fileupload());
app.use(flash());
app.use(bodyParser.urlencoded({extended:true}));
app.use(bodyParser.json());

//Get routes
app.get('/', function (req, res) {  

  delete req.session.loggedinpatient; 
  delete req.session.username;
  delete req.session.loggedindoctor; 
  delete req.session.firstname;
  res.render('pages/index', { header_title: "Home - Online Skin Lesion Diagnosis", selected_menu: "Index", message: req.flash('Error') });       

     
});  
//Add new routes like this
app.get('/about', function (req, res) { 
    delete req.session.loggedinpatient; 
    delete req.session.loggedindoctor; 
    delete req.session.username;
    delete req.session.firstname;
    res.render('pages/about', { header_title: "About Us - Online Skin Lesion Diagnosis ", selected_menu: "About", message:req.flash('Error') });   
    
 });  


 
 app.get('/login_form', function (req, res) { 
    delete req.session.loggedinpatient; 
    delete req.session.loggedindoctor;
    delete req.session.username;
    delete req.session.firstname;
    res.render('pages/login_form', { header_title: "Login - Online Skin Lesion Diagnosis ", selected_menu: "Login", message:req.flash('Error') });         
    	    
 });

 app.get('/logout', function (req, res) { 
    delete req.session.loggedinpatient; 
    delete req.session.loggedindoctor;
    delete req.session.username;
    delete req.session.firstname;
    req.flash('Success', 'Successfully Logged out');
    res.redirect('/');         
    	    
 });

 app.get('/registration_form', function (req, res) { 
    delete req.session.loggedinpatient; 
    delete req.session.loggedindoctor; 
    delete req.session.username;
    delete req.session.firstname;
    res.render('pages/registration_form', { header_title: "Registration - Online Skin Lesion Diagnosis ", selected_menu: "Registration", message: req.flash('Error') });          
   	       
});

 app.get('/patient', function (req, res) { 
   if (req.session.loggedinpatient){		            
      res.render('pages/patient/patient', { header_title: "Patient Page", selected_menu: "patient", fname:req.session.firstname, message:req.flash('Error') });
	}else{
        req.flash('Error', 'Cannot access this page');
		res.redirect('/');
	}
    	    
 });
 app.get('/doctor', function (req, res) { 
    if (req.session.loggedindoctor){		            
       res.render('pages/doctor/doctor', { header_title: "Doctor Page", selected_menu: "doctor", fname:req.session.firstname, message:req.flash('Error') });
     }else{
         req.flash('Error', 'Cannot access this page');
         res.redirect('/');
     }
             
  });
 // POST routes
 app.post('/user_registeration', registerController.register);
 app.post('/user_authentication', authenticateController.authenticate);

 app.post('/addprofile', patientProfile.addprofileimage);
 app.post('/addskin', patientProfile.addskinimage);
 app.post('/addmessage', patientProfile.addmessage);
 app.post('/patient_result/case/:caseid', patientProfile.addcase);
 
 

 app.post('/addprofile_doctor', doctorProfile.addprofileimage);
 app.post('/addmessage_doctor', doctorProfile.addmessage);
 app.post('/update_patient_result', doctorProfile.updateresult);
 app.post('/patient_doctor/patient/:patientid', doctorProfile.searchcase);
 app.post('/patient_doctor/case/:caseid', doctorProfile.addcase);

 //GET routes
 app.get('/MyProfile', patientProfile.myprofile);
 app.get('/Results', patientProfile.myresults);
 app.get('/messages_patient', patientProfile.viewmessage );

 app.get('/MyProfile_doctor', doctorProfile.myprofile);
 app.get('/Diagnoses_doctor', doctorProfile.myresults);
 app.get('/messages_doctor', doctorProfile.viewmessage);
 
 app.get('/new_diagnose', function (req, res) { 
   if (req.session.loggedinpatient){		            
      res.render('pages/patient/new_diagnose', { header_title: "New Diagnosis", selected_menu: "new_diagnose", fname:req.session.firstname,  message:req.flash('Error') });
	}else{
        req.flash('Error', 'Cannot access this page');
		res.redirect('/');
	}
});


app.get('*', function(req, res){
    res.render('pages/Not_found', { header_title: "Page Not Found"});         
});

//port number
app.listen(8080);
