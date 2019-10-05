

var express = require("express");
var connection = require('./../config');
var session = require('express-session');
var flash = require('connect-flash');
var dateFormat = require('dateformat');
var app = express();

var Cryptr = require('cryptr');
cryptr = new Cryptr('myKey');




module.exports.register = function(req,res){
  var today = new Date();
  app.use(flash());  
  var encryptedString = cryptr.encrypt(req.body.pass);
    if(req.body.usertype == 'Patient'){
      var users={
        //db columns name, input box name
          "patient_id":req.body.username,
          "fname":req.body.fname,
          "lname":req.body.lname,        
          "gender":req.body.gender,
          "nationality":req.body.Nationality,        
          "birthday":dateFormat(req.body.bday, "yyyy-mm-dd"),
          "password":encryptedString
                  
      }
      connection.query('INSERT INTO patient_info SET ?',users, function (error, results, fields) {
        if (error) {
          req.flash('Error','Registration not successful');
          console.log(error);
          res.redirect('/');
        }else{          
          req.flash('Success','Registration is successful');
          req.session.loggedinpatient = true;
          req.session.firstname = req.body.fname;
          req.session.username = req.body.username;
          res.redirect('/patient');          
        }
        res.end();
      });
    }else{
      var users={
        //db columns name, input box name
          "doctor_id":req.body.username,
          "fname":req.body.fname,
          "lname":req.body.lname,        
          "gender":req.body.gender,
          "nationality":req.body.Nationality,        
          "birthday":dateFormat(req.body.bday, "yyyy-mm-dd"), 
          "password":encryptedString
                  
      }
        connection.query('INSERT INTO doctor_info SET ?',users, function (error, results, fields) {
          if (error) {
            req.flash('Error','Registration not successful');
            console.log(error);
            res.redirect('/');
          }else{
            req.flash('Success','Registration is successful');
            req.session.loggedindoctor = true;
            req.session.firstname = req.body.fname;
            req.session.username = req.body.username;
            res.redirect('/doctor');          
          }
          res.end();
        });
    }
    
}