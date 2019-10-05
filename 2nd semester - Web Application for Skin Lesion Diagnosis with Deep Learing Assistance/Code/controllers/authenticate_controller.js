
var express=require("express");
var session = require('express-session');
var bodyParser=require('body-parser');
var flash = require('connect-flash');
var app = express();
 
var connection = require('./../config');

var Cryptr = require('cryptr');
cryptr = new Cryptr('myKey');


module.exports.authenticate=function(req,res){ 
    app.use(flash());   

    var email=req.body.username;
    var password=req.body.pass;
    var usertype=req.body.usertype;
    if(usertype == "patient"){
        connection.query('SELECT * FROM patient_info WHERE patient_id = ?',[email], function (error, results, fields) {
        if (error) {
            req.flash('Error','Registration not successful');
            console.log(error);
            res.redirect('/login_form');
        }else{
        
          if(results.length >0){

              var decryptedString = cryptr.decrypt(results[0].password);
              if(password==decryptedString){                  
                  req.flash('Success','Registration is successful');
                  req.session.loggedinpatient = true;
                  req.session.firstname = results[0].fname;
                  req.session.username = req.body.username;
                  res.redirect('/patient');
              }else{
                  /* res.json({
                    status:false,
                    message:"Email and password does not match"
                  }); */
                  req.flash('Error','Email and password does not match');                                
                  res.redirect('/login_form');
              }
            
          }
          else{
            /* res.json({
                status:false,    
              message:"Email does not exits"
            }); */
              req.flash('Error','Email does not exits');              
              res.redirect('/login_form');
          }
        }
      });

    }else if(usertype == 'doctor')  {
      connection.query('SELECT * FROM doctor_info WHERE doctor_id = ?',[email], function (error, results, fields) {
        if (error) {
            req.flash('Error','Login not successful');
            console.log(error);
            res.redirect('/login_form');
        }else{
        
          if(results.length >0){
            var decryptedString = cryptr.decrypt(results[0].password);
              if(password==decryptedString){
                  // res.json({
                  //     status:true,
                  //     message:'successfully authenticated'
                  // })
                  req.flash('Success','Registration is successful');
                  req.session.loggedindoctor = true;
                  req.session.username = req.body.username;
                  req.session.firstname = results[0].fname;
                  res.redirect('/doctor');
              }else{
                  /* res.json({
                    status:false,
                    message:"Email and password does not match"
                  }); */
                  req.flash('Error','Email and password does not match');                  
                  res.redirect('/login_form');
              }
            
          }
          else{
            /* res.json({
                status:false,    
              message:"Email does not exits"
            }); */
              req.flash('Error','Email does not exits');              
              res.redirect('/login_form');
          }
        }
      });
    }else{
      req.flash('Error','Please select usertype');      
      res.redirect('/login_form');
    }
      

}