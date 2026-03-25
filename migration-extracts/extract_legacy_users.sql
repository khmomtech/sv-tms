-- MySQL dump 10.13  Distrib 8.0.44, for Linux (aarch64)
--
-- Host: localhost    Database: driverapp
-- ------------------------------------------------------
-- Server version	8.0.44

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Dumping data for table `roles`
--

LOCK TABLES `roles` WRITE;
/*!40000 ALTER TABLE `roles` DISABLE KEYS */;
INSERT INTO `roles` VALUES (1,'ADMIN',NULL,NULL),(2,'MANAGER',NULL,NULL),(3,'DRIVER',NULL,NULL),(4,'CUSTOMER',NULL,NULL);
/*!40000 ALTER TABLE `roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'admin@example.com','$2a$10$l26Ydk81QZL5lmuATGfMbu69taGyk5G8k6UpmjdarqIARMeD4wCQe','admin',_binary '',_binary '',_binary '',_binary '',NULL),(4,'khetsothea@gmail.com','$2a$10$71psT0GFNGBjncrSq4tenuhDAnpFpFNTgqABA2p/Rt/d7LdXl2j/O','sotheakh',_binary '',_binary '',_binary '',_binary '',1),(5,'sothea@kk.com','$2a$10$7czFqj5XrdiXsU0NHWF3OOcQZFqtA/NG4VbQ0cXFXzscyTg/c/o/.','sothea',_binary '\0',_binary '\0',_binary '\0',_binary '',NULL),(6,'JaneSmith@gmail.com','$2a$10$VvPkUHOfxIoIYte/liokhuxLey2HRfUUdqzqkI6Gk49.BCGwBGunO','janesmith',_binary '',_binary '',_binary '',_binary '',NULL),(7,'SavyCHHAY@gmail.com','$2a$10$TlDLHGX2/7QRKdXCerO.v.UcdkddcMj6.PCCk1Yyc8cqDvhwVBBzq','ysavy',_binary '',_binary '',_binary '',_binary '',NULL),(8,'jjsdkfds@gmial.com','$2a$10$JmmNyeVzuCTlJcJiJSbPFuM6e/noY1fJYccMz4T/FtjssEzcTTuXi','sarahlee',_binary '',_binary '',_binary '',_binary '',NULL),(9,'015427080@gmail.com','$2a$10$BuNJD5y0klzrgRHi2rm9mO8PNTOFn.o3RpEVdj0YadggX.qG0o8Gi','015427080',_binary '',_binary '',_binary '',_binary '',NULL),(10,'0969091472@gmail.com','$2a$10$L8EorFzBg7TCzaIEBfyVMOhLNo6KivJdSPrZOKq3hye4tXmmwtmz.','0969091472',_binary '',_binary '',_binary '',_binary '',NULL),(11,'0717390687@gmail.com','$2a$10$HwG8P4Ri9SyVsoCMHhrUNOOIItDX.o7N6My.avOw5e6W6Ne6jfn8m','0717390687',_binary '',_binary '',_binary '',_binary '',NULL),(12,'0963981929@gmail.com','$2a$10$JEwUBoQKf8zMdftvX7Si1.Jgc.1wIUjaKGy6H9gTa3drq1Kjtvq.2','0963981929',_binary '',_binary '',_binary '',_binary '',NULL),(13,'0965656950@gmail.com','$2a$10$/M4S7nSJzTwqLsg6/GUdHuK0PdXvY3hWil0A03gK2WaUESd0bg4XS','0965656950',_binary '',_binary '',_binary '',_binary '',NULL),(14,'usertest1@gmail.com','$2a$10$PKLFrVpKvBqPDL8i7KR/2eea7ra2EOfzr6p0dB6nxO.jxMkjg6I3i','diver1',_binary '',_binary '',_binary '',_binary '',NULL),(15,'015506866@gmail.com','$2a$10$HbJt4VEXzYqN8sZ6EcBUmumCfjpcJ6/biHt/OdcldPCGaRYGvy4YS','015506866',_binary '',_binary '',_binary '',_binary '',NULL),(16,'093692134@gmail.com','$2a$10$1sweSfn3Ourzgg.AK9Kof.01tEj15c8lkz1lOZkpy1U8B07LYULxe','093692134',_binary '',_binary '',_binary '',_binary '',NULL),(17,'0967366118@gmail.com','$2a$10$Zcbn76gSCqbLhTJZH80AieV8qnpZ/jSKDNWBw5Z3E2uWem3GgG94.','0967366118',_binary '',_binary '',_binary '',_binary '',NULL),(18,'016391410@gmail.com','$2a$10$3U2tRO1c00N8QwltcXT6O.dmAp4VPVrFC/SyAaZLQMlXalJuH0UAO','016391410',_binary '',_binary '',_binary '',_binary '',NULL),(19,'010396399@gmail.com','$2a$10$v14BEBOoTbZpqPL5E51Wn.slgei7Vme4ifamCFiY3GcuolpKJPfl.','010396399',_binary '',_binary '',_binary '',_binary '',NULL),(20,'0962531684@gmail.com','$2a$10$1s7u2vIVovCN2Z70VrHH5e.2vJklGnvfQgHAEwLxYl3/3mOePyetO','0962531684',_binary '',_binary '',_binary '',_binary '',NULL),(21,'0966654986@gmail.com','$2a$10$FqWCrg4aKzP2fH.Y402v9exwsRThP/76b6fGohD7I736IM3YzIDY6','0966654986',_binary '',_binary '',_binary '',_binary '',NULL),(22,'010278799@gmail.com','$2a$10$FnzOvRHdWp..uGVODIIlGeuCf/VVrBgUkwZvp9tYJSlmJ9lER7.92','010278799',_binary '',_binary '',_binary '',_binary '',NULL),(23,'016542889@gmail.com','$2a$10$CQ2Ep30Fc5.C3uyc9dKzCeLufTHUVy6j0PGM4WTKET2uBGoHeNFDi','016542889',_binary '',_binary '',_binary '',_binary '',NULL),(24,'081769896@gmail.com','$2a$10$FTcjOBe6cQySn46RzsAIyeyKariry5ytZGLuwT2yyynGUoCeeiofy','081769896',_binary '',_binary '',_binary '',_binary '',NULL),(25,'0963413365@gmail.com','$2a$10$dwdl7YRPbMWfETXUj22GJ./FwufycYVBj/2QTkL7rrFl9O2GEF3e.','0963413365',_binary '',_binary '',_binary '',_binary '',NULL),(26,'012820305@gmail.com','$2a$10$6a/ajuEZ9b/7FIJ9aJcF7eBC7J6wrtCDrjoZ8K5ye5r2gp.BIxuSu','012820305',_binary '',_binary '',_binary '',_binary '',NULL),(27,'012310519@gmail.com','$2a$10$Q0DY.0f6halbeSc/3YLM9etb.p951tp/n5gaFybREv68/9EZraMQC','012310519',_binary '',_binary '',_binary '',_binary '',NULL),(28,'0975545696@gmail.co','$2a$10$ecodIdHE9PnEhfKrZRRY0.emPoaZphtyeGJgKZ1raIVxaiz2eqU.q','0975545696',_binary '',_binary '',_binary '',_binary '',NULL),(29,'086551171@gmail.com','$2a$10$qYxn5.DGhDPKkY7QLYyWLuAQ41lBIYuMdjg6DIrV2wWWyI1ZfSfo2','086551171',_binary '',_binary '',_binary '',_binary '',NULL),(30,'0966448323@gmail.co','$2a$10$JbbtPxQLfTrlxo12Krg2q.n0nk6rnXoZrJtlGkF5.GZ6MbsZ4zOPm','0966448323',_binary '',_binary '',_binary '',_binary '',NULL),(31,'0965080508@gmail.com','$2a$10$aww3/.sJXXCBysS3SQ2GOuTiRgkojSEZHuW.V0AAvoOQi8svig42O','0965080508',_binary '',_binary '',_binary '',_binary '',NULL),(32,'081210014@gmail.com','$2a$10$ELjJ8YBwaa.0IeXqEr0Geu3ZMMPQZGxJMAQ4VfJzBmpWO1/9c9WCK','081210014',_binary '',_binary '',_binary '',_binary '',NULL),(33,'0962900721@gmail.com','$2a$10$golgu8PU9EfJ1ee44efd7.EbPKSzulWvasspDb/Pv0cU1h4tt5zbi','0962900721',_binary '',_binary '',_binary '',_binary '',NULL),(34,'0972992007@gmail.com','$2a$10$rvrtqFcHFrzB8WtnbLMpBeZ4wsXuhaW/FGLVrwOxYNHl7tF6gRW86','0972992007',_binary '',_binary '',_binary '',_binary '',NULL),(35,'0969914508@gmail.com','$2a$10$yS6qp9flfuHgzK0G3sZTLu90LGKYpCH1ZMc69gOlLqbM6NIavwN2q','0969914508',_binary '',_binary '',_binary '',_binary '',NULL),(36,'0968593750@gmail.com','$2a$10$YRuy1wvP4pCFJ28mKOJnheBjP8M4Xesfd2oh4SYa3wXskSTO3Nilq','0968593750',_binary '',_binary '',_binary '',_binary '',NULL),(37,'010792979@gmail.com','$2a$10$Efn6imoFMtmunpLDAhZTiuEbKd1OJgHzKUM6RygP.6vICDQ8/4b6i','010792979',_binary '',_binary '',_binary '',_binary '',NULL),(38,'081640558@gmail.com','$2a$10$AVhgq/jxkrc9H1JhMeFaweBEHJuA70hsk59fkEnX9cLJSpb.h6xCC','081640558',_binary '',_binary '',_binary '',_binary '',NULL),(39,'077620001@gmail.com','$2a$10$ZPPkUUL99T1KTvQjNoT2/.h/cslWvj.ohCPeOQ.w8G0bNKIx5UlL2','077620001',_binary '',_binary '',_binary '',_binary '',NULL),(40,'0963288807@gmail.com','$2a$10$BYdVee7xpHo7jY/0oMjfw.JM9PwC.0CSmMi4yIPTu6uUIoLfp2OJe','0963288807',_binary '',_binary '',_binary '',_binary '',NULL),(41,'093942601@gmail.com','$2a$10$NH/8xu2dnjwQr48tLOw21O6cC6KGmmLHYlGZc9qdY368HPknPO1u6','093942601',_binary '',_binary '',_binary '',_binary '',NULL),(42,'095934399@gmail.com','$2a$10$5hxOCYqNT4rkYeoc01YxCe7VZLrhV05jug0M/GH.zUHFJPusK.RJW','095934399',_binary '',_binary '',_binary '',_binary '',NULL),(43,'087800165@gmail.com','$2a$10$bEnCytX2eSJKV2NzbOq7E.5AyzvjyatzAMoLgwPzkSYypSCmNbBD2','087800165',_binary '',_binary '',_binary '',_binary '',NULL),(44,'093990193@gmail.com','$2a$10$pMi2eAmaH1bCl/fQRHxs8Op5ubY510yk8oPyK9HPW6GngDk0PlINq','093990193',_binary '',_binary '',_binary '',_binary '',NULL),(45,'070555242@gmail.com','$2a$10$opgDRORcIsL2ptQ3fFXkjOkXzPtMLsAI/Rz8Oxh8.z4mana7NkMAS','070555242',_binary '',_binary '',_binary '',_binary '',NULL),(46,'0162643431@gmail.com','$2a$10$RpkLS4xiVcr/zaNJ2CM88uDeFXfvzMWEYVFDaUPoFhH4Z73O9vXMi','0162643431',_binary '',_binary '',_binary '',_binary '',NULL),(47,'01626434333@gmail.ocm','$2a$10$CNubjfKgVfXLzm1uW2j7N.niR32nTIm80VkLyJ8o.BMnm0GFsJevO','01626434333',_binary '',_binary '',_binary '',_binary '',NULL),(48,'081376173@gmail.com','$2a$10$ATfEC7BQDmO/XGvOTSgDT.onuyRxXy66xHDvw/19xMDw33fG.EnSO','081376173',_binary '',_binary '',_binary '',_binary '',NULL),(49,'086299744@gmail.com','$2a$10$omd..IaglORERjZh49xaYOZzh7tRVDCKKioXZZuilhVdk0sRRI6IG','086299744',_binary '',_binary '',_binary '',_binary '',NULL);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `user_roles`
--

LOCK TABLES `user_roles` WRITE;
/*!40000 ALTER TABLE `user_roles` DISABLE KEYS */;
INSERT INTO `user_roles` VALUES (1,1),(4,3),(5,3),(6,3),(7,3),(8,3),(9,3),(10,3),(11,3),(12,3),(13,3),(14,3),(15,3),(16,3),(17,3),(18,3),(19,3),(20,3),(21,3),(22,3),(23,3),(24,3),(25,3),(26,3),(27,3),(28,3),(29,3),(30,3),(31,3),(32,3),(33,3),(34,3),(35,3),(36,3),(37,3),(38,3),(39,3),(40,3),(41,3),(42,3),(43,3),(44,3),(45,3),(46,3),(47,3),(48,3),(49,3);
/*!40000 ALTER TABLE `user_roles` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-11-09  8:44:10
