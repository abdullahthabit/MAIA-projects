var mysql      = require('mysql');
var connection = mysql.createConnection({
  host     : 'localhost',
  user     : 'root',
  password : 'root',
  database : 'patientdb'
});
connection.connect(function(err){
if(!err) {
    console.log("Database is connected");
} else {
    throw err;
    //console.log("Error while connecting with database");
}
});
module.exports = connection; 
