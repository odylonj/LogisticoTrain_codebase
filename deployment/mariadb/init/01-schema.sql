CREATE DATABASE IF NOT EXISTS `myrames-prod-db`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_ci;

USE `myrames-prod-db`;

CREATE TABLE IF NOT EXISTS `voies` (
  `num_voie` INT(11) NOT NULL,
  `interdite` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`num_voie`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `rames` (
  `num_serie` VARCHAR(12) NOT NULL,
  `type_rame` VARCHAR(50) NOT NULL,
  `voie` INT(11) DEFAULT NULL,
  `conducteur_entrant` VARCHAR(50) NOT NULL,
  PRIMARY KEY (`num_serie`),
  UNIQUE KEY `uq_rames_voie` (`voie`),
  CONSTRAINT `fk_rames_voie`
    FOREIGN KEY (`voie`) REFERENCES `voies` (`num_voie`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `taches` (
  `num_serie` VARCHAR(12) NOT NULL,
  `num_tache` INT(11) NOT NULL,
  `tache` TEXT NOT NULL,
  PRIMARY KEY (`num_serie`, `num_tache`),
  CONSTRAINT `fk_taches_rame`
    FOREIGN KEY (`num_serie`) REFERENCES `rames` (`num_serie`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
