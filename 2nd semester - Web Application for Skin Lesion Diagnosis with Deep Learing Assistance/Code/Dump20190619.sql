-- MySQL dump 10.13  Distrib 8.0.15, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: patientdb
-- ------------------------------------------------------
-- Server version	8.0.15

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
 SET NAMES utf8 ;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `doctor_info`
--

DROP TABLE IF EXISTS `doctor_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
 SET character_set_client = utf8mb4 ;
CREATE TABLE `doctor_info` (
  `doctor_id` varchar(45) NOT NULL,
  `fname` varchar(45) NOT NULL,
  `lname` varchar(45) NOT NULL,
  `password` varchar(128) NOT NULL,
  `gender` varchar(10) NOT NULL,
  `nationality` varchar(45) NOT NULL,
  `birthday` date NOT NULL,
  `img_name` varchar(45) NOT NULL DEFAULT 'noPhoto.png',
  PRIMARY KEY (`doctor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `doctor_info`
--

LOCK TABLES `doctor_info` WRITE;
/*!40000 ALTER TABLE `doctor_info` DISABLE KEYS */;
INSERT INTO `doctor_info` VALUES ('tewdrosw@gmail.com','Tewodros','Arega','a0be49f89b855b121292e511986d51e5a526320d','Male','FR','1992-10-10','Arega1.jpg');
/*!40000 ALTER TABLE `doctor_info` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `messages`
--

DROP TABLE IF EXISTS `messages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
 SET character_set_client = utf8mb4 ;
CREATE TABLE `messages` (
  `message_id` int(11) NOT NULL AUTO_INCREMENT,
  `reciever_id` varchar(45) NOT NULL,
  `sender_id` varchar(45) NOT NULL,
  `subject` varchar(45) NOT NULL,
  `message` mediumtext NOT NULL,
  `date` date NOT NULL,
  `status` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`message_id`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `messages`
--

LOCK TABLES `messages` WRITE;
/*!40000 ALTER TABLE `messages` DISABLE KEYS */;
INSERT INTO `messages` VALUES (10,'haile@gmail.com','tewdrosw@gmail.com','Hello Patient','Hello there','2019-06-19',NULL),(11,'haile@gmail.com','tewdrosw@gmail.com','Hello Haile','Are you fine?','2019-06-19',NULL);
/*!40000 ALTER TABLE `messages` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `patient_info`
--

DROP TABLE IF EXISTS `patient_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
 SET character_set_client = utf8mb4 ;
CREATE TABLE `patient_info` (
  `patient_id` varchar(45) NOT NULL,
  `fname` varchar(45) NOT NULL,
  `lname` varchar(45) NOT NULL,
  `gender` varchar(10) NOT NULL,
  `nationality` varchar(45) NOT NULL,
  `birthday` date NOT NULL,
  `img_name` varchar(100) NOT NULL DEFAULT 'noPhoto.png',
  `password` varchar(128) NOT NULL,
  PRIMARY KEY (`patient_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `patient_info`
--

LOCK TABLES `patient_info` WRITE;
/*!40000 ALTER TABLE `patient_info` DISABLE KEYS */;
INSERT INTO `patient_info` VALUES ('haile@gmail.com','Haile','Girma','Male','Angola','1984-12-30','noPhoto.png','37cc9dd4c79ec7cf3d9570327417c36fea899627');
/*!40000 ALTER TABLE `patient_info` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `patient_result`
--

DROP TABLE IF EXISTS `patient_result`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
 SET character_set_client = utf8mb4 ;
CREATE TABLE `patient_result` (
  `case_id` int(11) NOT NULL AUTO_INCREMENT,
  `patient_id` varchar(45) NOT NULL,
  `upload_date` date NOT NULL,
  `image` varchar(100) NOT NULL,
  `result1` varchar(45) DEFAULT NULL,
  `result2` varchar(45) DEFAULT NULL,
  `result3` varchar(45) DEFAULT NULL,
  `doctor_comment` mediumtext,
  `doctor_id` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`case_id`),
  KEY `patient_id_idx` (`patient_id`),
  KEY `doctor_id_idx` (`doctor_id`),
  CONSTRAINT `doctor_id` FOREIGN KEY (`doctor_id`) REFERENCES `doctor_info` (`doctor_id`),
  CONSTRAINT `patient_id` FOREIGN KEY (`patient_id`) REFERENCES `patient_info` (`patient_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `patient_result`
--

LOCK TABLES `patient_result` WRITE;
/*!40000 ALTER TABLE `patient_result` DISABLE KEYS */;
INSERT INTO `patient_result` VALUES (16,'haile@gmail.com','2019-06-18','ISIC_0034321.jpg','null','null','null','It looks like you have Melanocytic Nevus.','tewdrosw@gmail.com');
/*!40000 ALTER TABLE `patient_result` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2019-06-19 14:27:03
