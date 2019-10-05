var express=require("express");
var session = require('express-session');
var bodyParser=require('body-parser');
var flash = require('connect-flash');
var app = express();
var dateFormat = require('dateformat');
var json_encode = require('json_encode'); 
 
var connection = require('./../config');


exports.myprofile = function (req, res) { 
    if (req.session.loggedindoctor){	
     var username=req.session.username;
     
     connection.query('SELECT * FROM doctor_info WHERE doctor_id = ?',[username], function (error, results, fields) {
     if (error) {
         req.flash('Error','Error in profile');
         console.log(error);
         res.redirect('/doctor');
     }else{
         
         res.render('pages/doctor/MyProfile_Doctor', { header_title: "Profile Doctor", selected_menu: "MyProfile_doctor", fname:req.session.firstname, doctor: results[0], message: req.flash('loginMessage') });
     }
     }); 	                  
     }else{
         req.flash('Error', 'Cannot access this page');
         res.redirect('/');
     }
             
  };
exports.addprofileimage = function(req, res){    
   if(req.session.loggedindoctor){

      var username=req.session.username;      
 
	  if (!req.files)
		return res.status(400).send('File not found');
 
		var file = req.files.profile_image;
		var img_name=file.name;
 
	  	if(file.mimetype == "image/jpeg" ||file.mimetype == "image/png"||file.mimetype == "image/gif" ){
                                 
              file.mv('public/img/profile_picture/doctor/'+img_name, function(err) {
                             
	              if (err)
                    return res.status(500).send(err);
                          	
                connection.query('UPDATE doctor_info SET img_name = ? WHERE doctor_id = ?',[img_name, username], function(error, results, fields) {
                    if (error) {
                        req.flash('Error','Error in profile');
                        console.log(error);
                        res.redirect('/doctor');
                    }else{
                        connection.query('SELECT * FROM doctor_info WHERE doctor_id = ?',[username], function (error, results, fields) {
                            if (error) {
                                req.flash('Error','Error in profile');
                                console.log(error);
                                res.redirect('/doctor');
                            }else{
                                
                                res.redirect('/MyProfile_doctor');
                                //res.render('pages/doctor/MyProfile', { header_title: "Profile Patient", selected_menu: "MyProfile", fname:req.session.firstname, patient: results[0], message: req.flash('loginMessage') });
                            }
                            }); 
                                                
                    }
                });
	   });
          } else {
            message = "This format is not allowed , please upload file with '.png','.gif','.jpg'";
            req.flash('Error', message);
            res.redirect('/doctor');            
          }
   } else {
        req.flash('Error', 'Cannot access this page');
        res.redirect('/');
   }
 
};
exports.addskinimage = function(req, res){    
    if(req.session.loggedindoctor){
 
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
                        //res.render('pages/doctor/new_diagnose', { header_title: "New Diagnosis", selected_menu: "new_diagnose", fname:req.session.firstname,  message:req.flash('Error'),patient_result: results[0]});                        
                                                 
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

    if (req.session.loggedindoctor){

     var username=req.session.username;
     
        connection.query('SELECT * FROM patient_result ', function (error, results, fields) {
        if (error) {
            req.flash('Error','Error in results');
            console.log(error);
            res.redirect('/doctor');
        }else{
            connection.query('SELECT * FROM patient_info ', function (error, results_patient, fields) {
            if (error) {
                req.flash('Error','Error in results');
                console.log(error);
                res.redirect('/doctor');
            }else{
                
                res.render('pages/doctor/Diagnoses', { header_title: "Patient Diagnoses", selected_menu: "Diagnoses_doctor",fname:req.session.firstname, message:req.flash('Error'), patient_result: results, patient_info: results_patient});
            }
            });            
        }
        }); 	                  
     }else{
         req.flash('Error', 'Cannot access this page');
         res.redirect('/');
     }
            
 };

 
 exports.addmessage =function (req, res) { 

    if (req.session.loggedindoctor){

        var username=req.session.username;
        var today = new Date();  
        var users={                    
            "reciever_id":req.body.reciever_id1, 
            "sender_id":username,       
            "subject":req.body.subject1,
            "message":req.body.message,
            "date":today                    
        }
        connection.query('INSERT INTO messages SET ?',users, function (error, results, fields) {
        if (error) {
            req.flash('Error','Error in results');
            console.log(error);
            res.redirect('/doctor');
        }else{
            connection.query('SELECT * FROM messages WHERE reciever_id = ? ORDER BY date ASC',[username], function (error, results_inbox, fields) {
            if (error) {
                req.flash('Error','Error in profile');
                console.log(error);
                res.redirect('/doctor');
            }else{
                connection.query('SELECT * FROM messages WHERE sender_id = ? ORDER BY date ASC',[username], function (error, results_outbox, fields) {
                    if (error) {
                        req.flash('Error','Error in profile');
                        console.log(error);
                        res.redirect('/doctor');
                    }else{
                        connection.query('SELECT * FROM patient_info', function (error, patient_info, fields) {
                            if (error) {
                                req.flash('Error','Error in profile');
                                console.log(error);
                                res.redirect('/doctor');
                            }else{
                                res.redirect('/messages_doctor');
                                //res.render('pages/doctor/messages_doctor', { header_title: "Messages", selected_menu: "messages_doctor", fname:req.session.firstname, doctor_inbox: results_inbox, doctor_outbox: results_outbox, patient_list:patient_info,  message:req.flash('Error') });
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

    if (req.session.loggedindoctor){

        var username=req.session.username;        
        
        connection.query('SELECT * FROM messages WHERE reciever_id = ? ORDER BY date ASC', [username], function (error, results_inbox, fields) {
        if (error) {
            req.flash('Error','Error in profile');
            console.log(error);
            res.redirect('/doctor');
        }else{
            connection.query('SELECT * FROM messages WHERE sender_id = ? ORDER BY date ASC', [username], function (error, results_outbox, fields) {
                if (error) {
                    req.flash('Error','Error in profile');
                    console.log(error);
                    res.redirect('/doctor');
                }else{
                    connection.query('SELECT * FROM patient_info', function (error, patient_info, fields) {
                    if (error) {
                        req.flash('Error','Error in profile');
                        console.log(error);
                        res.redirect('/doctor');
                    }else{
                        res.render('pages/doctor/messages_doctor', { header_title: "Messages", selected_menu: "messages_doctor", fname:req.session.firstname, doctor_inbox: results_inbox, doctor_outbox: results_outbox, patient_list:patient_info, message:req.flash('Error') });                         
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
 exports.searchcase =function (req, res) { 

    if (req.session.loggedindoctor){

        var username=req.session.username;
        var patientid = req.params.patientid;
        var today = new Date();  
        
        connection.query('SELECT case_id FROM patient_result WHERE patient_id = ?', [patientid], function (error, results, fields) {
        if (error) {
            req.flash('Error','Error in profile');
            console.log(error);            
        }else{
            var myresult = [];
            for(i = 0; i<results.length; i++){
                myresult.push(results[i].case_id)                
            }
            

            res.send(json_encode(myresult));
        }
        }); 	                  
     }else{
         req.flash('Error', 'Cannot access this page');
         res.redirect('/');
     }
            
 };

 exports.addcase =function (req, res) { 

    if (req.session.loggedindoctor){

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

 exports.updateresult =function (req, res) { 

    if (req.session.loggedindoctor){

     var username=req.session.username;
     var result1 = req.body.result0 + ":" + req.body.pred0;
     var result2 = req.body.result1 + ":" + req.body.pred1;
     var result3 = req.body.result2 + ":" + req.body.pred2;
     var caseiid = req.body.caseiid;
     var doc_comment = req.body.doctor_message;
        connection.query('UPDATE patient_result SET result1 = ?, result2 = ?, result3 = ?, doctor_comment = ?, doctor_id = ? WHERE case_id = ?',[result1, result2, result3,doc_comment,username, caseiid], function (error, results, fields) {
        if (error) {
            req.flash('Error','Error in results');
            console.log(error);
            res.redirect('/doctor');
        }else{
            res.redirect('/Diagnoses_doctor');            
        }
        }); 	                  
     }else{
         req.flash('Error', 'Cannot access this page');
         res.redirect('/');
     }
            
 };