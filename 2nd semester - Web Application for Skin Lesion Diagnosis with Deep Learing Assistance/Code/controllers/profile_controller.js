
var express=require("express");
var session = require('express-session');
var bodyParser=require('body-parser');
var flash = require('connect-flash');
var app = express();
var dateFormat = require('dateformat');
var json_encode = require('json_encode'); 
var connection = require('./../config');


exports.myprofile = function (req, res) { 
    if (req.session.loggedinpatient){	
     var username=req.session.username;
     
     connection.query('SELECT * FROM patient_info WHERE patient_id = ?',[username], function (error, results, fields) {
     if (error) {
         req.flash('Error','Error in profile');
         console.log(error);
         res.redirect('/patient');
     }else{
         
         res.render('pages/patient/MyProfile', { header_title: "Profile Patient", selected_menu: "MyProfile", fname:req.session.firstname, patient: results[0], message: req.flash('loginMessage') });
     }
     }); 	                  
     }else{
         req.flash('Error', 'Cannot access this page');
         res.redirect('/');
     }
             
  };
exports.addprofileimage = function(req, res){    
   if(req.session.loggedinpatient){

      var username=req.session.username;      
 
	  if (!req.files)
		return res.status(400).send('File not found');
 
		var file = req.files.profile_image;
		var img_name=file.name;
 
	  	if(file.mimetype == "image/jpeg" ||file.mimetype == "image/png"||file.mimetype == "image/gif" ){
                                 
              file.mv('public/img/profile_picture/'+img_name, function(err) {
                             
	              if (err)
                    return res.status(500).send(err);
                          	
                connection.query('UPDATE patient_info SET img_name = ? WHERE patient_id = ?',[img_name, username], function(error, results, fields) {
                    if (error) {
                        req.flash('Error','Error in profile');
                        console.log(error);
                        res.redirect('/patient');
                    }else{
                        connection.query('SELECT * FROM patient_info WHERE patient_id = ?',[username], function (error, results, fields) {
                            if (error) {
                                req.flash('Error','Error in profile');
                                console.log(error);
                                res.redirect('/patient');
                            }else{
                                res.redirect('/MyProfile');
                                //res.render('pages/patient/MyProfile', { header_title: "Profile Patient", selected_menu: "MyProfile", fname:req.session.firstname, patient: results[0], message: req.flash('loginMessage') });
                            }
                            }); 
                                                
                    }
                });
	   });
          } else {
            message = "This format is not allowed , please upload file with '.png','.gif','.jpg'";
            req.flash('Error', message);
            res.redirect('/patient');            
          }
   } else {
        req.flash('Error', 'Cannot access this page');
        res.redirect('/');
   }
 
};
exports.addskinimage = function(req, res){    
    if(req.session.loggedinpatient){
 
       var username=req.session.username;      
       
       if (!req.files)
         return res.status(400).send('File not found');
  
         var file = req.files.profile_image;
         var img_name=file.name;
  
           if(file.mimetype == "image/jpeg" ||file.mimetype == "image/png"||file.mimetype == "image/gif" ){
                                  
               file.mv('public/img/patient_skin/'+img_name, function(err) {
                              
                   if (err)
                     return res.status(500).send(err);
                var datetime = new Date();     
                var uploaddate = dateFormat(datetime, "yyyy-mm-dd hh:mm:ss");                
                               
                 connection.query('INSERT INTO patient_result (patient_id, upload_date, image) VALUES (?,?,?)',[username, uploaddate, img_name], function(error, results, fields) {
                     if (error) {
                         req.flash('Error','Error while uploading');
                         console.log(error);
                         res.redirect('/patient');
                     }else{
                        req.flash('Success', 'Image Submitted Successfully');
                        res.redirect('/Results');
                        //res.render('pages/patient/new_diagnose', { header_title: "New Diagnosis", selected_menu: "new_diagnose", fname:req.session.firstname,  message:req.flash('Error'),patient_result: results[0]});                        
                                                 
                     }
                 });
        });
           } else {
             message = "This format is not allowed , please upload file with '.png','.gif','.jpg'";
             req.flash('Error', message);
             res.redirect('/patient');            
           }
    } else {
         req.flash('Error', 'Cannot access this page');
         res.redirect('/');
    }
  
 };


