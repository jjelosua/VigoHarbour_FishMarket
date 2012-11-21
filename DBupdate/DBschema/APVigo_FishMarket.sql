# ************************************************************
# Sequel Pro SQL dump
# Version 3408
#
# http://www.sequelpro.com/
# http://code.google.com/p/sequel-pro/
#
# Host: localhost (MySQL 5.5.25a)
# Database: APVigo_FishMarket
# Generation Time: 2012-11-21 12:20:32 +0000
# ************************************************************


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


# Dump of table DAT_AUCTION
# ------------------------------------------------------------

DROP TABLE IF EXISTS `DAT_AUCTION`;

CREATE TABLE `DAT_AUCTION` (
  `id` int(11) unsigned NOT NULL,
  `date` date NOT NULL,
  `speciesId` int(3) NOT NULL,
  `familyId` int(3) NOT NULL,
  `initialPrice` float NOT NULL,
  `finalPrice` float NOT NULL,
  `amount` float NOT NULL,
  `unitsId` int(3) NOT NULL,
  `marketTypeId` int(3) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table DAT_SHIPS
# ------------------------------------------------------------

DROP TABLE IF EXISTS `DAT_SHIPS`;

CREATE TABLE `DAT_SHIPS` (
  `id` int(11) unsigned NOT NULL,
  `date` date NOT NULL,
  `shipTypeId` int(3) NOT NULL,
  `amount` int(6) NOT NULL DEFAULT '0',
  `marketTypeId` int(3) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table DAT_VOL_FISH
# ------------------------------------------------------------

DROP TABLE IF EXISTS `DAT_VOL_FISH`;

CREATE TABLE `DAT_VOL_FISH` (
  `id` int(11) unsigned NOT NULL,
  `date` date NOT NULL,
  `amount` float NOT NULL DEFAULT '0',
  `unitsId` int(3) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table DAT_VOL_SEAFOOD
# ------------------------------------------------------------

DROP TABLE IF EXISTS `DAT_VOL_SEAFOOD`;

CREATE TABLE `DAT_VOL_SEAFOOD` (
  `id` int(11) unsigned NOT NULL,
  `date` date NOT NULL,
  `amount` float NOT NULL DEFAULT '0',
  `unitsId` int(3) NOT NULL,
  `marketTypeId` int(3) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table DIM_DATES
# ------------------------------------------------------------

DROP TABLE IF EXISTS `DIM_DATES`;

CREATE TABLE `DIM_DATES` (
  `id` int(11) NOT NULL,
  `date` date NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table DIM_FAMILY
# ------------------------------------------------------------

DROP TABLE IF EXISTS `DIM_FAMILY`;

CREATE TABLE `DIM_FAMILY` (
  `id` int(3) unsigned NOT NULL,
  `familyName` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table DIM_MARKETTYPE
# ------------------------------------------------------------

DROP TABLE IF EXISTS `DIM_MARKETTYPE`;

CREATE TABLE `DIM_MARKETTYPE` (
  `id` int(3) unsigned NOT NULL,
  `marketTypeName` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table DIM_SHIPTYPE
# ------------------------------------------------------------

DROP TABLE IF EXISTS `DIM_SHIPTYPE`;

CREATE TABLE `DIM_SHIPTYPE` (
  `id` int(3) unsigned NOT NULL,
  `shipTypeName` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table DIM_SPECIES
# ------------------------------------------------------------

DROP TABLE IF EXISTS `DIM_SPECIES`;

CREATE TABLE `DIM_SPECIES` (
  `id` int(3) unsigned NOT NULL,
  `speciesName` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table DIM_UNITS
# ------------------------------------------------------------

DROP TABLE IF EXISTS `DIM_UNITS`;

CREATE TABLE `DIM_UNITS` (
  `id` int(3) unsigned NOT NULL,
  `unitName` text NOT NULL,
  `equivKg` int(7) unsigned NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;




/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