exports.myresults =function (req, res) { 

    if (req.session.loggedinpatient){

     var username=req.session.username;
     
        connection.query('SELECT * FROM patient_result WHERE patient_id = ? ORDER BY upload_date ASC',[username], function (error, results, fields) {
        if (error) {
            req.flash('Error','Error in results');
            console.log(error);
            res.redirect('/patient');
        }else{
            
            res.render('pages/patient/Results', { header_title: "Results", selected_menu: "Results", fname:req.session.firstname, message:req.flash('Error'), patient_result: results});
        }
        }); 	                  
     }else{
         req.flash('Error', 'Cannot access this page');
         res.redirect('/');
     }
            
 };

 
 exports.addmessage =function (req, res) { 

    if (req.session.loggedinpatient){

        var username=req.session.username;
        var today = new Date();  
        var users={                    
            "reciever_id":req.body.reciever_id, 
            "sender_id":username,       
            "subject":req.body.subject,
            "message":req.body.message,
            "date":today                    
        }
        connection.query('INSERT INTO messages SET ?',users, function (error, results, fields) {
        if (error) {
            req.flash('Error','Error in results');
            console.log(error);
            res.redirect('/patient');
        }else{
            connection.query('SELECT * FROM messages WHERE reciever_id = ?',[username], function (error, results_inbox, fields) {
            if (error) {
                req.flash('Error','Error in profile');
                console.log(error);
                res.redirect('/patient');
            }else{
                connection.query('SELECT * FROM messages WHERE sender_id = ?',[username], function (error, results_outbox, fields) {
                    if (error) {
                        req.flash('Error','Error in profile');
                        console.log(error);
                        res.redirect('/patient');
                    }else{
                        connection.query('SELECT * FROM doctor_info', function (error, doctor_info, fields) {
                            if (error) {
                                req.flash('Error','Error in profile');
                                console.log(error);
                                res.redirect('/doctor');
                            }else{
                                /* res.redirect(url.format({
                                    pathname:"/",
                                    query:req.query })); */                            
                                res.redirect('/messages_patient');    
                                //res.render('pages/patient/messages_patient', { header_title: "Messages", selected_menu: "Messages", fname:req.session.firstname, patient_inbox: results_inbox, patient_outbox: results_outbox, doctor_list:doctor_info,  message:req.flash('Error') });                                
                            }
                            });                         
                    }
                    });                 
            }
            });             
        }
        }); 	                  
     }else{
         req.flash('Error', 'Cannot access this page');
         res.redirect('/');
     }
            
 };
 exports.viewmessage =function (req, res) { 

    if (req.session.loggedinpatient){

        var username=req.session.username;        
        
        connection.query('SELECT * FROM messages WHERE reciever_id = ?',[username], function (error, results_inbox, fields) {
        if (error) {
            req.flash('Error','Error in profile');
            console.log(error);
            res.redirect('/patient');
        }else{
            connection.query('SELECT * FROM messages WHERE sender_id = ?',[username], function (error, results_outbox, fields) {
                if (error) {
                    req.flash('Error','Error in profile');
                    console.log(error);
                    res.redirect('/patient');
                }else{
                    connection.query('SELECT * FROM doctor_info', function (error, doctor_info, fields) {
                    if (error) {
                        req.flash('Error','Error in profile');
                        console.log(error);
                        res.redirect('/doctor');
                    }else{
                        res.render('pages/patient/messages_patient', { header_title: "Messages", selected_menu: "Messages", fname:req.session.firstname, patient_inbox: results_inbox, patient_outbox: results_outbox, doctor_list:doctor_info,  message:req.flash('Error') });                                
                    }
                    });                     
                }
                });                 
        }
        });             
    
     }else{
         req.flash('Error', 'Cannot access this page');
         res.redirect('/');
     }
            
 };

 //Ajax call
 exports.addcase =function (req, res) { 

    if (req.session.loggedinpatient){

        var username=req.session.username;
        var caseid = req.params.caseid;
        var today = new Date();  
        
        connection.query('SELECT * FROM patient_result WHERE case_id = ?',[caseid], function (error, results, fields) {
        if (error) {
            req.flash('Error','Error in profile');
            console.log(error);            
        }else{
            //console.log(json_encode(results[0]));
            res.send(json_encode(results[0]));
        }
        }); 	                  
     }else{
         req.flash('Error', 'Cannot access this page');
         res.redirect('/');
     }
            
 };

 