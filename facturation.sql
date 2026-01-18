-- phpMyAdmin SQL Dump
-- version 5.2.1deb3
-- https://www.phpmyadmin.net/
--
-- Hôte : localhost:3306
-- Généré le : dim. 04 jan. 2026 à 15:04
-- Version du serveur : 10.11.13-MariaDB-0ubuntu0.24.04.1
-- Version de PHP : 8.3.6

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de données : `facturation`
--

DELIMITER $$
--
-- Procédures
--
CREATE PROCEDURE `creer_articles_et_categories` () 
    BEGIN
		-- Supprimer les tables si elles existent
		DROP TABLE IF EXISTS article;
		DROP TABLE IF EXISTS categorieArticle;

		-- Création de la table categorieArticle avec code_famille
		CREATE TABLE categorieArticle (
			code_categorie VARCHAR(20) PRIMARY KEY,
			code_famille VARCHAR(20)
		);

		-- Création de la table article avec code_article comme clé primaire
		CREATE TABLE article (
			code_article VARCHAR(20) PRIMARY KEY,
			nom VARCHAR(100),
			prix_achat_ht DECIMAL(12,2),
			prix_vente_ht DECIMAL(12,2),
			taux_tva DECIMAL(5,2),
			description TEXT,
			unite_vente VARCHAR(10),
			article_actif TINYINT(1),
			code_categorie VARCHAR(20),
			FOREIGN KEY (code_categorie) REFERENCES categorieArticle(code_categorie)
		);

		-- Remplir la table categorieArticle avec les catégories uniques et code_famille
		INSERT INTO categorieArticle (code_categorie, code_famille)
		SELECT categorie, MIN(code_famille)
		FROM export_articles
		GROUP BY categorie;


		-- Remplir la table article avec la correspondance des catégories
		INSERT INTO article (code_article, nom, prix_achat_ht, prix_vente_ht, taux_tva, description, unite_vente, article_actif, code_categorie)
		SELECT 
			ea.code_article,
			TRIM(ea.nom),
			REPLACE(ea.prix_achat_ht, ',', '.') + 0,  -- convertir VARCHAR en DECIMAL
			REPLACE(ea.prix_vente_ht, ',', '.') + 0, -- convertir VARCHAR en DECIMAL
			REPLACE(ea.taux_tva, ',', '.') + 0,      -- convertir VARCHAR en DECIMAL
			ea.description,
			ea.unite_vente,
			IF(ea.article_actif='1', 1, 0),
			ea.categorie
		FROM export_articles ea;

	END$$

CREATE PROCEDURE `creer_client_et_adresses` () 
		BEGIN
		-- DROP TABLES SI EXISTE
		DROP TABLE IF EXISTS adresse_facturation;
		DROP TABLE IF EXISTS adresse_livraison;
		DROP TABLE IF EXISTS client;
		

		-- CREATION TABLE client
		CREATE TABLE client (
			code_tiers VARCHAR(8) PRIMARY KEY,
			civilite VARCHAR(12),
			nom VARCHAR(28),
			pourcentage_remise TINYINT(3),
			code_mode_reglement VARCHAR(10),
			notes TEXT,
			code_commercial VARCHAR(7)
		);

		-- CREATION TABLE adresse_facturation
		CREATE TABLE adresse_facturation (
			code_tiers VARCHAR(8),
			civilite VARCHAR(12),
			nom_contact VARCHAR(28),
			prenom_contact VARCHAR(28),
			adresse VARCHAR(33),
			code_postal VARCHAR(5),
			ville VARCHAR(26),
			pays VARCHAR(2),
			telephone_fixe VARCHAR(15),
			telephone_portable VARCHAR(14),
			email VARCHAR(26),
			PRIMARY KEY (code_tiers)
		);

		-- CREATION TABLE adresse_livraison
		CREATE TABLE adresse_livraison (
			code_tiers VARCHAR(8),
			civilite VARCHAR(12),
			nom_contact VARCHAR(28),
			prenom_contact VARCHAR(28),
			adresse VARCHAR(33),
			code_postal VARCHAR(5),
			ville VARCHAR(26),
			pays VARCHAR(2),
			telephone_fixe VARCHAR(15),
			telephone_portable VARCHAR(14),
			email VARCHAR(26),
			PRIMARY KEY (code_tiers)
		);

		-- INSERTION CLIENTS
		INSERT INTO client
		SELECT 
			`Code (tiers)`,
			`Civilité`,
			`Nom`,
			`% remise`,
			`Code mode de rčglement`,
			`Notes en texte brut`,
			`Code commercial/collaborateur`
		FROM export_clients;

		-- INSERTION ADRESSES FACTURATION
		INSERT INTO adresse_facturation
		SELECT 
			`Code (tiers)`,
			`Civilité (contact) (facturation)`,
			`Nom (contact) (facturation)`,
			`Prénom (facturation)`,
			`Adresse 1 (facturation)`,
			`Code postal (facturation)`,
			`Ville (facturation)`,
			`Code Pays (facturation)`,
			`Téléphone fixe (facturation)`,
			`Téléphone portable (facturation)`,
			`E-mail (facturation)`
		FROM export_clients;

		-- INSERTION ADRESSES LIVRAISON
		INSERT INTO adresse_livraison
		SELECT 
			`Code (tiers)`,
			`Civilité (contact) (livraison)`,
			`Nom (contact) (livraison)`,
			`Prénom (livraison)`,
			`Adresse 1 (livraison)`,
			`Code postal (livraison)`,
			`Ville (livraison)`,
			`Code Pays (livraison)`,
			`Téléphone fixe (livraison)`,
			`Téléphone portable (livraison)`,
			`E-mail (livraison)`
		FROM export_clients;

	END$$

CREATE PROCEDURE `creer_devis_et_devisLigne` () 
    BEGIN
    -- 1. NETTOYAGE
	DROP TABLE IF EXISTS devis;
	DROP TABLE IF EXISTS devisLigne;

	-- 2. CREATION TABLE DEVIS (Entête)
	CREATE TABLE devis (
		numero VARCHAR(12) PRIMARY KEY,
		date_devis DATE,
		code_client VARCHAR(8),
		civilite_client VARCHAR(8),
		nom_client VARCHAR(50),
		adresse_facturation VARCHAR(50),
		code_postal_facturation VARCHAR(10),
		ville_facturation VARCHAR(50),
		code_pays_facturation VARCHAR(5),
		adresse_livraison VARCHAR(50),
		code_postal_livraison VARCHAR(10),
		ville_livraison VARCHAR(50),
		code_pays_livraison VARCHAR(5),
		pourcentage_remise DECIMAL(5,2),
		montant_remise DECIMAL(10,2),
		montant_escompte DECIMAL(10,2),
		code_frais_port VARCHAR(10),
		frais_port_ht DECIMAL(10,2),
		taux_tva_port DECIMAL(5,2),
		code_tva_port VARCHAR(36),
		port_non_soumis_escompte TINYINT(1),
		total_brut_ht DECIMAL(10,2),
		total_ttc DECIMAL(10,2),
		notes TEXT,
		code_commercial VARCHAR(10),
		code_mode_payement VARCHAR(10),
		etat_devis TINYINT(1)
	);

	-- 3. CREATION TABLE DEVIS LIGNE (Détail)
	CREATE TABLE devisLigne (
		id_ligne VARCHAR(36) PRIMARY KEY,
		numero_devis VARCHAR(12),
		code_article VARCHAR(8),
		description TEXT,
		quantite DECIMAL(10,2),
		taux_tva DECIMAL(5,2),
		pv_ht DECIMAL(10,2),
		montant_net_ht DECIMAL(10,2)
	);

	-- 4. INSERTION DEVIS (On utilise DISTINCT pour ne pas dupliquer les entêtes)
	INSERT INTO devis (
		numero, 
		date_devis, 
		code_client, 
		civilite_client, 
		nom_client,
		adresse_facturation, -- Correspond à votre CREATE
		code_postal_facturation, 
		ville_facturation, 
		code_pays_facturation,
		adresse_livraison, -- Correspond à votre CREATE
		code_postal_livraison, 
		ville_livraison, 
		code_pays_livraison, 
		pourcentage_remise, 
		montant_remise, 
		montant_escompte, 
		code_frais_port, 
		frais_port_ht, 
		taux_tva_port, 
		code_tva_port, 
		port_non_soumis_escompte,
		total_brut_ht, 
		total_ttc, 
		notes, 
		code_commercial, 
		code_mode_payement, 
		etat_devis
	)
	SELECT DISTINCT
		`Document - Numéro du document`,
		STR_TO_DATE(`Document - Date`, '%d/%m/%Y'), -- Conversion date
		`Document - Code client`,
		`Document - Civilité`,
		`Document - Nom du client`,
		`Document - Adresse 1 (facturation)`, -- On garde juste l'adresse 1
		`Document - Code postal (facturation)`,
		`Document - Ville (facturation)`,
		`Document - Code Pays (facturation)`,
		`Document - Adresse 1 (livraison)`,   -- On garde juste l'adresse 1
		`Document - Code postal (livraison)`,
		`Document - Ville (livraison)`,
		`Document - Code Pays (livraison)`,
		`Document - % remise`,
		REPLACE(`Document - Montant de la remise`, ',', '.'), -- Conversion décimale
		REPLACE(`Document - Montant de l'escompte`, ',', '.'),
		`Document - Code frais de port`,
		`Document - Frais de port HT`,
		REPLACE(`Document - Taux de TVA port`, ',', '.'),
		`Document - Code TVA port`,
		`Document - Port non soumis ą escompte`,
		REPLACE(`Document - Total Brut HT`, ',', '.'),
		REPLACE(`Document - Total TTC`, ',', '.'),
		`Document - Notes`,
		`Document - Code commercial/collaborateur`,
		`Document - Code mode de rčglement`,
		`Document - Etat du devis`
	FROM export_devis;

	-- 5. INSERTION DEVIS LIGNE
	INSERT INTO devisLigne (
		id_ligne, 
		numero_devis, 
		code_article, 
		description,
		quantite, 
		taux_tva, 
		pv_ht, 
		montant_net_ht
	)
	SELECT
		`Ligne - Code ligne de document`,
		`Document - Numéro du document`,
		`Ligne - Code article`,
		`Ligne - Description`,
		`Ligne - Quantité`,
		REPLACE(`Ligne - Taux de TVA`, ',', '.'), -- Conversion décimale
		REPLACE(`Ligne - PV HT`, ',', '.'),       -- Conversion décimale
		REPLACE(`Ligne - Montant Net HT`, ',', '.') -- Conversion décimale
	FROM export_devis
	WHERE `Ligne - Code ligne de document` IS NOT NULL; -- Sécurité pour éviter les lignes vides

	END$$

CREATE PROCEDURE `creer_facture_et_factureLigne` () 
    BEGIN
    -- 1. NETTOYAGE
	DROP TABLE IF EXISTS facture;
	DROP TABLE IF EXISTS factureLigne;

	-- 2. CRÉATION TABLE FACTURE
	CREATE TABLE facture (
		numero_document VARCHAR(12) PRIMARY KEY,
		date_document DATE,
		code_client VARCHAR(8),
		civilite_client VARCHAR(12),
		nom_client VARCHAR(50),
		adresse_facturation VARCHAR(50),
		code_postal_facturation VARCHAR(10),
		ville_facturation VARCHAR(50),
		code_pays_facturation VARCHAR(5),
		adresse_livraison VARCHAR(50),
		code_postal_livraison VARCHAR(10),
		ville_livraison VARCHAR(50),
		code_pays_livraison VARCHAR(5),
		remise_pct DECIMAL(5,2),
		remise_montant DECIMAL(10,2),
		escompte_pct DECIMAL(5,2),
		escompte_montant DECIMAL(10,2),
		frais_port_ht DECIMAL(10,2),
		total_brut_ht DECIMAL(10,2),
		total_ttc DECIMAL(10,2),
		notes TEXT,
		code_commercial VARCHAR(7),
		code_mode_reglement VARCHAR(4),
		validation TINYINT(1) DEFAULT 1
	);

	-- 3. CRÉATION TABLE FACTURE LIGNE
	CREATE TABLE factureligne (
		id_factureLigne INT AUTO_INCREMENT PRIMARY KEY,
		numero_facture VARCHAR(12),
		code_article VARCHAR(8),
		description_article TEXT,
		quantite DECIMAL(10,2),
		taux_tva DECIMAL(5,2),
		prix_ht DECIMAL(10,2),
		total_ligne_ht DECIMAL(10,2),
		FOREIGN KEY (numero_facture) REFERENCES facture(numero_document)
	);

	-- 4. INSERTION FACTURE (Avec sécurité NULLIF pour les vides)
	INSERT INTO facture (
		numero_document, date_document, code_client, civilite_client, nom_client,
		adresse_facturation, code_postal_facturation, ville_facturation, code_pays_facturation,
		adresse_livraison, code_postal_livraison, ville_livraison, code_pays_livraison,
		remise_pct, remise_montant, escompte_pct, escompte_montant,
		frais_port_ht, total_brut_ht, total_ttc, notes, code_commercial, code_mode_reglement
	)
	SELECT DISTINCT
		`Document - Numéro du document`,
		STR_TO_DATE(`Document - Date`, '%d/%m/%Y'),
		`Document - Code client`,
		`Document - Civilité`,
		`Document - Nom du client`,
		`Document - Adresse 1 (facturation)`,
		`Document - Code postal (facturation)`,
		`Document - Ville (facturation)`,
		`Document - Code Pays (facturation)`,
		`Document - Adresse 1 (livraison)`,
		`Document - Code postal (livraison)`,
		`Document - Ville (livraison)`,
		`Document - Code Pays (livraison)`,
		-- C'est ici que l'erreur est corrigée : NULLIF(..., '')
		NULLIF(REPLACE(`Document - % remise`, ',', '.'), ''),
		NULLIF(REPLACE(`Document - Montant de la remise`, ',', '.'), ''),
		NULLIF(REPLACE(`Document - % escompte`, ',', '.'), ''),
		NULLIF(REPLACE(`Document - Montant de l'escompte`, ',', '.'), ''),
		NULLIF(REPLACE(`Document - Frais de port HT`, ',', '.'), ''),
		NULLIF(REPLACE(`Document - Total Brut HT`, ',', '.'), ''),
		NULLIF(REPLACE(`Document - Total TTC`, ',', '.'), ''),
		`Document - Notes`,
		`Document - Code commercial/collaborateur`,
		`Document - Code mode de rčglement`
	FROM export_factures;

	-- 5. INSERTION FACTURE LIGNE (Avec sécurité NULLIF pour les vides)
	INSERT INTO factureligne (
		numero_facture, code_article, description_article,
		quantite, taux_tva, prix_ht, total_ligne_ht
	)
	SELECT
		`Document - Numéro du document`,
		`Ligne - Code article`,
		`Ligne - Description`,
		-- Correction ici aussi pour la quantité et les prix
		NULLIF(REPLACE(`Ligne - Quantité`, ',', '.'), ''),
		NULLIF(REPLACE(`Ligne - Taux de TVA`, ',', '.'), ''),
		NULLIF(REPLACE(`Ligne - PV HT`, ',', '.'), ''),
		NULLIF(REPLACE(`Ligne - Montant Net HT`, ',', '.'), '')
	FROM export_factures
	WHERE `Ligne - Code ligne de document` IS NOT NULL;

	END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `adresse_facturation`
--

CREATE TABLE `adresse_facturation` (
  `code_tiers` varchar(8) NOT NULL,
  `civilite` varchar(12) DEFAULT NULL,
  `nom_contact` varchar(28) DEFAULT NULL,
  `prenom_contact` varchar(28) DEFAULT NULL,
  `adresse` varchar(33) DEFAULT NULL,
  `code_postal` varchar(5) DEFAULT NULL,
  `ville` varchar(26) DEFAULT NULL,
  `pays` varchar(2) DEFAULT NULL,
  `telephone_fixe` varchar(15) DEFAULT NULL,
  `telephone_portable` varchar(14) DEFAULT NULL,
  `email` varchar(26) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `adresse_facturation`
--

INSERT INTO `adresse_facturation` (`code_tiers`, `civilite`, `nom_contact`, `prenom_contact`, `adresse`, `code_postal`, `ville`, `pays`, `telephone_fixe`, `telephone_portable`, `email`) VALUES
('BDM0001', '', '', '', '17 rue Centrale', '1200', 'BELLEGARDE SUR VALSERINE', 'FR', '', '', ''),
('CCL00002', '', '', '', '', '', '', '', '', '', ''),
('CCL00003', '', '', '', '', '', '', 'FR', '', '', ''),
('CCL00004', '', '', '', '28 rue de la Fontaine de l\'Yvette', '91140', 'VILLEBON SUR YVETTE', 'FR', '', '', ''),
('CCL00005', '', '', '', '7 rue Lambert', '91410', 'DOURDAN', 'FR', '', '', ''),
('CCL00006', '', '', '', '159 Boulevard de Créteil', '94100', 'ST MAUR DES FOSSES', 'FR', '', '', ''),
('CL00001', '', '', '', '10 avenue du Général de Gaulle', '75011', 'PARIS 11EME ARRONDISSEMENT', 'FR', '', '', ''),
('CL00002', '', '', '', '11 Avenue du coin du bois', '95000', 'BOISEMONT', 'FR', '', '', ''),
('CL00003', '', '', '', '5 rue Mond', '93000', 'BOBIGNY', 'FR', '', '', ''),
('GOU0001', 'Madame', 'GOUJUS', 'Alexandra', 'avenue des freres lumiere', '78190', 'TRAPPES', 'FR', '', '', 'goujus.alexandra@free.fr'),
('JAR0001', '', '', '', '16 rue de l\'abreuvoir', '78920', 'ECQUEVILLY', 'FR', '', '', ''),
('KAL0001', 'Monsieur', 'KALOU', 'André', '105 Boulevard john kennedy', '91100', 'CORBEIL ESSONNES', 'FR', '01.65.85.74.45', '06.25.78.95.45', ''),
('LAM0001', 'Mademoiselle', 'LAMBERT', 'Stéphanie', '3 IMPASSE DE LA CISERAIE', '91120', 'PALAISEAU', 'FR', '', '', 'lambert.stephanie@free.fr'),
('LEC0001', '', '', '', '49 square Diderot', '91000', 'EVRY', 'FR', '', '', ''),
('LEG0001', '', '', '', '28 Rue de la fontaine de l\'yvette', '91140', 'VILLEBON SUR YVETTE', 'FR', '', '', ''),
('LOR0001', '', '', '', '7 rue lambert', '91410', 'DOURDAN', 'FR', '', '', ''),
('MAR0001', '', '', '', '159 boulevard de creteil', '94100', 'SAINT MAUR DES FOSSES', 'FR', '', '', ''),
('MAR0002', '', '', '', '52 rue pasteur', '94120', 'FONTENAY SOUS BOIS', 'FR', '', '', ''),
('MAR0003', 'Madame', 'MARCHAND', 'Danielle', '40 RUE CARNOT', '94270', 'LE KREMLIN BICETRE', 'FR', '', '', 'marchand.danielle@aol.fr'),
('MAR0004', 'Madame', 'MARTINEAU', 'Laura', '15 rue de l\'yser', '94400', 'VITRY SUR SEINE', 'FR', '', '', 'martineau.laura@aol.fr'),
('MAS0002', '', '', '', '6 rue de travy', '94320', 'THIAIS', 'FR', '', '', ''),
('MET0001', 'Madame', 'METALLIN', 'Elodie', '3 allée charles V', '94300', 'VINCENNES', 'FR', '', '', 'metallin.elodie@alice.fr'),
('MOL0001', 'Monsieur', 'MOLINA', 'Franēois', '43 rue de taverny', '95130', 'FRANCONVILLE LA GARENNE', 'FR', '01  55 66 99 88', '', ''),
('MUL0001', 'Monsieur', 'MULMERSON', ' Ed', '242 avenue jean jaures', '95100', 'ARGENTEUIL', 'FR', '', '', 'mulmerson.ed@free.fr'),
('ORM0001', 'Monsieur', 'ORMONT', 'PAUL', '10 BIS RUE SAINTE HONORINE', '95150', 'TAVERNY', 'FR', '', '', 'ormont.paul@yahoo.fr'),
('PET0001', '', '', '', '178 avenue des Landes', '95000', 'NEUVILLE SUR OISE', 'FR', '', '', ''),
('POR0001', '', '', '', '62 rue de france', '77300', 'FONTAINEBLEAU', 'FR', '', '', ''),
('RIN0001', 'Mademoiselle', 'RINGUAI', 'Nathalie', '37 rue des archives', '75003', 'PARIS 3EME ARRONDISSEMENT', 'FR', '', '', 'ringuai.nathalie@orange.fr'),
('ROQ0001', 'Monsieur', 'ROQUES', 'Jean-Philippe', '23 rue d\'antin', '75002', 'PARIS 2EME ARRONDISSEMENT', 'FR', '', '', 'roques.jp@yahoo.fr'),
('SAN0001', '', '', '', '53 rue de babylone', '75007', 'PARIS 7EME ARRONDISSEMENT', 'FR', '', '', ''),
('STA0001', '', '', '', '21 rue du renard', '75004', 'PARIS 4EME ARRONDISSEMENT', 'FR', '', '', ''),
('TOR0001', '', '', '', '137 BOULEVARD SAINT MICHEL', '75005', 'PARIS 5EME ARRONDISSEMENT', 'FR', '', '', ''),
('TUL0001', '', '', '', '4 RUE ABEL', '75012', 'PARIS 12EME ARRONDISSEMENT', 'FR', '', '', ''),
('VAN0001', '', '', '', '9 RUE PAUL LOUIS COURRIER', '77100', 'MEAUX', 'FR', '', '', ''),
('VOI0001', '', '', '', '17 rue de l\'assomption', '75016', 'PARIS 16EME ARRONDISSEMENT', 'FR', '', '', ''),
('VOI0002', '', '', '', '11 Avenue du coin du bois', '78120', 'Rambouillet', 'FR', '', '', ''),
('VOI0003', '', '', '', '1 Rue de boisse', '95000', 'CERGY', 'FR', '', '', '');

-- --------------------------------------------------------

--
-- Structure de la table `adresse_livraison`
--

CREATE TABLE `adresse_livraison` (
  `code_tiers` varchar(8) NOT NULL,
  `civilite` varchar(12) DEFAULT NULL,
  `nom_contact` varchar(28) DEFAULT NULL,
  `prenom_contact` varchar(28) DEFAULT NULL,
  `adresse` varchar(33) DEFAULT NULL,
  `code_postal` varchar(5) DEFAULT NULL,
  `ville` varchar(26) DEFAULT NULL,
  `pays` varchar(2) DEFAULT NULL,
  `telephone_fixe` varchar(15) DEFAULT NULL,
  `telephone_portable` varchar(14) DEFAULT NULL,
  `email` varchar(26) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `adresse_livraison`
--

INSERT INTO `adresse_livraison` (`code_tiers`, `civilite`, `nom_contact`, `prenom_contact`, `adresse`, `code_postal`, `ville`, `pays`, `telephone_fixe`, `telephone_portable`, `email`) VALUES
('BDM0001', '', '', '', '17 rue Centrale', '1200', 'BELLEGARDE SUR VALSERINE', 'FR', '', '', ''),
('CCL00002', '', '', '', '', '', '', '', '', '', ''),
('CCL00003', '', '', '', '', '', '', 'FR', '', '', ''),
('CCL00004', '', '', '', '28 rue de la Fontaine de l\'Yvette', '91140', 'VILLEBON SUR YVETTE', 'FR', '', '', ''),
('CCL00005', '', '', '', '7 rue Lambert', '91410', 'DOURDAN', 'FR', '', '', ''),
('CCL00006', '', '', '', '159 Boulevard de Créteil', '94100', 'ST MAUR DES FOSSES', 'FR', '', '', ''),
('CL00001', '', '', '', '10 avenue du Général de Gaulle', '75011', 'PARIS 11EME ARRONDISSEMENT', 'FR', '', '', ''),
('CL00002', '', '', '', '11 Avenue du coin du bois', '95000', 'BOISEMONT', 'FR', '', '', ''),
('CL00003', '', '', '', '5 rue Mond', '93000', 'BOBIGNY', 'FR', '', '', ''),
('GOU0001', 'Madame', 'GOUJUS', 'Alexandra', 'avenue des freres lumiere', '78190', 'TRAPPES', 'FR', '', '', 'goujus.alexandra@free.fr'),
('JAR0001', '', '', '', '16 rue de l\'abreuvoir', '78920', 'ECQUEVILLY', 'FR', '', '', ''),
('KAL0001', 'Monsieur', 'KALOU', 'André', '105 Boulevard john kennedy', '91100', 'CORBEIL ESSONNES', 'FR', '01.65.85.74.45', '06.25.78.95.45', ''),
('LAM0001', 'Mademoiselle', 'LAMBERT', 'Stéphanie', '3 IMPASSE DE LA CISERAIE', '91120', 'PALAISEAU', 'FR', '', '', 'lambert.stephanie@free.fr'),
('LEC0001', '', '', '', '49 square Diderot', '91000', 'EVRY', 'FR', '', '', ''),
('LEG0001', '', '', '', '28 Rue de la fontaine de l\'yvette', '91140', 'VILLEBON SUR YVETTE', 'FR', '', '', ''),
('LOR0001', '', '', '', '7 rue lambert', '91410', 'DOURDAN', 'FR', '', '', ''),
('MAR0001', '', '', '', '159 boulevard de creteil', '94100', 'SAINT MAUR DES FOSSES', 'FR', '', '', ''),
('MAR0002', '', '', '', '52 rue pasteur', '94120', 'FONTENAY SOUS BOIS', 'FR', '', '', ''),
('MAR0003', 'Madame', 'MARCHAND', 'Danielle', '40 RUE CARNOT', '94270', 'LE KREMLIN BICETRE', 'FR', '', '', 'marchand.danielle@aol.fr'),
('MAR0004', 'Madame', 'MARTINEAU', 'Laura', '15 rue de l\'yser', '94400', 'VITRY SUR SEINE', 'FR', '', '', 'martineau.laura@aol.fr'),
('MAS0002', '', '', '', '6 rue de travy', '94320', 'THIAIS', 'FR', '', '', ''),
('MET0001', 'Madame', 'METALLIN', 'Elodie', '3 allée charles V', '94300', 'VINCENNES', 'FR', '', '', 'metallin.elodie@alice.fr'),
('MOL0001', 'Monsieur', 'MOLINA', 'Franēois', '43 rue de taverny', '95130', 'FRANCONVILLE LA GARENNE', 'FR', '01  55 66 99 88', '', ''),
('MUL0001', 'Monsieur', 'MULMERSON', ' Ed', '242 avenue jean jaures', '95100', 'ARGENTEUIL', 'FR', '', '', 'mulmerson.ed@free.fr'),
('ORM0001', 'Monsieur', 'ORMONT', 'PAUL', '10 BIS RUE SAINTE HONORINE', '95150', 'TAVERNY', 'FR', '', '', 'ormont.paul@yahoo.fr'),
('PET0001', '', '', '', '178 avenue des Landes', '95000', 'NEUVILLE SUR OISE', 'FR', '', '', ''),
('POR0001', '', '', '', '62 rue de france', '77300', 'FONTAINEBLEAU', 'FR', '', '', ''),
('RIN0001', 'Mademoiselle', 'RINGUAI', 'Nathalie', '37 rue des archives', '75003', 'PARIS 3EME ARRONDISSEMENT', 'FR', '', '', 'ringuai.nathalie@orange.fr'),
('ROQ0001', 'Monsieur', 'ROQUES', 'Jean-Philippe', '23 rue d\'antin', '75002', 'PARIS 2EME ARRONDISSEMENT', 'FR', '', '', 'roques.jp@yahoo.fr'),
('SAN0001', '', '', '', '53 rue de babylone', '75007', 'PARIS 7EME ARRONDISSEMENT', 'FR', '', '', ''),
('STA0001', '', '', '', '21 rue du renard', '75004', 'PARIS 4EME ARRONDISSEMENT', 'FR', '', '', ''),
('TOR0001', '', '', '', '137 BOULEVARD SAINT MICHEL', '75005', 'PARIS 5EME ARRONDISSEMENT', 'FR', '', '', ''),
('TUL0001', '', '', '', '4 RUE ABEL', '75012', 'PARIS 12EME ARRONDISSEMENT', 'FR', '', '', ''),
('VAN0001', '', '', '', '9 RUE PAUL LOUIS COURRIER', '77100', 'MEAUX', 'FR', '', '', ''),
('VOI0001', '', '', '', '17 rue de l\'assomption', '75016', 'PARIS 16EME ARRONDISSEMENT', 'FR', '', '', ''),
('VOI0002', '', '', '', '11 Avenue du coin du bois', '78120', 'Rambouillet', 'FR', '', '', ''),
('VOI0003', '', '', '', '1 Rue de boisse', '95000', 'CERGY', 'FR', '', '', '');

-- --------------------------------------------------------

--
-- Structure de la table `article`
--

CREATE TABLE `article` (
  `code_article` varchar(20) NOT NULL,
  `nom` varchar(100) DEFAULT NULL,
  `prix_achat_ht` decimal(12,2) DEFAULT NULL,
  `prix_vente_ht` decimal(12,2) DEFAULT NULL,
  `taux_tva` decimal(5,2) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `unite_vente` varchar(10) DEFAULT NULL,
  `article_actif` tinyint(1) DEFAULT NULL,
  `code_categorie` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `article`
--

INSERT INTO `article` (`code_article`, `nom`, `prix_achat_ht`, `prix_vente_ht`, `taux_tva`, `description`, `unite_vente`, `article_actif`, `code_categorie`) VALUES
('ACTI0001', 'FIGURINE HYBRIDE', 19.80, 36.77, 20.00, 'FIGURINE HYBRIDE', 'UNIT', 0, 'GARC0001'),
('ACTI0002', 'VOITURE HERO', 9.35, 17.47, 20.00, 'VOITURE HERO', 'UNIT', 0, 'GARC0001'),
('ANIM0001', 'ANIMATEUR/ANIMATRICE', 129.60, 162.00, 20.00, 'ANIMATEUR/ANIMATRICE POUR LA JOURNEE', 'JOUR', 1, 'PRES0001'),
('ANIM0002', 'ASSISTANT/ASSISTANTE', 50.17, 62.71, 20.00, 'ASSISTANT/ASSISTANTE POUR LA JOURNEE', 'JOUR', 1, 'PRES0001'),
('ANIM0003', 'MAGICIEN', 292.64, 365.80, 20.00, 'MAGICIEN POUR LA JOURNEE', 'JOUR', 1, 'PRES0001'),
('ANIM0004', 'PERE NOEL', 167.22, 209.03, 20.00, 'PERE NOEL POUR LA JOURNEE', 'JOUR', 1, 'PRES0001'),
('ANIM0005', 'MASCOTTE', 50.17, 62.71, 20.00, 'MASCOTTE POUR LA JOURNEE', 'JOUR', 1, 'PRES0001'),
('ANIM0006', 'CLOWNS', 250.84, 313.55, 20.00, 'CLOWNS POUR LA JOURNEE', 'JOUR', 1, 'PRES0001'),
('ATEL0001', 'ATELIER CREATION', 25.08, 31.35, 20.00, 'ATELIER CREATION', 'JOUR', 1, 'ANIM0001'),
('ATEL0002', 'ATELIER BRICOLAGE', 25.08, 31.35, 20.00, 'ATELIER BRICOLAGE', 'JOUR', 1, 'ANIM0001'),
('ATEL0003', 'ATELIER CUISINE', 25.08, 31.35, 20.00, 'ATELIER CUISINE', 'JOUR', 1, 'ANIM0001'),
('ATEL0004', 'ATELIER SCULPTURE SUR BALLONS', 25.08, 31.35, 20.00, 'ATELIER SCULPTURE SUR BALLONS', 'JOUR', 1, 'ANIM0001'),
('ATTA0001', 'ATTACHE-TETINE COEURS', 4.84, 9.11, 20.00, 'ATTACHE-TETINE COEURS', 'UNIT', 0, 'BEBE0001'),
('AU0Z0001', 'AU ZOO AVEC HECTOR LIVRE DE 3 A 6 ANS', 4.18, 7.82, 20.00, 'AU ZOO AVEC HECTOR LIVRE DE 3 A 6 ANS', 'UNIT', 0, 'LIVR0001'),
('AVIO0001', 'AVIONS TELECOMMANDES', 29.70, 55.18, 20.00, 'AVIONS TELECOMMANDES', 'UNIT', 0, 'GARC0001'),
('BARB0001', 'SET GLADIATEUR', 7.59, 14.26, 20.00, 'SET GLADIATEUR', 'UNIT', 0, 'FIGU0001'),
('BARB0002', 'COFFRET BOUTIQUE MODE', 12.32, 22.90, 20.00, 'COFFRET BOUTIQUE MODE', 'UNIT', 0, 'FILL0001'),
('BARB0003', 'POUPEE FASHION', 6.82, 12.78, 20.00, 'POUPEE FASHION', 'UNIT', 0, 'FILL0001'),
('BARB0004', 'HABIT ROSE POUPEE', 4.18, 7.82, 20.00, 'HABIT ROSE POUPEE', 'UNIT', 0, 'FILL0001'),
('BARB0005', 'CHEVAL SAUT D\'OBSTACLES + POUPEE', 23.43, 44.05, 20.00, 'CHEVAL SAUT D\'OBSTACLES + POUPEE', 'UNIT', 0, 'FILL0001'),
('BATE0001', 'BATEAU FORCE SPEED', 29.70, 55.18, 20.00, 'BATEAU FORCE SPEED', 'UNIT', 0, 'GARC0001'),
('BATM0001', 'FIGURINE COLLECTOR DEFI', 19.58, 36.33, 20.00, ' FIGURINE COLLECTOR DEFI', 'UNIT', 0, 'GARC0001'),
('BAVO0001', 'BAVOIRS FUNNY', 2.20, 4.13, 20.00, 'BAVOIRS FUNNY', 'UNIT', 0, 'BEBE0001'),
('BLAN0001', 'BLANCHE NEIGE LIVRE DE 3 A 6 ANS', 6.11, 11.50, 20.00, 'BLANCHE NEIGE LIVRE DE 3 A 6 ANS', 'UNIT', 0, 'LIVR0001'),
('BLOC0001', 'BLOC DE MOUSSE A ASSEMBLER', 8.25, 15.54, 20.00, 'BLOC DE MOUSSE A ASSEMBLER', 'UNIT', 0, 'CONS0001'),
('BUS00001', 'BUS SCOLAIRE 30 CM', 12.76, 23.90, 20.00, 'BUS SCOLAIRE 30 CM ', 'UNIT', 0, 'GARC0001'),
('BUZZ0001', 'FIGURINE HEROS', 2.64, 4.96, 20.00, 'FIGURINE HEROS', 'UNIT', 0, 'FIGU0001'),
('CADR0001', 'CADRE PHOTOS', 2.97, 5.50, 20.00, 'CADRE PHOTOS', 'UNIT', 0, 'BEBE0001'),
('CAMI0001', 'CAMIONS REMORQUES', 5.17, 9.66, 20.00, 'CAMIONS REMORQUES', 'UNIT', 0, 'GARC0001'),
('CAMP0001', 'CAMPING CAR AVEC ACCESSOIRES', 17.60, 33.10, 20.00, 'CAMPING CAR AVEC ACCESSOIRES', 'UNIT', 0, 'GARC0001'),
('CANA0001', 'CANARD JAUNE EN PELUCHE', 13.20, 24.75, 20.00, 'CANARD JAUNE EN PELUCHE', 'UNIT', 0, 'PELU0001'),
('CEND0001', 'CENDRILLON LIVRE DE 3 A 6 ANS', 6.82, 12.78, 20.00, 'CENDRILLON LIVRE DE 3 A 6 ANS', 'UNIT', 0, 'LIVR0001'),
('CHAM0001', 'CHAMBRE ENFANTS MODERNE', 247.50, 459.87, 20.00, 'CHAMBRE ENFANTS MODERNE', 'UNIT', 0, 'FILL0001'),
('CHAQ0001', 'CHEQUE CADEAU 100€', 83.61, 104.51, 20.00, 'CHEQUE CADEAU 100€', 'UNIT', 1, 'CHCA0001'),
('CHEQ0001', 'CHEQUE CADEAU 30€', 25.08, 31.35, 20.00, 'CHEQUE CADEAU 30€', 'UNIT', 1, 'CHCA0001'),
('CHEQ0002', 'CHEQUE CADEAU 50€', 41.81, 52.26, 20.00, 'CHEQUE CADEAU 50€', 'UNIT', 1, 'CHCA0001'),
('CHEV0001', 'FIGURINE CHEVALIERS', 2.42, 4.51, 20.00, 'FIGURINE CHEVALIERS', 'UNIT', 0, 'FIGU0001'),
('CHIO0001', 'BEBE TIGRE BLANC', 1.82, 3.41, 20.00, 'BEBE TIGRE BLANC', 'UNIT', 0, 'FIGU0001'),
('CLES0001', 'CLES MUSICALES D\'ACTIVITES', 7.37, 13.75, 20.00, 'CLES MUSICALES D\'ACTIVITES', 'UNIT', 0, 'BEBE0001'),
('CORR0001', 'BEBE PREND SON POUCE', 12.87, 23.90, 20.00, 'BEBE PREND SON POUCE', 'UNIT', 0, 'FILL0001'),
('CORR0002', 'POUPEE BEBE VALENTINE', 12.87, 23.87, 20.00, 'POUPEE BEBE VALENTINE', 'UNIT', 0, 'BEBE0001'),
('CORR0003', 'LANDAU POUSSETTE MARINE', 53.90, 101.16, 20.00, 'LANDAU POUSSETTE MARINE', 'UNIT', 0, 'FILL0001'),
('CORR0004', 'SAC NURSERY FLEURS', 14.30, 26.58, 20.00, 'SAC NURSERY FLEURS', 'UNIT', 0, 'FILL0001'),
('CORV0001', 'C5 MAQUETTE ECHELLE 1:25 180 PIECES', 10.78, 20.23, 20.00, 'C5 MAQUETTE ECHELLE 1:25 180 PIECES', 'UNIT', 0, 'MAQU0001'),
('DECO0001', 'DECOR BALLONS SIMPLES', 41.81, 52.26, 20.00, 'DECOR BALLONS SIMPLES', 'UNIT', 1, 'ANNI0001'),
('DECO0002', 'DECOR BALLONS HELIUM', 125.42, 156.78, 20.00, 'DECOR BALLONS  HELIUM [100 BALLONS)', 'UNIT', 1, 'ANNI0001'),
('DECO0003', 'DECOR DE TABLE A THEME', 50.17, 62.71, 20.00, 'DECOR DE TABLE A THEME', 'UNIT', 1, 'ANNI0001'),
('DECO0004', 'DECOR THEME BABAR', 83.61, 104.51, 20.00, 'DECOR THEME BABAR', 'UNIT', 1, 'ANNI0001'),
('DECO0005', 'DECOR THEME PRINCESSE', 83.61, 104.51, 20.00, 'DECOR THEME PRINCESSE', 'UNIT', 1, 'ANNI0001'),
('DECO0006', 'DECOR THEME FEE', 83.61, 104.51, 20.00, 'DECOR THEME FEE', 'UNIT', 1, 'ANNI0001'),
('DECO0007', 'DECOR THEME PIRATE', 83.61, 104.51, 20.00, 'DECOR THEME PIRATE', 'UNIT', 1, 'ANNI0001'),
('DECO0008', 'DECOR THEME SPIDER MAN', 83.61, 104.51, 20.00, 'DECOR THEME SPIDER MAN', 'UNIT', 1, 'ANNI0001'),
('DEST0001', 'JEUX FAMILIAL ELECTRONIQUE', 26.95, 50.49, 20.00, 'JEUX FAMILIAL ELECTRONIQUE', 'UNIT', 0, 'SOCI0001'),
('DX0L0001', 'CONSOLE DE JEUX PORTABLE', 71.50, 134.19, 20.00, 'CONSOLE DE JEUX PORTABLE', 'UNIT', 0, 'MIXT0001'),
('ENSE0001', 'ENSEMBLE LAVE VAISSELLE', 59.40, 110.36, 20.00, 'ENSEMBLE LAVE VAISSELLE', 'UNIT', 0, 'BOIS0001'),
('ETOI0001', 'ETOILES ET PLANETES LIVRE 9 ANS ET PLUS', 4.40, 8.27, 20.00, 'ETOILES ET PLANETES LIVRE 9 ANS ET PLUS', 'UNIT', 0, 'LIVR0001'),
('FERM0001', 'FERME MUSICALE', 10.78, 20.14, 20.00, 'FERME MUSICALE ', 'UNIT', 0, 'PUZZ0001'),
('FISH0001', 'MAQUETTE HOMO SAPIENS', 5.83, 10.95, 20.00, 'MAQUETTE HOMO SAPIENS', 'UNIT', 0, 'FIGU0001'),
('FOUR0001', 'FOUR A MICRO ONDES', 17.60, 33.10, 20.00, 'FOUR A MICRO ONDES', 'UNIT', 0, 'BOIS0001'),
('GARA0001', 'GARAGE VOITURES', 15.29, 28.50, 20.00, 'GARAGE VOITURES', 'UNIT', 0, 'GARC0001'),
('GIGO0001', 'GIGOTEUSES', 35.20, 66.22, 20.00, 'GIGOTEUSES', 'UNIT', 0, 'BEBE0001'),
('GIRA0001', 'HIPPOPOTAME MALE', 2.86, 5.34, 20.00, 'HIPPOPOTAME MALE', 'UNIT', 0, 'FIGU0001'),
('GOUT0001', 'GOUTER SIMPLE', 6.69, 8.36, 20.00, 'GOUTER SIMPLE <br> Goūter composé d\'une crźpe ou une part de gateau, un bonbon et une boisson froide (soda ou jus de fruit au choix)', 'PERS', 1, 'ANNI0001'),
('GOUT0002', 'GOUTER ELABORE', 8.36, 10.45, 20.00, 'GOUTER ELABORE <br> Goūter composé d\'une crźpe ou une part de gateau, une brochette de bonbons, barbe ą papa et une boisson froide (soda ou jus de fruit au choix)', 'PERS', 1, 'ANNI0001'),
('GOUT0003', 'COCKTAIL PARENTS', 7.53, 9.41, 20.00, 'COCKTAIL PARENTS <br> Cocktail composé de 5 petits fours ou une part de gateau et une boisson froide (soda ou jus de fruit au choix) ou café', 'PERS', 1, 'ANNI0001'),
('GOUT0004', 'GOUTER DE 15H A 18H', 242.47, 303.09, 20.00, 'GOUTER DE 15H 18H POUR 10 ENFANTS', 'UNIT', 1, 'ANNI0001'),
('GOUT0005', 'DEJEUNER DE 11H A 15H', 242.47, 303.09, 20.00, 'DEJEUNER DE 11H A 15H POUR 10 ENFANTS', 'UNIT', 1, 'ANNI0001'),
('GOUT0006', 'BOUM DE 19H A 22H', 359.53, 449.41, 20.00, 'BOUM DE 19H A 22H POUR 15 ENFANTS <br> (Enfants ą partir de 10 ans)', '', 0, 'ANNI0001'),
('GOUT0007', 'GOUTER ENFANTS SUPPLEMENTAIRES', 20.90, 26.13, 20.00, 'GOUTER ENFANTS SUPPLEMENTAIRES', 'PERS', 1, 'ANNI0001'),
('GRAN0001', 'GRAND LIVRE TISSU - ANIMAUX DECORS', 2.97, 5.51, 20.00, 'GRAND LIVRE TISSU - ANIMAUX DECORS', 'UNIT', 0, 'LIVR0001'),
('GRAN0002', 'GRANDE LOCOMOTIVE', 19.25, 35.86, 20.00, 'GRANDE LOCOMOTIVE ', 'UNIT', 0, 'GARC0001'),
('GRAN0003', 'GRANDES DALLES CHIFFRES PUZZLES', 3.91, 7.36, 20.00, 'GRANDES DALLES CHIFFRES PUZZLES', 'UNIT', 0, 'PUZZ0001'),
('GRIL0001', 'GRILLE PAIN', 11.33, 21.15, 20.00, 'GRILLE PAIN', 'UNIT', 0, 'BOIS0001'),
('GRUE0001', 'GRUE VEHICULES DE CHANTIER', 7.37, 13.79, 20.00, 'GRUE VEHICULES DE CHANTIER', 'UNIT', 0, 'GARC0001'),
('HELI0001', 'HELICOPTERES TELECOMMANDES', 12.87, 23.90, 20.00, 'HELICOPTERES TELECOMMANDES', 'UNIT', 0, 'GARC0001'),
('HOCH0001', 'HOCHET CARILLON', 5.94, 11.04, 20.00, 'HOCHET CARILLON', 'UNIT', 0, 'BEBE0001'),
('HOUS0001', 'HOUSSE DE COUETTE VELOURS 100 X 140 + TAIE', 31.79, 59.79, 20.00, 'HOUSSE DE COUETTE VELOURS 100 X 140 + TAIE', 'UNIT', 0, 'BEBE0001'),
('JEU00001', 'JEUX D\'ADRESSE', 3.41, 6.39, 20.00, 'JEUX D\'ADRESSE', 'UNIT', 0, 'EDUC0001'),
('JEU00002', 'JEUX DE PETITS CHEVAUX', 7.37, 13.75, 20.00, 'JEUX DE PETITS CHEVAUX', 'UNIT', 0, 'EDUC0001'),
('JEU00003', 'JEUX DU NAIN JAUNE', 5.17, 9.66, 20.00, 'JEUX DU NAIN JAUNE', 'UNIT', 0, 'EDUC0001'),
('JEUX0001', 'JEUX D\'ECHECS DE VOYAGE', 10.12, 18.86, 20.00, 'JEUX D\'ECHECS DE VOYAGE', 'UNIT', 0, 'EDUC0001'),
('JEUX0002', 'JEUX DE DAMES', 7.59, 14.26, 20.00, 'JEUX DE DAMES', 'UNIT', 0, 'EDUC0001'),
('JEUX0003', 'CLUEDO HUMAIN', 20.90, 26.13, 20.00, 'CLUEDO HUMAIN', 'PERS', 1, 'ANIM0001'),
('JEUX0004', 'JEUX OLYMPIADES', 20.90, 26.13, 20.00, 'JEUX OLYMPIADES', 'PERS', 1, 'ANIM0001'),
('JUNG0001', 'JUNGLE MUSICAL PUZZLES', 10.78, 20.14, 20.00, 'JUNGLE MUSICAL PUZZLES', 'UNIT', 0, 'PUZZ0001'),
('KAYA0001', 'CHAUSSONS 3 A 9 MOIS', 1.72, 3.23, 20.00, 'CHAUSSONS 3 A 9 MOIS', 'UNIT', 0, 'BEBE0001'),
('L0AB0001', 'L\'ABC DU DESSIN LIVRE DE 6 A 9 ANS', 3.41, 6.42, 20.00, 'L\'ABC DU DESSIN LIVRE DE 6 A 9 ANS', 'UNIT', 0, 'LIVR0001'),
('LA0G0001', 'LA GARE ANIMEE LIVRE DE 0 A 3 ANS', 2.48, 4.60, 20.00, 'LA GARE ANIMEE LIVRE DE 0 A 3 ANS', 'UNIT', 0, 'LIVR0001'),
('LA0M0001', 'JEUX DE STRATEGIE', 14.30, 26.58, 20.00, 'JEUX DE STRATEGIE', 'UNIT', 0, 'SOCI0001'),
('LAPI0001', 'LAPIN ROSE A MUSIQUE', 21.78, 40.39, 20.00, 'LAPIN ROSE A MUSIQUE', 'UNIT', 0, 'PELU0001'),
('LE0C0001', 'LE CHEVAL EN BOIS', 26.95, 50.58, 20.00, 'LE CHEVAL EN BOIS', 'UNIT', 0, 'BOIS0001'),
('LE0C0002', 'LE CORPS HUMAIN LIVRE DE 9 ANS ET PLUS', 5.94, 11.03, 20.00, 'LE CORPS HUMAIN LIVRE DE 9 ANS ET PLUS', 'UNIT', 0, 'LIVR0001'),
('LE0C0003', 'LE CHATEAU A CONSTRUIRE', 13.20, 24.78, 20.00, 'LE CHATEAU A CONSTRUIRE', 'UNIT', 0, 'CONS0001'),
('LE0C0004', 'LE CIRQUE A ASSEMBLER', 19.80, 36.74, 20.00, 'LE CIRQUE A ASSEMBLER', 'UNIT', 0, 'CONS0001'),
('LE0F0001', 'LE FAR WEST A ASSEMBLER', 13.20, 24.78, 20.00, 'LE FAR WEST A ASSEMBLER', 'UNIT', 0, 'CONS0001'),
('LEGO0001', 'FIGURINE FERMIER', 4.95, 9.19, 20.00, 'FIGURINE FERMIER', 'UNIT', 0, 'GARC0001'),
('LEGO0002', 'FIGURINE POMPIER', 4.95, 9.19, 20.00, 'FIGURINE POMPIER', 'UNIT', 0, 'GARC0001'),
('LEGO0003', 'FIGURINE SAFARI', 4.95, 9.19, 20.00, 'FIGURINE SAFARI', 'UNIT', 0, 'GARC0001'),
('LION0001', 'LION SAUVAGE EN PELUCHE 23 CM', 9.79, 18.30, 20.00, 'LION SAUVAGE EN PELUCHE 23 CM', 'UNIT', 0, 'PELU0001'),
('LIT00001', 'LIT BEBE', 17.38, 32.19, 20.00, 'LIT BEBE', 'UNIT', 0, 'FILL0001'),
('LOCO0001', 'LOCOMOTIVE VAPEUR SON ET LUMIERE', 19.25, 35.86, 20.00, 'LOCOMOTIVE VAPEUR SON ET LUMIERE', 'UNIT', 0, 'GARC0001'),
('LOLA0001', 'LOLA TAPIS D\'EVEIL', 37.07, 69.89, 20.00, 'LOLA TAPIS D\'EVEIL', 'UNIT', 0, 'BEBE0001'),
('LUMI0001', 'CHAT MUSICAL 19 CM', 6.93, 12.87, 20.00, 'CHAT MUSICAL 19 CM', 'UNIT', 0, 'PELU0001'),
('MA0P0001', 'MA PREMIERE MAISON POUPEE', 25.30, 46.86, 20.00, 'MA PREMIERE MAISON POUPEE', 'UNIT', 0, 'FILL0001'),
('MA0P0002', 'MA PLAGE ANIMEE LIVRE DE 0 A 3 ANS', 2.48, 4.60, 20.00, 'MA PLAGE ANIMEE LIVRE DE 0 A 3 ANS', 'UNIT', 0, 'LIVR0001'),
('MATT0001', 'MON BEBE A CALINER', 17.38, 32.19, 20.00, 'MON BEBE A CALINER', 'UNIT', 0, 'FILL0001'),
('MEMO0001', 'MEMO ANIMAUX', 1.74, 3.22, 20.00, 'MEMO ANIMAUX', 'UNIT', 0, 'EDUC0001'),
('MON00001', 'MON LAPIN EN PELUCHE 36 CM', 17.60, 33.00, 20.00, 'MON LAPIN EN PELUCHE 36 CM', 'UNIT', 0, 'PELU0001'),
('MONO0001', 'JEUX DE RŌLE', 13.20, 24.83, 20.00, 'JEUX DE RŌLE', 'UNIT', 0, 'SOCI0001'),
('MOTO0001', 'MOTOS CASCADES', 11.88, 22.07, 20.00, 'MOTOS CASCADES', 'UNIT', 0, 'GARC0001'),
('MOTO0002', 'MOTO BIG RACER', 73.70, 137.95, 20.00, 'MOTO BIG RACER', 'UNIT', 0, 'GARC0001'),
('MUST0001', 'MUSTANG GT MAQUETTE ECHELLE 1:25 135 PIECES', 10.78, 20.15, 20.00, 'MUSTANG GT MAQUETTE ECHELLE 1:25 135 PIECES', 'UNIT', 0, 'MAQU0001'),
('ORQU0001', 'ORQUE EN PELUCHE', 8.36, 15.54, 20.00, 'ORQUE EN PELUCHE', 'UNIT', 0, 'PELU0001'),
('OURS0001', 'OURS BEIGE 23 CM', 7.81, 14.61, 20.00, 'OURS BEIGE 23 CM ', 'UNIT', 0, 'PELU0001'),
('PACO0001', 'PYJAMA BICOLOR', 3.41, 6.42, 20.00, 'PYJAMA BICOLOR', 'UNIT', 0, 'BEBE0001'),
('PAPI0001', 'PAPIER CADEAU ET ETIQUETTAGE', 1.25, 1.56, 20.00, 'PAPIER CADEAU ET ETIQUETTAGE', 'UNIT', 1, 'PRES0001'),
('PARA0001', 'PARAPLUIE MYRTILLE', 11.00, 20.22, 20.00, 'PARAPLUIE MYRTILLE', 'UNIT', 0, 'FILL0001'),
('PEIG0001', 'PEIGNOIR DE BAINS', 22.00, 41.39, 20.00, 'PEIGNOIR DE BAINS', 'UNIT', 0, 'BEBE0001'),
('PICT0001', 'JEUX DE CARTES', 3.69, 6.91, 20.00, 'JEUX DE CARTES', 'UNIT', 0, 'SOCI0001'),
('PIRA0001', 'BATEAU PIRATE AVEC ACCESSOIRE', 31.90, 59.77, 20.00, 'BATEAU PIRATE AVEC ACCESSOIRE', 'UNIT', 0, 'FIGU0001'),
('POCH0001', 'POCHETTE SURPRISE 3€', 2.51, 3.14, 20.00, 'POCHETTE SURPRISE 3 EUROS PAR ENFANT', 'PERS', 1, 'ANNI0001'),
('POCH0002', 'POCHETTE SURPRISE 6€', 5.02, 6.28, 20.00, 'POCHETTE SURPRISE 6 EUROS PAR ENFANT', 'UNIT', 1, 'ANNI0001'),
('PORS0001', 'VOITURE TELECOMMANDEE', 22.00, 41.38, 20.00, 'VOITURE TELECOMMANDEE', 'UNIT', 0, 'GARC0001'),
('POUP0001', 'POUPEE LILI', 14.85, 27.59, 20.00, 'POUPEE LILI', 'UNIT', 0, 'FILL0001'),
('POUP0002', 'POUPEE STELLA', 12.10, 22.52, 20.00, 'POUPEE STELLA', 'UNIT', 0, 'FILL0001'),
('POWE0001', 'LE BATEAU DE SURCOUF', 38.50, 71.64, 20.00, 'LE BATEAU DE SURCOUF', 'UNIT', 0, 'FIGU0001'),
('PS400001', 'CONSOLE DE JEUX SALON', 137.50, 256.61, 20.00, 'CONSOLE DE JEUX SALON', 'UNIT', 0, 'MIXT0001'),
('PUZZ0001', 'PUZZLE ANIMAL 1000 PIECES', 7.15, 13.34, 20.00, 'PUZZLE ANIMAL 1000 PIECES', 'UNIT', 0, 'PUZZ0001'),
('PUZZ0002', 'PUZZLE THEME ASTROLOGIE 1000 PIECES', 6.93, 12.87, 20.00, 'PUZZLE THEME ASTROLOGIE 1000 PIECES', 'UNIT', 0, 'PUZZ0001'),
('PUZZ0003', 'PUZZLE THEME FANTASTIQUES 2000 PIECES', 13.64, 25.27, 20.00, 'PUZZLE THEME FANTASTIQUES 2000 PIECES', 'UNIT', 0, 'PUZZ0001'),
('PUZZ0004', 'PUZZLE THEME NATURE 1000 PIECES', 7.15, 13.34, 20.00, 'PUZZLE THEME NATURE 1000 PIECES', 'UNIT', 0, 'PUZZ0001'),
('PUZZ0005', 'PUZZLE MAGNETIQUE 60 PIECES', 5.94, 11.04, 20.00, 'PUZZLE MAGNETIQUE 60 PIECES', 'UNIT', 0, 'PUZZ0001'),
('QUEE0001', 'QUEEN MARY MAQUETTE ECHELLE 1:400', 29.70, 55.17, 20.00, 'QUEEN MARY MAQUETTE ECHELLE 1:400', 'UNIT', 0, 'MAQU0001'),
('QUI00001', 'JEUX TELE', 17.71, 33.10, 20.00, 'JEUX TELE', 'UNIT', 0, 'SOCI0001'),
('REFR0001', 'REFRIGERATEUR', 22.00, 41.30, 20.00, 'REFRIGERATEUR ', 'UNIT', 0, 'BOIS0001'),
('REPA0001', 'REPARATION FORFAITAIRE PRODUITS STANDARD: 14,80 € DE L\'HEURE', 12.37, 15.46, 20.00, 'REPARATION FORFAITAIRE PRODUITS STANDARD: 14,80 € DE L\'HEURE', 'HEUR', 1, 'PRES0001'),
('REPA0002', 'REPARATION FORFAITAIRE PRODUITS TECHNIQUES: 20,50€ DE L\'HEURE', 17.14, 21.43, 20.00, 'REPARATION FORFAITAIRE PRODUITS TECHNIQUES: 20,50€ DE L\'HEURE', 'HEUR', 1, 'PRES0001'),
('ROBO0001', 'ROBOTS TELECOMMANDES', 37.40, 69.89, 20.00, 'ROBOTS TELECOMMANDES', 'UNIT', 0, 'GARC0001'),
('SAC00001', 'SAC DE VOYAGE', 30.25, 56.09, 20.00, 'SAC DE VOYAGE', 'UNIT', 0, 'BEBE0001'),
('SAC00002', 'SAC A DOS SOUPLE ROUGE', 14.30, 26.58, 20.00, 'SAC A DOS SOUPLE ROUGE', 'UNIT', 0, 'FILL0001'),
('SAC00003', 'SAC A MAIN MYRTILLE DE LILI', 9.35, 17.46, 20.00, 'SAC A MAIN MYRTILLE DE LILI', 'UNIT', 0, 'FILL0001'),
('SALL0001', 'LANDAU POUR POUPEE', 22.00, 41.38, 20.00, 'LANDAU POUR POUPEE', 'UNIT', 0, 'FILL0001'),
('SALL0002', 'CHAISE HAUTE POUR POUPEE', 22.00, 41.38, 20.00, 'CHAISE HAUTE POUR POUPEE', 'UNIT', 0, 'FILL0001'),
('SALO0001', 'LANDAU BLEU/ROUGE', 63.80, 118.65, 20.00, 'LANDAU BLEU/ROUGE', 'UNIT', 0, 'FILL0001'),
('SCAR0001', 'JEUX DE REFLEXION', 13.20, 24.83, 20.00, 'JEUX DE REFLEXION', 'UNIT', 0, 'SOCI0001'),
('SET00001', 'SET DE BAINS', 14.85, 27.59, 20.00, 'SET DE BAINS', 'UNIT', 0, 'BEBE0001'),
('SET00002', 'SET MATERNITE BEIGE', 22.55, 42.21, 20.00, 'SET MATERNITE BEIGE', 'UNIT', 0, 'BEBE0001'),
('SING0001', 'SINGE EN PELUCHE', 7.92, 14.71, 20.00, 'SINGE EN PELUCHE', 'UNIT', 0, 'PELU0001'),
('SOUS0001', 'SOUS MARIN MAQUETTE ECHELLE 1:72 150 PIECES', 29.70, 55.17, 20.00, 'SOUS MARIN MAQUETTE ECHELLE 1:72 150 PIECES', 'UNIT', 0, 'MAQU0001'),
('STAG0001', 'STAGE DE D\'EQUITATION 1 SEMAINE', 260.87, 326.09, 20.00, 'STAGE DE D\'EQUITATION 1 SEMAINE  (5 JOURS]', 'SEMA', 1, 'ANIM0001'),
('STAG0002', 'STAGE DE VACANCES JOURNEE 9H - 17H', 33.44, 41.80, 20.00, 'STAGE DE VACANCES JOURNEE 9H - 17H <br> UNE ANIMATION DIFFERENTES CHAQUE JOUR <br> (Cuisine, Bricolage, Création, Sculpture sur ballons, jeux olympiades, cluedo humain...)', 'JOUR', 1, 'ANIM0001'),
('STAG0003', 'STAGE DE VACANCES 1 SEMAINE', 150.50, 188.13, 20.00, 'STAGE DE VACANCES 1 SEMAINE (5 JOURS) <br> UNE ANIMATION DIFFERENTE CHAQUE JOUR  <br> (Cuisine, Bricolage, Création, Sculpture sur ballons, jeux olympiades, cluedo humain...)', 'SEMA', 1, 'ANIM0001'),
('STAG0004', 'STAGE DE PONEY CLUB JOURNEE', 16.72, 20.90, 20.00, 'STAGE DE PONEY CLUB JOURNEE : <br> - THEORIE, SOIN DES PONEYS, <br> - PROMENADE EN FORŹT, <br> - VOLTIGE, <br> - JEUX ÉQUESTRES, <br> - REPAS ET GOŪTER AU PONEY CLUB.', 'JOUR', 1, 'ANIM0001'),
('STAR0001', 'DINOSAURE BRACHIOSAURUS', 9.35, 17.38, 20.00, 'DINOSAURE BRACHIOSAURUS', 'UNIT', 0, 'FIGU0001'),
('STEG0001', 'STEGOSAUREUS', 2.26, 4.24, 20.00, 'STEGOSAUREUS', 'UNIT', 0, 'FIGU0001'),
('SUPE0001', 'MINI ROBOT REPTILE ELECTRONIQUE', 8.80, 16.54, 20.00, 'MINI ROBOT REPTILE ELECTRONIQUE', 'UNIT', 0, 'GARC0001'),
('SUPE0002', 'SUPERCOPTERE MAQUETTE ECHELLE 1:48 75 PIECES', 22.00, 41.30, 20.00, 'SUPERCOPTERE MAQUETTE ECHELLE 1:48 75 PIECES', 'UNIT', 0, 'MAQU0001'),
('T0CH0001', 'LES PREMIERS PAS DE BEBE', 1.98, 3.67, 20.00, 'LES PREMIERS PAS DE BEBE', 'UNIT', 0, 'LIVR0001'),
('T0RE0001', 'T REX 3D LIVRE DE 6 A 9 ANS', 6.44, 11.96, 20.00, 'T REX 3D LIVRE DE 6 A 9 ANS', 'UNIT', 0, 'LIVR0001'),
('TALK0001', 'TALKIE WALKIE PRO', 12.76, 23.90, 20.00, 'TALKIE WALKIE PRO', 'UNIT', 0, 'GARC0001'),
('TAPI0001', 'TAPIS FLIC FLAC', 29.92, 56.06, 20.00, 'TAPIS FLIC FLAC', 'UNIT', 0, 'BEBE0001'),
('TORT0001', 'POISSONS', 2.42, 4.51, 20.00, 'POISSONS', 'UNIT', 0, 'FIGU0001'),
('TOUR0001', 'TOURS DE LIT VELOURS', 17.27, 32.19, 20.00, 'TOURS DE LIT VELOURS', 'UNIT', 0, 'BEBE0001'),
('TRAI0001', 'TRAINS ELECTRIQUES', 32.56, 60.70, 20.00, 'TRAINS ELECTRIQUES ', 'UNIT', 0, 'GARC0001'),
('TRAI0002', 'TRAIN EN BOIS', 12.32, 22.90, 20.00, 'TRAIN EN BOIS ', 'UNIT', 0, 'BOIS0001'),
('TRAI0003', 'TRAIN A ASSEMBLER ET TIRER', 8.36, 15.63, 20.00, 'TRAIN A ASSEMBLER ET TIRER', 'UNIT', 0, 'CONS0001'),
('TRAN0001', 'COWBOY DEGAINANT', 2.42, 4.51, 20.00, 'COWBOY DEGAINANT', 'UNIT', 0, 'FIGU0001'),
('TRIV0001', 'JEUX D\'ECHECS CLASSIQUE', 9.79, 18.30, 20.00, 'JEUX D\'ECHECS CLASSIQUE', 'UNIT', 0, 'SOCI0001'),
('TROU0001', 'TROUSSE DE TOILETTE VELOURS', 12.76, 23.87, 20.00, 'TROUSSE DE TOILETTE VELOURS', 'UNIT', 0, 'BEBE0001'),
('TURB0001', 'PLANEUR ECHELLE 1:32 79 PIECES', 8.80, 16.35, 20.00, 'PLANEUR ECHELLE 1:32 79 PIECES', 'UNIT', 0, 'MAQU0001'),
('VALI0001', 'VALISE POUPEE', 26.18, 48.65, 20.00, 'VALISE POUPEE', 'UNIT', 0, 'FILL0001'),
('VOIT0001', 'VOITURE DE SPORT TELECOMMANDEE', 29.59, 55.17, 20.00, 'VOITURE DE SPORT TELECOMMANDEE', 'UNIT', 0, 'GARC0001'),
('VOIT0002', 'VOITURES DE COURSE 700 PIECES', 9.35, 17.47, 20.00, 'VOITURES DE COURSE 700 PIECES', 'UNIT', 0, 'PUZZ0001');

-- --------------------------------------------------------

--
-- Structure de la table `categoriearticle`
--

CREATE TABLE `categoriearticle` (
  `code_categorie` varchar(20) NOT NULL,
  `code_famille` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `categoriearticle`
--

INSERT INTO `categoriearticle` (`code_categorie`, `code_famille`) VALUES
('ANIM0001', ''),
('ANNI0001', ''),
('BEBE0001', 'PRE0001'),
('BOIS0001', 'BOI0001'),
('CHCA0001', ''),
('CONS0001', 'HAR0001'),
('EDUC0001', 'HIG0001'),
('FIGU0001', 'CON0001'),
('FILL0001', 'POU0001'),
('GARC0001', 'JOU0001'),
('LIVR0001', 'PRI0001'),
('MAQU0001', 'HIG0001'),
('MIXT0001', 'PRE0001'),
('PELU0001', 'PRI0001'),
('PRES0001', ''),
('PUZZ0001', 'PUZ0001'),
('SOCI0001', 'VAR0001');

-- --------------------------------------------------------

--
-- Structure de la table `client`
--

CREATE TABLE `client` (
  `code_tiers` varchar(8) NOT NULL,
  `civilite` varchar(12) DEFAULT NULL,
  `nom` varchar(28) DEFAULT NULL,
  `pourcentage_remise` tinyint(3) DEFAULT NULL,
  `code_mode_reglement` varchar(10) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `code_commercial` varchar(7) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `client`
--

INSERT INTO `client` (`code_tiers`, `civilite`, `nom`, `pourcentage_remise`, `code_mode_reglement`, `notes`, `code_commercial`) VALUES
('BDM0001', 'CE', 'BDMANIA', 0, '', '', 'CO00001'),
('CCL00002', '', 'Clients et comptes rattachés', 0, '', '', ''),
('CCL00003', '', 'ECCA SARL', 0, '', '', 'CO00002'),
('CCL00004', '', 'GESPI', 0, '', '', 'CO00001'),
('CCL00005', '', 'PICOSO', 0, '', '', 'CO00002'),
('CCL00006', '', 'TONIER', 0, '', '', 'CO00001'),
('CL00001', 'Madame', 'MOLINA Sandrine', 0, '', '', 'CO00002'),
('CL00002', 'Madame', 'TARDIEU Antoinette', 0, '', '', 'CO00001'),
('CL00003', 'Madame', 'RAVIN Odile', 0, '', '', 'CO00002'),
('GOU0001', 'Madame', 'GOUJUS Alexandra', 0, '', '', 'CO00002'),
('JAR0001', 'Mademoiselle', 'JAREAU Claire', 0, '', '', 'CO00001'),
('KAL0001', 'Monsieur', 'KALOU André', 0, '', '', 'CO00002'),
('LAM0001', 'Mademoiselle', 'LAMBERT Stéphanie', 0, '', '', 'CO00001'),
('LEC0001', 'Ce', 'LECTURA', 0, '', '', 'CO00002'),
('LEG0001', 'Monsieur', 'LEGENNEC Yannick', 0, '', '', 'CO00001'),
('LOR0001', 'Madame', 'LORENT ALINE', 0, '', '', 'CO00002'),
('MAR0001', 'Monsieur', 'MARTIN Jean-Paul', 0, '', '', 'CO00001'),
('MAR0002', 'Monsieur', 'MARTIN Eric', 0, '', '', 'CO00002'),
('MAR0003', 'Madame', 'MARCHAND Danielle', 0, '', '', 'CO00001'),
('MAR0004', 'Madame', 'MARTINEAU Laura', 0, '', '', 'CO00002'),
('MAS0002', 'Monsieur', 'MASSIN Olivier', 0, '', '', 'CO00001'),
('MET0001', 'Madame', 'METALLIN Elodie', 0, '', '', 'CO00002'),
('MOL0001', 'Monsieur', 'MOLINA Franēois', 0, '', '', 'CO00001'),
('MUL0001', 'Monsieur', 'MULMERSON ED', 0, '', '', 'CO00002'),
('ORM0001', 'Monsieur', 'ORMONT PAUL', 0, '', '', 'CO00001'),
('PET0001', 'CE', 'PETIT LOUP', 0, '', '', 'CO00002'),
('POR0001', 'Monsieur', 'PORTIER Stéphane', 0, '', '', 'CO00001'),
('RIN0001', 'Mademoiselle', 'RINGUAI Nathalie', 0, '', '', 'CO00002'),
('ROQ0001', 'Monsieur', 'ROQUES Jean-Philippe', 0, '', '', 'CO00001'),
('SAN0001', 'Madame', 'SANDYA Céline', 0, '', '', 'CO00002'),
('STA0001', 'Mademoiselle', 'STANLAB Emilie', 0, '', '', 'CO00001'),
('TOR0001', 'Madame', 'TORRES Odile', 0, '', '', 'CO00002'),
('TUL0001', 'Mademoiselle', 'TULIA Sophie', 0, '', '', 'CO00001'),
('VAN0001', 'Monsieur', 'VANNIER Yvan', 0, '', '', 'CO00002'),
('VOI0001', 'Monsieur', 'VOISINA Eric', 0, '', '', 'CO00001'),
('VOI0002', 'Madame', 'VERRON Brigitte', 0, '', '', 'CO00002'),
('VOI0003', 'Madame', 'VINET Francine', 0, '', '', 'CO00001');

-- --------------------------------------------------------

--
-- Structure de la table `devis`
--

CREATE TABLE `devis` (
  `numero` varchar(12) NOT NULL,
  `date_devis` date DEFAULT NULL,
  `code_client` varchar(8) DEFAULT NULL,
  `civilite_client` varchar(8) DEFAULT NULL,
  `nom_client` varchar(50) DEFAULT NULL,
  `adresse_facturation` varchar(50) DEFAULT NULL,
  `code_postal_facturation` varchar(10) DEFAULT NULL,
  `ville_facturation` varchar(50) DEFAULT NULL,
  `code_pays_facturation` varchar(5) DEFAULT NULL,
  `adresse_livraison` varchar(50) DEFAULT NULL,
  `code_postal_livraison` varchar(10) DEFAULT NULL,
  `ville_livraison` varchar(50) DEFAULT NULL,
  `code_pays_livraison` varchar(5) DEFAULT NULL,
  `pourcentage_remise` decimal(5,2) DEFAULT NULL,
  `montant_remise` decimal(10,2) DEFAULT NULL,
  `montant_escompte` decimal(10,2) DEFAULT NULL,
  `code_frais_port` varchar(10) DEFAULT NULL,
  `frais_port_ht` decimal(10,2) DEFAULT NULL,
  `taux_tva_port` decimal(5,2) DEFAULT NULL,
  `code_tva_port` varchar(36) DEFAULT NULL,
  `port_non_soumis_escompte` tinyint(1) DEFAULT NULL,
  `total_brut_ht` decimal(10,2) DEFAULT NULL,
  `total_ttc` decimal(10,2) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `code_commercial` varchar(10) DEFAULT NULL,
  `code_mode_payement` varchar(10) DEFAULT NULL,
  `etat_devis` tinyint(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `devis`
--

INSERT INTO `devis` (`numero`, `date_devis`, `code_client`, `civilite_client`, `nom_client`, `adresse_facturation`, `code_postal_facturation`, `ville_facturation`, `code_pays_facturation`, `adresse_livraison`, `code_postal_livraison`, `ville_livraison`, `code_pays_livraison`, `pourcentage_remise`, `montant_remise`, `montant_escompte`, `code_frais_port`, `frais_port_ht`, `taux_tva_port`, `code_tva_port`, `port_non_soumis_escompte`, `total_brut_ht`, `total_ttc`, `notes`, `code_commercial`, `code_mode_payement`, `etat_devis`) VALUES
('DE00000001', '2024-12-07', 'CCL00003', '', 'ECCA SARL', '5 rue de rivoli', '75001', 'PARIS 1ER ARRONDISSEMENT', 'FR', '5 rue de rivoli', '75001', 'PARIS 1ER ARRONDISSEMENT', 'FR', 2.00, 3.90, 2.01, '', 10.00, 20.00, '36cab0de-3e5b-4bee-a556-8eabb1673e76', 0, 201.10, 233.28, '', 'CO00002', '', 4),
('DE00000002', '2024-12-19', 'CCL00003', '', 'ECCA SARL', '5 rue de rivoli', '75001', 'PARIS 1ER ARRONDISSEMENT', 'FR', '5 rue de rivoli', '75001', 'PARIS 1ER ARRONDISSEMENT', 'FR', 2.00, 6.30, 3.19, '', 10.00, 20.00, '36cab0de-3e5b-4bee-a556-8eabb1673e76', 0, 318.70, 372.98, '', 'CO00002', '', 0),
('DE0900000001', '2017-07-07', 'CL00003', 'Madame', 'RAVIN Odile', '5 rue Mond', '93000', 'BOBIGNY', 'FR', '5 rue Mond', '93000', 'BOBIGNY', 'FR', 0.00, 0.00, 0.00, '', 0.00, 19.60, '823f1060-71b2-419a-b70a-2107c554b35b', 0, 251.88, 301.25, '', '', 'CH2', 3),
('DE0900000002', '2017-07-07', 'MAR0002', 'Monsieur', 'MARTIN Eric', '52 rue pasteur', '94120', 'FONTENAY SOUS BOIS', 'FR', '52 rue pasteur', '94120', 'FONTENAY SOUS BOIS', 'FR', 0.00, 0.00, 0.00, '', 0.00, 19.60, '823f1060-71b2-419a-b70a-2107c554b35b', 0, 213.91, 255.84, '', '', '', 3);


-- --------------------------------------------------------

--
-- Structure de la table `devisLigne`
--

CREATE TABLE `devisLigne` (
  `id_ligne` varchar(36) NOT NULL,
  `numero_devis` varchar(12) DEFAULT NULL,
  `code_article` varchar(8) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `quantite` decimal(10,2) DEFAULT NULL,
  `taux_tva` decimal(5,2) DEFAULT NULL,
  `pv_ht` decimal(10,2) DEFAULT NULL,
  `montant_net_ht` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `devisLigne`
--

INSERT INTO `devisLigne` (`id_ligne`, `numero_devis`, `code_article`, `description`, `quantite`, `taux_tva`, `pv_ht`, `montant_net_ht`) VALUES
('090de12a-ea33-41f6-aa2d-e546f5e3f5fe', 'DE0900000002', 'GARA0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\n\\viewkind4\\uc1\\pard\\f0\\fs17 GARAGE VOITURES\\par\n}\n', 1.00, 19.60, 28.50, 28.50),
('1b4bc241-368b-42c9-9698-778f0438b47e', 'DE00000002', 'ACTI0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\n\\viewkind4\\uc1\\pard\\f0\\fs17 FIGURINE HYBRIDE modifi\\\'e9\\par\n}\n', 3.00, 20.00, 60.00, 180.00),
('3f2374ec-a120-40db-901e-058c8c8bd976', 'DE0900000001', 'ATEL0002', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\n\\viewkind4\\uc1\\pard\\f0\\fs17 ATELIER BRICOLAGE\\par\n}\n', 5.00, 19.60, 31.35, 156.75),
('58f6fa41-230e-4203-be65-9fb0ffb41daf', 'DE00000002', 'ACTI0002', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\n\\viewkind4\\uc1\\pard\\f0\\fs17 VOITURE HERO\\par\n}\n', 1.00, 5.50, 40.00, 40.00),
('5ffeaadd-a7b4-4721-af17-c530457dd99c', 'DE0900000001', 'LOCO0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\n\\viewkind4\\uc1\\pard\\f0\\fs17 LOCOMOTIVE VAPEUR SON ET LUMIERE\\par\n}\n', 1.00, 19.60, 35.86, 35.86),
('629cd8f5-ac06-4fe3-a19f-0d1a1169c2ac', 'DE0900000001', 'GOUT0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\n\\viewkind4\\uc1\\pard\\f0\\fs17 GOUTER SIMPLE\\par\nGo\\\'fbter compos\\\'e9 d\'une cr\\\'eape ou une part de gateau, un bonbon et une boisson froide (soda ou jus de fruit au choix)\\par\n}\n', 5.00, 19.60, 8.36, 41.80),
('76e844d7-bb4e-4542-842c-2a21975df036', 'DE0900000001', 'ACTI0002', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\n\\viewkind4\\uc1\\pard\\f0\\fs17 VOITURE HERO\\par\n}\n', 1.00, 19.60, 17.47, 17.47),
('76f4ab94-2f17-4cd9-a7b9-ecd7f228a856', 'DE00000001', 'ACTI0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\n\\viewkind4\\uc1\\pard\\f0\\fs17 FIGURINE HYBRIDE\\par\n}\n', 2.00, 20.00, 50.00, 95.00),
('7d21565a-4b4e-40e7-8a0e-50aa2bbe090f', 'DE0900000002', 'FISH0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\n\\viewkind4\\uc1\\pard\\f0\\fs17 MAQUETTE HOMO SAPIENS\\par\n}\n', 1.00, 19.60, 10.95, 10.95),
('81b3be4f-ea65-4351-bad1-df9f8bdc11d1', 'DE00000001', 'ACTI0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\n\\viewkind4\\uc1\\pard\\f0\\fs17 FIGURINE HYBRIDE modifi\\\'e9\\par\n}\n', 1.00, 20.00, 60.00, 60.00),
('846a5678-4043-4da3-8b5d-2962134e65f5', 'DE00000001', 'ACTI0002', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\n\\viewkind4\\uc1\\pard\\f0\\fs17 VOITURE HERO\\par\n}\n', 1.00, 5.50, 40.00, 40.00),
('986a9c75-ff2a-45d3-93cf-a0c33452fab3', 'DE0900000002', 'ENSE0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\n\\viewkind4\\uc1\\pard\\f0\\fs17 ENSEMBLE LAVE VAISSELLE\\par\n}\n', 1.00, 19.60, 110.36, 110.36),
('a0b0f0f5-6bc8-4173-a30d-5959cdc7b6e3', 'DE0900000002', 'DEST0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\n\\viewkind4\\uc1\\pard\\f0\\fs17 JEUX FAMILIAL ELECTRONIQUE\\par\n}\n', 1.00, 19.60, 50.49, 50.49),
('a7b99c9b-29f8-4f5a-94cd-e9a08655388a', 'DE0900000002', 'GIRA0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\n\\viewkind4\\uc1\\pard\\f0\\fs17 HIPPOPOTAME MALE\\par\n}\n', 1.00, 19.60, 5.34, 5.34),
('a8905814-1a01-4c88-a045-2a8517825eb9', 'DE00000002', 'ACTI0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\n\\viewkind4\\uc1\\pard\\f0\\fs17 FIGURINE HYBRIDE\\par\n}\n', 2.00, 20.00, 50.00, 95.00),
('bd89e4ea-7783-4773-97d1-f2061b8fb5ad', 'DE0900000002', 'ETOI0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\n\\viewkind4\\uc1\\pard\\f0\\fs17 ETOILES ET PLANETES LIVRE 9 ANS ET PLUS\\par\n}\n', 1.00, 19.60, 8.27, 8.27);

--
-- Déclencheurs `devis`
--

DELIMITER $$

-- 1. TRIGGER AVANT INSERTION DEVIS (Numérotation Auto)
DROP TRIGGER IF EXISTS `before_insert_devis`$$
CREATE TRIGGER `before_insert_devis` BEFORE INSERT ON `devis` FOR EACH ROW 
BEGIN
    DECLARE next_num INT;
    DECLARE current_year CHAR(4);
    
    -- Date par défaut
    IF NEW.date_devis IS NULL THEN 
        SET NEW.date_devis = CURDATE(); 
    END IF;

    -- Génération du numéro DE + Année + Compteur
    IF NEW.numero IS NULL OR NEW.numero = '' THEN
        SET current_year = YEAR(NEW.date_devis);
        
        SELECT COALESCE(MAX(CAST(SUBSTRING(numero, 7) AS UNSIGNED)), 0) + 1 
        INTO next_num
        FROM devis 
        WHERE SUBSTRING(numero, 1, 2) = 'DE' 
        AND SUBSTRING(numero, 3, 4) = current_year;
        
        SET NEW.numero = CONCAT('DE', current_year, LPAD(next_num, 3, '0'));
    END IF;
END$$

-- 2. TRIGGER AVANT UPDATE DEVIS (Protection)
DROP TRIGGER IF EXISTS `before_update_devis`$$
CREATE TRIGGER `before_update_devis` BEFORE UPDATE ON `devis` FOR EACH ROW 
BEGIN
    -- Interdire modif numéro
    IF OLD.numero != NEW.numero THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Modification du numéro de devis interdite';
    END IF;
    
    IF OLD.etat_devis >= 2 THEN
        IF OLD.total_brut_ht != NEW.total_brut_ht OR OLD.total_ttc != NEW.total_ttc THEN
             SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Devis validé : Modification financière interdite';
        END IF;
    END IF;
END$$

-- 3. TRIGGER AVANT DELETE DEVIS (Protection)
DROP TRIGGER IF EXISTS `before_delete_devis`$$
CREATE TRIGGER `before_delete_devis` BEFORE DELETE ON `devis` FOR EACH ROW 
BEGIN
    IF OLD.etat_devis >= 2 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Suppression interdite - Le devis est validé';
    END IF;
END$$

-- 4. TRIGGERS CALCUL AUTO (Sur devisLigne)
DROP TRIGGER IF EXISTS `after_devisligne_insert`$$
CREATE TRIGGER `after_devisligne_insert` AFTER INSERT ON `devisLigne` FOR EACH ROW 
BEGIN
    UPDATE devis 
    SET total_brut_ht = (SELECT COALESCE(SUM(montant_net_ht), 0) FROM devisLigne WHERE numero_devis = NEW.numero_devis)
    WHERE numero = NEW.numero_devis;
END$$

DROP TRIGGER IF EXISTS `after_devisligne_update`$$
CREATE TRIGGER `after_devisligne_update` AFTER UPDATE ON `devisLigne` FOR EACH ROW 
BEGIN
    UPDATE devis 
    SET total_brut_ht = (SELECT COALESCE(SUM(montant_net_ht), 0) FROM devisLigne WHERE numero_devis = NEW.numero_devis)
    WHERE numero = NEW.numero_devis;
END$$

DROP TRIGGER IF EXISTS `after_devisligne_delete`$$
CREATE TRIGGER `after_devisligne_delete` AFTER DELETE ON `devisLigne` FOR EACH ROW 
BEGIN
    UPDATE devis 
    SET total_brut_ht = (SELECT COALESCE(SUM(montant_net_ht), 0) FROM devisLigne WHERE numero_devis = OLD.numero_devis)
    WHERE numero = OLD.numero_devis;
END$$

-- 5. TRIGGERS PROTECTION LIGNE (Sur devisLigne)
DROP TRIGGER IF EXISTS `before_update_devisligne`$$
CREATE TRIGGER `before_update_devisligne` BEFORE UPDATE ON `devisLigne` FOR EACH ROW 
BEGIN
    DECLARE etat_parent TINYINT;
    SELECT etat_devis INTO etat_parent FROM devis WHERE numero = OLD.numero_devis;
    
    IF etat_parent >= 2 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Modification ligne interdite - Devis validé';
    END IF;
END$$

DROP TRIGGER IF EXISTS `before_delete_devisligne`$$
CREATE TRIGGER `before_delete_devisligne` BEFORE DELETE ON `devisLigne` FOR EACH ROW 
BEGIN
    DECLARE etat_parent TINYINT;
    SELECT etat_devis INTO etat_parent FROM devis WHERE numero = OLD.numero_devis;
    
    IF etat_parent >= 2 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Suppression ligne interdite - Devis validé';
    END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `export_articles`
--

CREATE TABLE `export_articles` (
  `code_article` varchar(8) DEFAULT NULL,
  `nom` varchar(61) DEFAULT NULL,
  `categorie` varchar(8) DEFAULT NULL,
  `prix_achat_ht` varchar(12) DEFAULT NULL,
  `prix_vente_ht` varchar(12) DEFAULT NULL,
  `taux_tva` varchar(5) DEFAULT NULL,
  `description` varchar(174) DEFAULT NULL,
  `COL 8` varchar(181) DEFAULT NULL,
  `unite_vente` varchar(4) DEFAULT NULL,
  `article_actif` varchar(4) DEFAULT NULL,
  `COL 11` varchar(1) DEFAULT NULL,
  `code_famille` varchar(7) DEFAULT NULL,
  `code_d3e` varchar(8) DEFAULT NULL,
  `COL 14` varchar(10) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Déchargement des données de la table `export_articles`
--

INSERT INTO `export_articles` (`code_article`, `nom`, `categorie`, `prix_achat_ht`, `prix_vente_ht`, `taux_tva`, `description`, `COL 8`, `unite_vente`, `article_actif`, `COL 11`, `code_famille`, `code_d3e`, `COL 14`) VALUES
('ACTI0001', 'FIGURINE HYBRIDE ', 'GARC0001', '19,80000000', '36,77000000', '20,00', 'FIGURINE HYBRIDE', '', 'UNIT', '0', '', 'JOU0001', '', NULL),
('ACTI0002', 'VOITURE HERO', 'GARC0001', '9,35000000', '17,47000000', '20,00', 'VOITURE HERO', '', 'UNIT', '0', '', 'JOU0001', '', NULL),
('ANIM0001', 'ANIMATEUR/ANIMATRICE', 'PRES0001', '129,60000000', '162,00000000', '20,00', 'ANIMATEUR/ANIMATRICE POUR LA JOURNEE', '', 'JOUR', '1', '', '', '', NULL),
('ANIM0002', 'ASSISTANT/ASSISTANTE', 'PRES0001', '50,17000000', '62,71000000', '20,00', 'ASSISTANT/ASSISTANTE POUR LA JOURNEE', '', 'JOUR', '1', '', '', '', NULL),
('ANIM0003', 'MAGICIEN', 'PRES0001', '292,64000000', '365,80000000', '20,00', 'MAGICIEN POUR LA JOURNEE', '', 'JOUR', '1', '', '', '', NULL),
('ANIM0004', 'PERE NOEL', 'PRES0001', '167,22000000', '209,03000000', '20,00', 'PERE NOEL POUR LA JOURNEE', '', 'JOUR', '1', '', '', '', NULL),
('ANIM0005', 'MASCOTTE', 'PRES0001', '50,17000000', '62,71000000', '20,00', 'MASCOTTE POUR LA JOURNEE', '', 'JOUR', '1', '', '', '', NULL),
('ANIM0006', 'CLOWNS', 'PRES0001', '250,84000000', '313,55000000', '20,00', 'CLOWNS POUR LA JOURNEE', '', 'JOUR', '1', '', '', '', NULL),
('ATEL0001', 'ATELIER CREATION', 'ANIM0001', '25,08000000', '31,35000000', '20,00', 'ATELIER CREATION', '', 'JOUR', '1', '', '', '', NULL),
('ATEL0002', 'ATELIER BRICOLAGE', 'ANIM0001', '25,08000000', '31,35000000', '20,00', 'ATELIER BRICOLAGE', '', 'JOUR', '1', '', '', '', NULL),
('ATEL0003', 'ATELIER CUISINE', 'ANIM0001', '25,08000000', '31,35000000', '20,00', 'ATELIER CUISINE', '', 'JOUR', '1', '', '', '', NULL),
('ATEL0004', 'ATELIER SCULPTURE SUR BALLONS', 'ANIM0001', '25,08000000', '31,35000000', '20,00', 'ATELIER SCULPTURE SUR BALLONS', '', 'JOUR', '1', '', '', '', NULL),
('ATTA0001', 'ATTACHE-TETINE COEURS', 'BEBE0001', '4,84000000', '9,11000000', '20,00', 'ATTACHE-TETINE COEURS', '', 'UNIT', '0', '', 'PRE0001', '', NULL),
('AU0Z0001', 'AU ZOO AVEC HECTOR LIVRE DE 3 A 6 ANS', 'LIVR0001', '4,18000000', '7,82000000', '20,00', 'AU ZOO AVEC HECTOR LIVRE DE 3 A 6 ANS', '', 'UNIT', '0', '', 'PRI0001', '', NULL),
('AVIO0001', 'AVIONS TELECOMMANDES', 'GARC0001', '29,70000000', '55,18000000', '20,00', 'AVIONS TELECOMMANDES', '', 'UNIT', '0', '', 'JOU0001', 'D3E00026', NULL),
('BARB0001', 'SET GLADIATEUR', 'FIGU0001', '7,59000000', '14,26000000', '20,00', 'SET GLADIATEUR', '', 'UNIT', '0', '', 'CON0001', '', NULL),
('BARB0002', 'COFFRET BOUTIQUE MODE', 'FILL0001', '12,32000000', '22,90000000', '20,00', 'COFFRET BOUTIQUE MODE', '', 'UNIT', '0', '', 'POU0001', '', NULL),
('BARB0003', 'POUPEE FASHION ', 'FILL0001', '6,82000000', '12,78000000', '20,00', 'POUPEE FASHION', '', 'UNIT', '0', '', 'POU0001', '', NULL),
('BARB0004', 'HABIT ROSE POUPEE', 'FILL0001', '4,18000000', '7,82000000', '20,00', 'HABIT ROSE POUPEE', '', 'UNIT', '0', '', 'POU0001', '', NULL),
('BARB0005', 'CHEVAL SAUT D\'OBSTACLES + POUPEE', 'FILL0001', '23,43000000', '44,05000000', '20,00', 'CHEVAL SAUT D\'OBSTACLES + POUPEE', '', 'UNIT', '0', '', 'POU0001', '', NULL),
('BATE0001', 'BATEAU FORCE SPEED', 'GARC0001', '29,70000000', '55,18000000', '20,00', 'BATEAU FORCE SPEED', '', 'UNIT', '0', '', 'JOU0001', 'D3E00028', NULL),
('BATM0001', ' FIGURINE COLLECTOR DEFI', 'GARC0001', '19,58000000', '36,33000000', '20,00', ' FIGURINE COLLECTOR DEFI', '', 'UNIT', '0', '', 'JOU0001', '', NULL),
('BAVO0001', 'BAVOIRS FUNNY', 'BEBE0001', '2,20000000', '4,13000000', '20,00', 'BAVOIRS FUNNY', '', 'UNIT', '0', '', 'PRE0001', '', NULL),
('BLAN0001', 'BLANCHE NEIGE LIVRE DE 3 A 6 ANS', 'LIVR0001', '6,11000000', '11,50000000', '20,00', 'BLANCHE NEIGE LIVRE DE 3 A 6 ANS', '', 'UNIT', '0', '', 'PRI0001', '', NULL),
('BLOC0001', 'BLOC DE MOUSSE A ASSEMBLER', 'CONS0001', '8,25000000', '15,54000000', '20,00', 'BLOC DE MOUSSE A ASSEMBLER', '', 'UNIT', '0', '', 'HAR0001', '', NULL),
('BUS00001', 'BUS SCOLAIRE 30 CM ', 'GARC0001', '12,76000000', '23,90000000', '20,00', 'BUS SCOLAIRE 30 CM ', '', 'UNIT', '0', '', 'JOU0001', '', NULL),
('BUZZ0001', 'FIGURINE HEROS', 'FIGU0001', '2,64000000', '4,96000000', '20,00', 'FIGURINE HEROS', '', 'UNIT', '0', '', 'CON0001', '', NULL),
('CADR0001', 'CADRE PHOTOS', 'BEBE0001', '2,97000000', '5,50000000', '20,00', 'CADRE PHOTOS', '', 'UNIT', '0', '', 'PRE0001', '', NULL),
('CAMI0001', 'CAMIONS REMORQUES', 'GARC0001', '5,17000000', '9,66000000', '20,00', 'CAMIONS REMORQUES', '', 'UNIT', '0', '', 'JOU0001', '', NULL),
('CAMP0001', 'CAMPING CAR AVEC ACCESSOIRES', 'GARC0001', '17,60000000', '33,10000000', '20,00', 'CAMPING CAR AVEC ACCESSOIRES', '', 'UNIT', '0', '', 'JOU0001', '', NULL),
('CANA0001', 'CANARD JAUNE EN PELUCHE', 'PELU0001', '13,20000000', '24,75000000', '20,00', 'CANARD JAUNE EN PELUCHE', '', 'UNIT', '0', '', 'PRI0001', '', NULL),
('CEND0001', 'CENDRILLON LIVRE DE 3 A 6 ANS', 'LIVR0001', '6,82000000', '12,78000000', '20,00', 'CENDRILLON LIVRE DE 3 A 6 ANS', '', 'UNIT', '0', '', 'PRI0001', '', NULL),
('CHAM0001', 'CHAMBRE ENFANTS MODERNE', 'FILL0001', '247,50000000', '459,87000000', '20,00', 'CHAMBRE ENFANTS MODERNE', '', 'UNIT', '0', '', 'POU0001', '', NULL),
('CHAQ0001', 'CHEQUE CADEAU 100€', 'CHCA0001', '83,61000000', '104,51000000', '20,00', 'CHEQUE CADEAU 100€', '', 'UNIT', '1', '', '', '', NULL),
('CHEQ0001', 'CHEQUE CADEAU 30€', 'CHCA0001', '25,08000000', '31,35000000', '20,00', 'CHEQUE CADEAU 30€', '', 'UNIT', '1', '', '', '', NULL),
('CHEQ0002', 'CHEQUE CADEAU 50€', 'CHCA0001', '41,81000000', '52,26000000', '20,00', 'CHEQUE CADEAU 50€', '', 'UNIT', '1', '', '', '', NULL),
('CHEV0001', 'FIGURINE CHEVALIERS', 'FIGU0001', '2,42000000', '4,51000000', '20,00', 'FIGURINE CHEVALIERS', '', 'UNIT', '0', '', 'CON0001', '', NULL),
('CHIO0001', 'BEBE TIGRE BLANC', 'FIGU0001', '1,82000000', '3,41000000', '20,00', 'BEBE TIGRE BLANC', '', 'UNIT', '0', '', 'CON0001', '', NULL),
('CLES0001', 'CLES MUSICALES D\'ACTIVITES', 'BEBE0001', '7,37000000', '13,75000000', '20,00', 'CLES MUSICALES D\'ACTIVITES', '', 'UNIT', '0', '', 'PRE0001', '', NULL),
('CORR0001', 'BEBE PREND SON POUCE', 'FILL0001', '12,87000000', '23,90000000', '20,00', 'BEBE PREND SON POUCE', '', 'UNIT', '0', '', 'POU0001', '', NULL),
('CORR0002', 'POUPEE BEBE VALENTINE', 'BEBE0001', '12,87000000', '23,87000000', '20,00', 'POUPEE BEBE VALENTINE', '', 'UNIT', '0', '', 'PRE0001', '', NULL),
('CORR0003', 'LANDAU POUSSETTE MARINE', 'FILL0001', '53,90000000', '101,16000000', '20,00', 'LANDAU POUSSETTE MARINE', '', 'UNIT', '0', '', 'POU0001', '', NULL),
('CORR0004', 'SAC NURSERY FLEURS', 'FILL0001', '14,30000000', '26,58000000', '20,00', 'SAC NURSERY FLEURS', '', 'UNIT', '0', '', 'POU0001', '', NULL),
('CORV0001', 'C5 MAQUETTE ECHELLE 1:25 180 PIECES', 'MAQU0001', '10,78000000', '20,23000000', '20,00', 'C5 MAQUETTE ECHELLE 1:25 180 PIECES', '', 'UNIT', '0', '', 'HIG0001', '', NULL),
('DECO0001', 'DECOR BALLONS SIMPLES', 'ANNI0001', '41,81000000', '52,26000000', '20,00', 'DECOR BALLONS SIMPLES', '', 'UNIT', '1', '', 'GOU0001', '', NULL),
('DECO0002', 'DECOR BALLONS HELIUM', 'ANNI0001', '125,42000000', '156,78000000', '20,00', 'DECOR BALLONS  HELIUM [100 BALLONS)', '', 'UNIT', '1', '', 'GOU0001', '', NULL),
('DECO0003', 'DECOR DE TABLE A THEME', 'ANNI0001', '50,17000000', '62,71000000', '20,00', 'DECOR DE TABLE A THEME', '', 'UNIT', '1', '', 'GOU0001', '', NULL),
('DECO0004', 'DECOR THEME BABAR', 'ANNI0001', '83,61000000', '104,51000000', '20,00', 'DECOR THEME BABAR', '', 'UNIT', '1', '', 'GOU0001', '', NULL),
('DECO0005', 'DECOR THEME PRINCESSE', 'ANNI0001', '83,61000000', '104,51000000', '20,00', 'DECOR THEME PRINCESSE', '', 'UNIT', '1', '', 'GOU0001', '', NULL),
('DECO0006', 'DECOR THEME FEE', 'ANNI0001', '83,61000000', '104,51000000', '20,00', 'DECOR THEME FEE', '', 'UNIT', '1', '', 'GOU0001', '', NULL),
('DECO0007', 'DECOR THEME PIRATE', 'ANNI0001', '83,61000000', '104,51000000', '20,00', 'DECOR THEME PIRATE', '', 'UNIT', '1', '', 'GOU0001', '', NULL),
('DECO0008', 'DECOR THEME SPIDER MAN', 'ANNI0001', '83,61000000', '104,51000000', '20,00', 'DECOR THEME SPIDER MAN', '', 'UNIT', '1', '', 'GOU0001', '', NULL),
('DEST0001', 'JEUX FAMILIAL ELECTRONIQUE', 'SOCI0001', '26,95000000', '50,49000000', '20,00', 'JEUX FAMILIAL ELECTRONIQUE', '', 'UNIT', '0', '', 'VAR0001', 'D3E00027', NULL),
('DX0L0001', 'CONSOLE DE JEUX PORTABLE', 'MIXT0001', '71,50000000', '134,19000000', '20,00', 'CONSOLE DE JEUX PORTABLE', '', 'UNIT', '0', '', 'PRE0001', 'D3E00026', NULL),
('ENSE0001', 'ENSEMBLE LAVE VAISSELLE', 'BOIS0001', '59,40000000', '110,36000000', '20,00', 'ENSEMBLE LAVE VAISSELLE', '', 'UNIT', '0', '', 'BOI0001', '', NULL),
('ETOI0001', 'ETOILES ET PLANETES LIVRE 9 ANS ET PLUS', 'LIVR0001', '4,40000000', '8,27000000', '20,00', 'ETOILES ET PLANETES LIVRE 9 ANS ET PLUS', '', 'UNIT', '0', '', 'PRI0001', '', NULL),
('FERM0001', 'FERME MUSICALE ', 'PUZZ0001', '10,78000000', '20,14000000', '20,00', 'FERME MUSICALE ', '', 'UNIT', '0', '', 'PUZ0001', '', NULL),
('FISH0001', 'MAQUETTE HOMO SAPIENS', 'FIGU0001', '5,83000000', '10,95000000', '20,00', 'MAQUETTE HOMO SAPIENS', '', 'UNIT', '0', '', 'CON0001', '', NULL),
('FOUR0001', 'FOUR A MICRO ONDES', 'BOIS0001', '17,60000000', '33,10000000', '20,00', 'FOUR A MICRO ONDES', '', 'UNIT', '0', '', 'BOI0001', '', NULL),
('GARA0001', 'GARAGE VOITURES', 'GARC0001', '15,29000000', '28,50000000', '20,00', 'GARAGE VOITURES', '', 'UNIT', '0', '', 'JOU0001', '', NULL),
('GIGO0001', 'GIGOTEUSES', 'BEBE0001', '35,20000000', '66,22000000', '20,00', 'GIGOTEUSES', '', 'UNIT', '0', '', 'PRE0001', '', NULL),
('GIRA0001', 'HIPPOPOTAME MALE', 'FIGU0001', '2,86000000', '5,34000000', '20,00', 'HIPPOPOTAME MALE', '', 'UNIT', '0', '', 'CON0001', '', NULL),
('GOUT0001', 'GOUTER SIMPLE', 'ANNI0001', '6,69000000', '8,36000000', '20,00', 'GOUTER SIMPLE <br> Goūter composé d\'une crźpe ou une part de gateau, un bonbon et une boisson froide (soda ou jus de fruit au choix)', '', 'PERS', '1', '', 'GOU0001', '', NULL),
('GOUT0002', 'GOUTER ELABORE', 'ANNI0001', '8,36000000', '10,45000000', '20,00', 'GOUTER ELABORE <br> Goūter composé d\'une crźpe ou une part de gateau, une brochette de bonbons, barbe ą papa et une boisson froide (soda ou jus de fruit au choix)', '', 'PERS', '1', '', 'GOU0001', '', NULL),
('GOUT0003', 'COCKTAIL PARENTS', 'ANNI0001', '7,53000000', '9,41000000', '20,00', 'COCKTAIL PARENTS <br> Cocktail composé de 5 petits fours ou une part de gateau et une boisson froide (soda ou jus de fruit au choix) ou café', '', 'PERS', '1', '', 'GOU0001', '', NULL),
('GOUT0004', 'GOUTER DE 15H A 18H', 'ANNI0001', '242,47000000', '303,09000000', '20,00', 'GOUTER DE 15H 18H POUR 10 ENFANTS', '', 'UNIT', '1', '', 'GOU0001', '', NULL),
('GOUT0005', 'DEJEUNER DE 11H A 15H', 'ANNI0001', '242,47000000', '303,09000000', '20,00', 'DEJEUNER DE 11H A 15H POUR 10 ENFANTS', '', 'UNIT', '1', '', 'GOU0001', '', NULL),
('GOUT0006', 'BOUM DE 19H A 22H', 'ANNI0001', '359,53000000', '449,41000000', '20,00', 'BOUM DE 19H A 22H POUR 15 ENFANTS <br> (Enfants ą partir de 10 ans)', 'Boum animée par un DJ animateur, Quiz musical, Jeux dansants, Concours de danse <br> Buffet composé de pizza, chips, moeulleux au chocolat, bonbons et boissons (soda, jus de fruits)', '', 'UNIT', '1', '', 'GOU0001', ''),
('GOUT0007', 'GOUTER ENFANTS SUPPLEMENTAIRES', 'ANNI0001', '20,90000000', '26,13000000', '20,00', 'GOUTER ENFANTS SUPPLEMENTAIRES', '', 'PERS', '1', '', 'GOU0001', '', NULL),
('GRAN0001', 'GRAND LIVRE TISSU - ANIMAUX DECORS', 'LIVR0001', '2,97000000', '5,51000000', '20,00', 'GRAND LIVRE TISSU - ANIMAUX DECORS', '', 'UNIT', '0', '', 'PRI0001', '', NULL),
('GRAN0002', 'GRANDE LOCOMOTIVE ', 'GARC0001', '19,25000000', '35,86000000', '20,00', 'GRANDE LOCOMOTIVE ', '', 'UNIT', '0', '', 'JOU0001', '', NULL),
('GRAN0003', 'GRANDES DALLES CHIFFRES PUZZLES', 'PUZZ0001', '3,91000000', '7,36000000', '20,00', 'GRANDES DALLES CHIFFRES PUZZLES', '', 'UNIT', '0', '', 'PUZ0001', '', NULL),
('GRIL0001', 'GRILLE PAIN', 'BOIS0001', '11,33000000', '21,15000000', '20,00', 'GRILLE PAIN', '', 'UNIT', '0', '', 'BOI0001', '', NULL),
('GRUE0001', 'GRUE VEHICULES DE CHANTIER', 'GARC0001', '7,37000000', '13,79000000', '20,00', 'GRUE VEHICULES DE CHANTIER', '', 'UNIT', '0', '', 'JOU0001', '', NULL),
('HELI0001', 'HELICOPTERES TELECOMMANDES', 'GARC0001', '12,87000000', '23,90000000', '20,00', 'HELICOPTERES TELECOMMANDES', '', 'UNIT', '0', '', 'JOU0001', 'D3E00028', NULL),
('HOCH0001', 'HOCHET CARILLON', 'BEBE0001', '5,94000000', '11,04000000', '20,00', 'HOCHET CARILLON', '', 'UNIT', '0', '', 'PRE0001', '', NULL),
('HOUS0001', 'HOUSSE DE COUETTE VELOURS 100 X 140 + TAIE', 'BEBE0001', '31,79000000', '59,79000000', '20,00', 'HOUSSE DE COUETTE VELOURS 100 X 140 + TAIE', '', 'UNIT', '0', '', 'PRE0001', '', NULL),
('JEU00001', 'JEUX D\'ADRESSE', 'EDUC0001', '3,41000000', '6,39000000', '20,00', 'JEUX D\'ADRESSE', '', 'UNIT', '0', '', 'HIG0001', '', NULL),
('JEU00002', 'JEUX DE PETITS CHEVAUX', 'EDUC0001', '7,37000000', '13,75000000', '20,00', 'JEUX DE PETITS CHEVAUX', '', 'UNIT', '0', '', 'HIG0001', '', NULL),
('JEU00003', 'JEUX DU NAIN JAUNE', 'EDUC0001', '5,17000000', '9,66000000', '20,00', 'JEUX DU NAIN JAUNE', '', 'UNIT', '0', '', 'HIG0001', '', NULL),
('JEUX0001', 'JEUX D\'ECHECS DE VOYAGE', 'EDUC0001', '10,12000000', '18,86000000', '20,00', 'JEUX D\'ECHECS DE VOYAGE', '', 'UNIT', '0', '', 'HIG0001', '', NULL),
('JEUX0002', 'JEUX DE DAMES', 'EDUC0001', '7,59000000', '14,26000000', '20,00', 'JEUX DE DAMES', '', 'UNIT', '0', '', 'HIG0001', '', NULL),
('JEUX0003', 'CLUEDO HUMAIN', 'ANIM0001', '20,90000000', '26,13000000', '20,00', 'CLUEDO HUMAIN', '', 'PERS', '1', '', '', '', NULL),
('JEUX0004', 'JEUX OLYMPIADES', 'ANIM0001', '20,90000000', '26,13000000', '20,00', 'JEUX OLYMPIADES', '', 'PERS', '1', '', '', '', NULL),
('JUNG0001', 'JUNGLE MUSICAL PUZZLES', 'PUZZ0001', '10,78000000', '20,14000000', '20,00', 'JUNGLE MUSICAL PUZZLES', '', 'UNIT', '0', '', 'PUZ0001', '', NULL),
('KAYA0001', 'CHAUSSONS 3 A 9 MOIS', 'BEBE0001', '1,72000000', '3,23000000', '20,00', 'CHAUSSONS 3 A 9 MOIS', '', 'UNIT', '0', '', 'PRE0001', '', NULL),
('L0AB0001', 'L\'ABC DU DESSIN LIVRE DE 6 A 9 ANS', 'LIVR0001', '3,41000000', '6,42000000', '20,00', 'L\'ABC DU DESSIN LIVRE DE 6 A 9 ANS', '', 'UNIT', '0', '', 'PRI0001', '', NULL),
('LA0G0001', 'LA GARE ANIMEE LIVRE DE 0 A 3 ANS', 'LIVR0001', '2,48000000', '4,60000000', '20,00', 'LA GARE ANIMEE LIVRE DE 0 A 3 ANS', '', 'UNIT', '0', '', 'PRI0001', '', NULL),
('LA0M0001', 'JEUX DE STRATEGIE', 'SOCI0001', '14,30000000', '26,58000000', '20,00', 'JEUX DE STRATEGIE', '', 'UNIT', '0', '', 'VAR0001', '', NULL),
('LAPI0001', 'LAPIN ROSE A MUSIQUE', 'PELU0001', '21,78000000', '40,39000000', '20,00', 'LAPIN ROSE A MUSIQUE', '', 'UNIT', '0', '', 'PRI0001', '', NULL),
('LE0C0001', 'LE CHEVAL EN BOIS', 'BOIS0001', '26,95000000', '50,58000000', '20,00', 'LE CHEVAL EN BOIS', '', 'UNIT', '0', '', 'BOI0001', '', NULL),
('LE0C0002', 'LE CORPS HUMAIN LIVRE DE 9 ANS ET PLUS', 'LIVR0001', '5,94000000', '11,03000000', '20,00', 'LE CORPS HUMAIN LIVRE DE 9 ANS ET PLUS', '', 'UNIT', '0', '', 'PRI0001', '', NULL),
('LE0C0003', 'LE CHATEAU A CONSTRUIRE', 'CONS0001', '13,20000000', '24,78000000', '20,00', 'LE CHATEAU A CONSTRUIRE', '', 'UNIT', '0', '', 'HAR0001', '', NULL),
('LE0C0004', 'LE CIRQUE A ASSEMBLER', 'CONS0001', '19,80000000', '36,74000000', '20,00', 'LE CIRQUE A ASSEMBLER', '', 'UNIT', '0', '', 'HAR0001', '', NULL),
('LE0F0001', 'LE FAR WEST A ASSEMBLER', 'CONS0001', '13,20000000', '24,78000000', '20,00', 'LE FAR WEST A ASSEMBLER', '', 'UNIT', '0', '', 'HAR0001', '', NULL),
('LEGO0001', 'FIGURINE FERMIER', 'GARC0001', '4,95000000', '9,19000000', '20,00', 'FIGURINE FERMIER', '', 'UNIT', '0', '', 'JOU0001', '', NULL),
('LEGO0002', 'FIGURINE POMPIER', 'GARC0001', '4,95000000', '9,19000000', '20,00', 'FIGURINE POMPIER', '', 'UNIT', '0', '', 'JOU0001', '', NULL),
('LEGO0003', 'FIGURINE SAFARI', 'GARC0001', '4,95000000', '9,19000000', '20,00', 'FIGURINE SAFARI', '', 'UNIT', '0', '', 'JOU0001', '', NULL),
('LION0001', 'LION SAUVAGE EN PELUCHE 23 CM', 'PELU0001', '9,79000000', '18,30000000', '20,00', 'LION SAUVAGE EN PELUCHE 23 CM', '', 'UNIT', '0', '', 'PRI0001', '', NULL),
('LIT00001', 'LIT BEBE', 'FILL0001', '17,38000000', '32,19000000', '20,00', 'LIT BEBE', '', 'UNIT', '0', '', 'POU0001', '', NULL),
('LOCO0001', 'LOCOMOTIVE VAPEUR SON ET LUMIERE', 'GARC0001', '19,25000000', '35,86000000', '20,00', 'LOCOMOTIVE VAPEUR SON ET LUMIERE', '', 'UNIT', '0', '', 'JOU0001', 'D3E00028', NULL),
('LOLA0001', 'LOLA TAPIS D\'EVEIL', 'BEBE0001', '37,07000000', '69,89000000', '20,00', 'LOLA TAPIS D\'EVEIL', '', 'UNIT', '0', '', 'PRE0001', '', NULL),
('LUMI0001', 'CHAT MUSICAL 19 CM', 'PELU0001', '6,93000000', '12,87000000', '20,00', 'CHAT MUSICAL 19 CM', '', 'UNIT', '0', '', 'PRI0001', 'D3E00028', NULL),
('MA0P0001', 'MA PREMIERE MAISON POUPEE', 'FILL0001', '25,30000000', '46,86000000', '20,00', 'MA PREMIERE MAISON POUPEE', '', 'UNIT', '0', '', 'POU0001', '', NULL),
('MA0P0002', 'MA PLAGE ANIMEE LIVRE DE 0 A 3 ANS', 'LIVR0001', '2,48000000', '4,60000000', '20,00', 'MA PLAGE ANIMEE LIVRE DE 0 A 3 ANS', '', 'UNIT', '0', '', 'PRI0001', '', NULL),
('MATT0001', 'MON BEBE A CALINER', 'FILL0001', '17,38000000', '32,19000000', '20,00', 'MON BEBE A CALINER', '', 'UNIT', '0', '', 'POU0001', '', NULL),
('MEMO0001', 'MEMO ANIMAUX', 'EDUC0001', '1,74000000', '3,22000000', '20,00', 'MEMO ANIMAUX', '', 'UNIT', '0', '', 'HIG0001', '', NULL),
('MON00001', 'MON LAPIN EN PELUCHE 36 CM', 'PELU0001', '17,60000000', '33,00000000', '20,00', 'MON LAPIN EN PELUCHE 36 CM', '', 'UNIT', '0', '', 'PRI0001', '', NULL),
('MONO0001', 'JEUX DE RŌLE', 'SOCI0001', '13,20000000', '24,83000000', '20,00', 'JEUX DE RŌLE', '', 'UNIT', '0', '', 'VAR0001', '', NULL),
('MOTO0001', 'MOTOS CASCADES', 'GARC0001', '11,88000000', '22,07000000', '20,00', 'MOTOS CASCADES', '', 'UNIT', '0', '', 'JOU0001', '', NULL),
('MOTO0002', 'MOTO BIG RACER ', 'GARC0001', '73,70000000', '137,95000000', '20,00', 'MOTO BIG RACER', '', 'UNIT', '0', '', 'JOU0001', '', NULL),
('MUST0001', 'MUSTANG GT MAQUETTE ECHELLE 1:25 135 PIECES', 'MAQU0001', '10,78000000', '20,15000000', '20,00', 'MUSTANG GT MAQUETTE ECHELLE 1:25 135 PIECES', '', 'UNIT', '0', '', 'HIG0001', '', NULL),
('ORQU0001', 'ORQUE EN PELUCHE', 'PELU0001', '8,36000000', '15,54000000', '20,00', 'ORQUE EN PELUCHE', '', 'UNIT', '0', '', 'PRI0001', '', NULL),
('OURS0001', 'OURS BEIGE 23 CM ', 'PELU0001', '7,81000000', '14,61000000', '20,00', 'OURS BEIGE 23 CM ', '', 'UNIT', '0', '', 'PRI0001', '', NULL),
('PACO0001', 'PYJAMA BICOLOR', 'BEBE0001', '3,41000000', '6,42000000', '20,00', 'PYJAMA BICOLOR', '', 'UNIT', '0', '', 'PRE0001', '', NULL),
('PAPI0001', 'PAPIER CADEAU ET ETIQUETTAGE', 'PRES0001', '1,25000000', '1,56000000', '20,00', 'PAPIER CADEAU ET ETIQUETTAGE', '', 'UNIT', '1', '', '', '', NULL),
('PARA0001', 'PARAPLUIE MYRTILLE', 'FILL0001', '11,00000000', '20,22000000', '20,00', 'PARAPLUIE MYRTILLE', '', 'UNIT', '0', '', 'POU0001', '', NULL),
('PEIG0001', 'PEIGNOIR DE BAINS', 'BEBE0001', '22,00000000', '41,39000000', '20,00', 'PEIGNOIR DE BAINS', '', 'UNIT', '0', '', 'PRE0001', '', NULL),
('PICT0001', 'JEUX DE CARTES', 'SOCI0001', '3,69000000', '6,91000000', '20,00', 'JEUX DE CARTES', '', 'UNIT', '0', '', 'VAR0001', '', NULL),
('PIRA0001', 'BATEAU PIRATE AVEC ACCESSOIRE', 'FIGU0001', '31,90000000', '59,77000000', '20,00', 'BATEAU PIRATE AVEC ACCESSOIRE', '', 'UNIT', '0', '', 'CON0001', '', NULL),
('POCH0001', 'POCHETTE SURPRISE 3€', 'ANNI0001', '2,51000000', '3,14000000', '20,00', 'POCHETTE SURPRISE 3 EUROS PAR ENFANT', '', 'PERS', '1', '', 'GOU0001', '', NULL),
('POCH0002', 'POCHETTE SURPRISE 6€', 'ANNI0001', '5,02000000', '6,28000000', '20,00', 'POCHETTE SURPRISE 6 EUROS PAR ENFANT', '', 'UNIT', '1', '', 'GOU0001', '', NULL),
('PORS0001', 'VOITURE TELECOMMANDEE', 'GARC0001', '22,00000000', '41,38000000', '20,00', 'VOITURE TELECOMMANDEE', '', 'UNIT', '0', '', 'JOU0001', 'D3E00028', NULL),
('POUP0001', 'POUPEE LILI', 'FILL0001', '14,85000000', '27,59000000', '20,00', 'POUPEE LILI', '', 'UNIT', '0', '', 'POU0001', '', NULL),
('POUP0002', 'POUPEE STELLA', 'FILL0001', '12,10000000', '22,52000000', '20,00', 'POUPEE STELLA', '', 'UNIT', '0', '', 'POU0001', '', NULL),
('POWE0001', 'LE BATEAU DE SURCOUF', 'FIGU0001', '38,50000000', '71,64000000', '20,00', 'LE BATEAU DE SURCOUF', '', 'UNIT', '0', '', 'CON0001', '', NULL),
('PS400001', 'CONSOLE DE JEUX SALON', 'MIXT0001', '137,50000000', '256,61000000', '20,00', 'CONSOLE DE JEUX SALON', '', 'UNIT', '0', '', 'PRE0001', 'D3E00027', NULL),
('PUZZ0001', 'PUZZLE ANIMAL 1000 PIECES', 'PUZZ0001', '7,15000000', '13,34000000', '20,00', 'PUZZLE ANIMAL 1000 PIECES', '', 'UNIT', '0', '', 'PUZ0001', '', NULL),
('PUZZ0002', 'PUZZLE THEME ASTROLOGIE 1000 PIECES', 'PUZZ0001', '6,93000000', '12,87000000', '20,00', 'PUZZLE THEME ASTROLOGIE 1000 PIECES', '', 'UNIT', '0', '', 'PUZ0001', '', NULL),
('PUZZ0003', 'PUZZLE THEME FANTASTIQUES 2000 PIECES', 'PUZZ0001', '13,64000000', '25,27000000', '20,00', 'PUZZLE THEME FANTASTIQUES 2000 PIECES', '', 'UNIT', '0', '', 'PUZ0001', '', NULL),
('PUZZ0004', 'PUZZLE THEME NATURE 1000 PIECES', 'PUZZ0001', '7,15000000', '13,34000000', '20,00', 'PUZZLE THEME NATURE 1000 PIECES', '', 'UNIT', '0', '', 'PUZ0001', '', NULL),
('PUZZ0005', 'PUZZLE MAGNETIQUE 60 PIECES', 'PUZZ0001', '5,94000000', '11,04000000', '20,00', 'PUZZLE MAGNETIQUE 60 PIECES', '', 'UNIT', '0', '', 'PUZ0001', '', NULL),
('QUEE0001', 'QUEEN MARY MAQUETTE ECHELLE 1:400', 'MAQU0001', '29,70000000', '55,17000000', '20,00', 'QUEEN MARY MAQUETTE ECHELLE 1:400', '', 'UNIT', '0', '', 'HIG0001', '', NULL),
('QUI00001', 'JEUX TELE', 'SOCI0001', '17,71000000', '33,10000000', '20,00', 'JEUX TELE', '', 'UNIT', '0', '', 'VAR0001', '', NULL),
('REFR0001', 'REFRIGERATEUR ', 'BOIS0001', '22,00000000', '41,30000000', '20,00', 'REFRIGERATEUR ', '', 'UNIT', '0', '', 'BOI0001', '', NULL),
('REPA0001', 'REPARATION FORFAITAIRE PRODUITS STANDARD: 14,80 € DE L\'HEURE', 'PRES0001', '12,37000000', '15,46000000', '20,00', 'REPARATION FORFAITAIRE PRODUITS STANDARD: 14,80 € DE L\'HEURE', '', 'HEUR', '1', '', '', '', NULL),
('REPA0002', 'REPARATION FORFAITAIRE PRODUITS TECHNIQUES: 20,50€ DE L\'HEURE', 'PRES0001', '17,14000000', '21,43000000', '20,00', 'REPARATION FORFAITAIRE PRODUITS TECHNIQUES: 20,50€ DE L\'HEURE', '', 'HEUR', '1', '', '', '', NULL),
('ROBO0001', 'ROBOTS TELECOMMANDES', 'GARC0001', '37,40000000', '69,89000000', '20,00', 'ROBOTS TELECOMMANDES', '', 'UNIT', '0', '', 'JOU0001', 'D3E00028', NULL),
('SAC00001', 'SAC DE VOYAGE', 'BEBE0001', '30,25000000', '56,09000000', '20,00', 'SAC DE VOYAGE', '', 'UNIT', '0', '', 'PRE0001', '', NULL),
('SAC00002', 'SAC A DOS SOUPLE ROUGE', 'FILL0001', '14,30000000', '26,58000000', '20,00', 'SAC A DOS SOUPLE ROUGE', '', 'UNIT', '0', '', 'POU0001', '', NULL),
('SAC00003', 'SAC A MAIN MYRTILLE DE LILI', 'FILL0001', '9,35000000', '17,46000000', '20,00', 'SAC A MAIN MYRTILLE DE LILI', '', 'UNIT', '0', '', 'POU0001', '', NULL),
('SALL0001', 'LANDAU POUR POUPEE', 'FILL0001', '22,00000000', '41,38000000', '20,00', 'LANDAU POUR POUPEE', '', 'UNIT', '0', '', 'POU0001', '', NULL),
('SALL0002', 'CHAISE HAUTE POUR POUPEE', 'FILL0001', '22,00000000', '41,38000000', '20,00', 'CHAISE HAUTE POUR POUPEE', '', 'UNIT', '0', '', 'POU0001', '', NULL),
('SALO0001', 'LANDAU BLEU/ROUGE', 'FILL0001', '63,80000000', '118,65000000', '20,00', 'LANDAU BLEU/ROUGE', '', 'UNIT', '0', '', 'POU0001', '', NULL),
('SCAR0001', 'JEUX DE REFLEXION', 'SOCI0001', '13,20000000', '24,83000000', '20,00', 'JEUX DE REFLEXION', '', 'UNIT', '0', '', 'VAR0001', '', NULL),
('SET00001', 'SET DE BAINS', 'BEBE0001', '14,85000000', '27,59000000', '20,00', 'SET DE BAINS', '', 'UNIT', '0', '', 'PRE0001', '', NULL),
('SET00002', 'SET MATERNITE BEIGE', 'BEBE0001', '22,55000000', '42,21000000', '20,00', 'SET MATERNITE BEIGE', '', 'UNIT', '0', '', 'PRE0001', '', NULL),
('SING0001', 'SINGE EN PELUCHE', 'PELU0001', '7,92000000', '14,71000000', '20,00', 'SINGE EN PELUCHE', '', 'UNIT', '0', '', 'PRI0001', '', NULL),
('SOUS0001', 'SOUS MARIN MAQUETTE ECHELLE 1:72 150 PIECES', 'MAQU0001', '29,70000000', '55,17000000', '20,00', 'SOUS MARIN MAQUETTE ECHELLE 1:72 150 PIECES', '', 'UNIT', '0', '', 'HIG0001', '', NULL),
('STAG0001', 'STAGE DE D\'EQUITATION 1 SEMAINE', 'ANIM0001', '260,87000000', '326,09000000', '20,00', 'STAGE DE D\'EQUITATION 1 SEMAINE  (5 JOURS]', '', 'SEMA', '1', '', '', '', NULL),
('STAG0002', 'STAGE DE VACANCES JOURNEE 9H - 17H', 'ANIM0001', '33,44000000', '41,80000000', '20,00', 'STAGE DE VACANCES JOURNEE 9H - 17H <br> UNE ANIMATION DIFFERENTES CHAQUE JOUR <br> (Cuisine, Bricolage, Création, Sculpture sur ballons, jeux olympiades, cluedo humain...)', '', 'JOUR', '1', '', '', '', NULL),
('STAG0003', 'STAGE DE VACANCES 1 SEMAINE', 'ANIM0001', '150,50000000', '188,13000000', '20,00', 'STAGE DE VACANCES 1 SEMAINE (5 JOURS) <br> UNE ANIMATION DIFFERENTE CHAQUE JOUR  <br> (Cuisine, Bricolage, Création, Sculpture sur ballons, jeux olympiades, cluedo humain...)', '', 'SEMA', '1', '', '', '', NULL),
('STAG0004', 'STAGE DE PONEY CLUB JOURNEE', 'ANIM0001', '16,72000000', '20,90000000', '20,00', 'STAGE DE PONEY CLUB JOURNEE : <br> - THEORIE, SOIN DES PONEYS, <br> - PROMENADE EN FORŹT, <br> - VOLTIGE, <br> - JEUX ÉQUESTRES, <br> - REPAS ET GOŪTER AU PONEY CLUB.', '', 'JOUR', '1', '', '', '', NULL),
('STAR0001', 'DINOSAURE BRACHIOSAURUS', 'FIGU0001', '9,35000000', '17,38000000', '20,00', 'DINOSAURE BRACHIOSAURUS', '', 'UNIT', '0', '', 'CON0001', '', NULL),
('STEG0001', 'STEGOSAUREUS', 'FIGU0001', '2,26000000', '4,24000000', '20,00', 'STEGOSAUREUS', '', 'UNIT', '0', '', 'CON0001', '', NULL),
('SUPE0001', 'MINI ROBOT REPTILE ELECTRONIQUE', 'GARC0001', '8,80000000', '16,54000000', '20,00', 'MINI ROBOT REPTILE ELECTRONIQUE', '', 'UNIT', '0', '', 'JOU0001', 'D3E00028', NULL),
('SUPE0002', 'SUPERCOPTERE MAQUETTE ECHELLE 1:48 75 PIECES', 'MAQU0001', '22,00000000', '41,30000000', '20,00', 'SUPERCOPTERE MAQUETTE ECHELLE 1:48 75 PIECES', '', 'UNIT', '0', '', 'HIG0001', '', NULL),
('T0CH0001', 'LES PREMIERS PAS DE BEBE', 'LIVR0001', '1,98000000', '3,67000000', '20,00', 'LES PREMIERS PAS DE BEBE', '', 'UNIT', '0', '', 'PRI0001', '', NULL),
('T0RE0001', 'T REX 3D LIVRE DE 6 A 9 ANS', 'LIVR0001', '6,44000000', '11,96000000', '20,00', 'T REX 3D LIVRE DE 6 A 9 ANS', '', 'UNIT', '0', '', 'PRI0001', '', NULL),
('TALK0001', 'TALKIE WALKIE PRO', 'GARC0001', '12,76000000', '23,90000000', '20,00', 'TALKIE WALKIE PRO', '', 'UNIT', '0', '', 'JOU0001', 'D3E00028', NULL),
('TAPI0001', 'TAPIS FLIC FLAC', 'BEBE0001', '29,92000000', '56,06000000', '20,00', 'TAPIS FLIC FLAC', '', 'UNIT', '0', '', 'PRE0001', '', NULL),
('TORT0001', 'POISSONS', 'FIGU0001', '2,42000000', '4,51000000', '20,00', 'POISSONS', '', 'UNIT', '0', '', 'CON0001', '', NULL),
('TOUR0001', 'TOURS DE LIT VELOURS', 'BEBE0001', '17,27000000', '32,19000000', '20,00', 'TOURS DE LIT VELOURS', '', 'UNIT', '0', '', 'PRE0001', '', NULL),
('TRAI0001', 'TRAINS ELECTRIQUES ', 'GARC0001', '32,56000000', '60,70000000', '20,00', 'TRAINS ELECTRIQUES ', '', 'UNIT', '0', '', 'JOU0001', 'D3E00028', NULL),
('TRAI0002', 'TRAIN EN BOIS ', 'BOIS0001', '12,32000000', '22,90000000', '20,00', 'TRAIN EN BOIS ', '', 'UNIT', '0', '', 'BOI0001', '', NULL),
('TRAI0003', 'TRAIN A ASSEMBLER ET TIRER', 'CONS0001', '8,36000000', '15,63000000', '20,00', 'TRAIN A ASSEMBLER ET TIRER', '', 'UNIT', '0', '', 'HAR0001', '', NULL),
('TRAN0001', 'COWBOY DEGAINANT', 'FIGU0001', '2,42000000', '4,51000000', '20,00', 'COWBOY DEGAINANT', '', 'UNIT', '0', '', 'CON0001', '', NULL),
('TRIV0001', 'JEUX D\'ECHECS CLASSIQUE', 'SOCI0001', '9,79000000', '18,30000000', '20,00', 'JEUX D\'ECHECS CLASSIQUE', '', 'UNIT', '0', '', 'VAR0001', '', NULL),
('TROU0001', 'TROUSSE DE TOILETTE VELOURS', 'BEBE0001', '12,76000000', '23,87000000', '20,00', 'TROUSSE DE TOILETTE VELOURS', '', 'UNIT', '0', '', 'PRE0001', '', NULL),
('TURB0001', 'PLANEUR ECHELLE 1:32 79 PIECES', 'MAQU0001', '8,80000000', '16,35000000', '20,00', 'PLANEUR ECHELLE 1:32 79 PIECES', '', 'UNIT', '0', '', 'HIG0001', '', NULL),
('VALI0001', 'VALISE POUPEE', 'FILL0001', '26,18000000', '48,65000000', '20,00', 'VALISE POUPEE', '', 'UNIT', '0', '', 'POU0001', '', NULL),
('VOIT0001', 'VOITURE DE SPORT TELECOMMANDEE', 'GARC0001', '29,59000000', '55,17000000', '20,00', 'VOITURE DE SPORT TELECOMMANDEE', '', 'UNIT', '0', '', 'JOU0001', 'D3E00028', NULL),
('VOIT0002', 'VOITURES DE COURSE 700 PIECES', 'PUZZ0001', '9,35000000', '17,47000000', '20,00', 'VOITURES DE COURSE 700 PIECES', '', 'UNIT', '0', '', 'PUZ0001', '', NULL);

-- --------------------------------------------------------

--
-- Structure de la table `export_clients`
--

CREATE TABLE `export_clients` (
  `Code (tiers)` varchar(8) DEFAULT NULL,
  `Civilité` varchar(12) DEFAULT NULL,
  `Nom` varchar(28) DEFAULT NULL,
  `Code Famille` varchar(6) DEFAULT NULL,
  `Libellé` varchar(20) DEFAULT NULL,
  `Code sous-famille client` varchar(10) DEFAULT NULL,
  `Libellé sous-famille client` varchar(10) DEFAULT NULL,
  `Personne physique` int(1) DEFAULT NULL,
  `Statut` varchar(1) DEFAULT NULL,
  `Adresse 1 (facturation)` varchar(33) DEFAULT NULL,
  `Adresse 2 (facturation)` varchar(10) DEFAULT NULL,
  `Adresse 3 (facturation)` varchar(10) DEFAULT NULL,
  `Adresse 4 (facturation)` varchar(10) DEFAULT NULL,
  `Code postal (facturation)` varchar(5) DEFAULT NULL,
  `Ville (facturation)` varchar(26) DEFAULT NULL,
  `Département (facturation)` varchar(14) DEFAULT NULL,
  `Code Pays (facturation)` varchar(2) DEFAULT NULL,
  `Site Web (facturation)` varchar(10) DEFAULT NULL,
  `Civilité (contact) (facturation)` varchar(12) DEFAULT NULL,
  `Nom (contact) (facturation)` varchar(9) DEFAULT NULL,
  `Prénom (facturation)` varchar(13) DEFAULT NULL,
  `Fonction (facturation)` varchar(10) DEFAULT NULL,
  `Service/Bureau (facturation)` varchar(10) DEFAULT NULL,
  `Téléphone fixe (facturation)` varchar(15) DEFAULT NULL,
  `Téléphone portable (facturation)` varchar(14) DEFAULT NULL,
  `Fax (facturation)` varchar(10) DEFAULT NULL,
  `E-mail (facturation)` varchar(26) DEFAULT NULL,
  `Civilité (adresse) (livraison)` varchar(12) DEFAULT NULL,
  `Nom (adresse) (livraison)` varchar(28) DEFAULT NULL,
  `Adresse 1 (livraison)` varchar(33) DEFAULT NULL,
  `Adresse 2 (livraison)` varchar(10) DEFAULT NULL,
  `Adresse 3 (livraison)` varchar(10) DEFAULT NULL,
  `Adresse 4 (livraison)` varchar(10) DEFAULT NULL,
  `Code postal (livraison)` varchar(5) DEFAULT NULL,
  `Ville (livraison)` varchar(26) DEFAULT NULL,
  `Département (livraison)` varchar(14) DEFAULT NULL,
  `Code Pays (livraison)` varchar(2) DEFAULT NULL,
  `Site Web (livraison)` varchar(10) DEFAULT NULL,
  `Civilité (contact) (livraison)` varchar(12) DEFAULT NULL,
  `Nom (contact) (livraison)` varchar(9) DEFAULT NULL,
  `Prénom (livraison)` varchar(13) DEFAULT NULL,
  `Fonction (livraison)` varchar(10) DEFAULT NULL,
  `Service/Bureau (livraison)` varchar(10) DEFAULT NULL,
  `Téléphone fixe (livraison)` varchar(15) DEFAULT NULL,
  `Téléphone portable (livraison)` varchar(14) DEFAULT NULL,
  `Fax (livraison)` varchar(10) DEFAULT NULL,
  `E-mail (livraison)` varchar(26) DEFAULT NULL,
  `Compte comptable` varchar(10) DEFAULT NULL,
  `% remise` int(1) DEFAULT NULL,
  `Encours autorisé` int(1) DEFAULT NULL,
  `Solde initial` int(1) DEFAULT NULL,
  `Date de premičre facture` varchar(10) DEFAULT NULL,
  `Code mode de rčglement` varchar(10) DEFAULT NULL,
  `Date de paiement` varchar(10) DEFAULT NULL,
  `Code territorialité` varchar(6) DEFAULT NULL,
  `Siren` varchar(10) DEFAULT NULL,
  `Code NAF` varchar(10) DEFAULT NULL,
  `Numéro de TVA intracommunautaire` varchar(10) DEFAULT NULL,
  `Notes en texte brut` varchar(10) DEFAULT NULL,
  `Libellé du mode rčglement` varchar(10) DEFAULT NULL,
  `Libellé du code NAF` varchar(10) DEFAULT NULL,
  `Est la banque principale` varchar(10) DEFAULT NULL,
  `Libellé de la banque` varchar(10) DEFAULT NULL,
  `Code pays de la banque` varchar(10) DEFAULT NULL,
  `Domiciliation 1 de la banque` varchar(10) DEFAULT NULL,
  `Domiciliation 2 de la banque` varchar(10) DEFAULT NULL,
  `Domiciliation 3 de la banque` varchar(10) DEFAULT NULL,
  `RIB / BBAN` varchar(10) DEFAULT NULL,
  `BIC` varchar(10) DEFAULT NULL,
  `IBAN` varchar(10) DEFAULT NULL,
  `Code de la catégorie tarifaire` varchar(10) DEFAULT NULL,
  `Libellé de la catégorie tarifaire` varchar(10) DEFAULT NULL,
  `Code commercial/collaborateur` varchar(7) DEFAULT NULL,
  `Nom du commercial/collaborateur` varchar(7) DEFAULT NULL,
  `% Remise 2` int(1) DEFAULT NULL,
  `% escompte` int(1) DEFAULT NULL,
  `Date de derničre facturation` varchar(10) DEFAULT NULL,
  `Type de tiers` varchar(1) DEFAULT NULL,
  `Facturation TTC` int(1) DEFAULT NULL,
  `Code frais de port` varchar(10) DEFAULT NULL,
  `Client en compte` int(1) DEFAULT NULL,
  `Type d'envoi des contacts sur le web` varchar(5) DEFAULT NULL,
  `Référence unique du mandat SEPA` varchar(10) DEFAULT NULL,
  `Date de signature du mandat SEPA` varchar(10) DEFAULT NULL,
  `Séquence de présentation SEPA` varchar(10) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Déchargement des données de la table `export_clients`
--

INSERT INTO `export_clients` (`Code (tiers)`, `Civilité`, `Nom`, `Code Famille`, `Libellé`, `Code sous-famille client`, `Libellé sous-famille client`, `Personne physique`, `Statut`, `Adresse 1 (facturation)`, `Adresse 2 (facturation)`, `Adresse 3 (facturation)`, `Adresse 4 (facturation)`, `Code postal (facturation)`, `Ville (facturation)`, `Département (facturation)`, `Code Pays (facturation)`, `Site Web (facturation)`, `Civilité (contact) (facturation)`, `Nom (contact) (facturation)`, `Prénom (facturation)`, `Fonction (facturation)`, `Service/Bureau (facturation)`, `Téléphone fixe (facturation)`, `Téléphone portable (facturation)`, `Fax (facturation)`, `E-mail (facturation)`, `Civilité (adresse) (livraison)`, `Nom (adresse) (livraison)`, `Adresse 1 (livraison)`, `Adresse 2 (livraison)`, `Adresse 3 (livraison)`, `Adresse 4 (livraison)`, `Code postal (livraison)`, `Ville (livraison)`, `Département (livraison)`, `Code Pays (livraison)`, `Site Web (livraison)`, `Civilité (contact) (livraison)`, `Nom (contact) (livraison)`, `Prénom (livraison)`, `Fonction (livraison)`, `Service/Bureau (livraison)`, `Téléphone fixe (livraison)`, `Téléphone portable (livraison)`, `Fax (livraison)`, `E-mail (livraison)`, `Compte comptable`, `% remise`, `Encours autorisé`, `Solde initial`, `Date de premičre facture`, `Code mode de rčglement`, `Date de paiement`, `Code territorialité`, `Siren`, `Code NAF`, `Numéro de TVA intracommunautaire`, `Notes en texte brut`, `Libellé du mode rčglement`, `Libellé du code NAF`, `Est la banque principale`, `Libellé de la banque`, `Code pays de la banque`, `Domiciliation 1 de la banque`, `Domiciliation 2 de la banque`, `Domiciliation 3 de la banque`, `RIB / BBAN`, `BIC`, `IBAN`, `Code de la catégorie tarifaire`, `Libellé de la catégorie tarifaire`, `Code commercial/collaborateur`, `Nom du commercial/collaborateur`, `% Remise 2`, `% escompte`, `Date de derničre facturation`, `Type de tiers`, `Facturation TTC`, `Code frais de port`, `Client en compte`, `Type d'envoi des contacts sur le web`, `Référence unique du mandat SEPA`, `Date de signature du mandat SEPA`, `Séquence de présentation SEPA`) VALUES
('MAS0002', 'Monsieur', 'MASSIN Olivier', 'PA0001', 'Particuliers', '', '', 1, 'A', '6 rue de travy', '', '', '', '94320', 'THIAIS', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', '', '', '', '', 'Monsieur', 'MASSIN Olivier', '6 rue de travy', '', '', '', '94320', 'THIAIS', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', '', '', '', '', '411MAS0002', 0, 0, 0, '28/01/2018', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00001', 'Durand', 0, 0, '', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('MAR0002', 'Monsieur', 'MARTIN Eric', 'PA0001', 'Particuliers', '', '', 1, 'A', '52 rue pasteur', '', '', '', '94120', 'FONTENAY SOUS BOIS', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', '', '', '', '', 'Monsieur', 'MARTIN Eric', '52 rue pasteur', '', '', '', '94120', 'FONTENAY SOUS BOIS', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', '', '', '', '', '411MAR0002', 0, 0, 0, '08/07/2017', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00002', 'Noirlan', 0, 0, '08/07/2017', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('MOL0001', 'Monsieur', 'MOLINA Franēois', 'PA0001', 'Particuliers', '', '', 1, 'A', '43 rue de taverny', '', '', '', '95130', 'FRANCONVILLE LA GARENNE', 'VAL-D\'OISE', 'FR', '', 'Monsieur', 'MOLINA', 'Franēois', '', '', '01  55 66 99 88', '', '', '', 'Monsieur', 'MOLINA Franēois', '43 rue de taverny', '', '', '', '95130', 'FRANCONVILLE LA GARENNE', 'VAL-D\'OISE', 'FR', '', 'Monsieur', 'MOLINA', 'Franēois', '', '', '01  55 66 99 88', '', '', '', '411MOL0001', 0, 0, 0, '08/07/2017', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00001', 'Durand', 0, 0, '08/07/2017', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('CL00001', 'Madame', 'MOLINA Sandrine', 'PA0001', 'Particuliers', '', '', 1, 'A', '10 avenue du Général de Gaulle', '', '', '', '75011', 'PARIS 11EME ARRONDISSEMENT', 'PARIS', 'FR', '', '', '', '', '', '', '', '', '', '', 'Madame', 'MOLINA Sandrine', '10 avenue du Général de Gaulle', '', '', '', '75011', 'PARIS 11EME ARRONDISSEMENT', 'PARIS', 'FR', '', '', '', '', '', '', '', '', '', '', '411CL00001', 0, 0, 0, '28/01/2018', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00002', 'Noirlan', 0, 0, '', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('POR0001', 'Monsieur', 'PORTIER Stéphane', 'PA0001', 'Particuliers', '', '', 1, 'A', '62 rue de france', '', '', '', '77300', 'FONTAINEBLEAU', 'SEINE-ET-MARNE', 'FR', '', '', '', '', '', '', '', '', '', '', 'Monsieur', 'PORTIER Stéphane', '62 rue de france', '', '', '', '77300', 'FONTAINEBLEAU', 'SEINE-ET-MARNE', 'FR', '', '', '', '', '', '', '', '', '', '', '411POR0001', 0, 0, 0, '28/01/2018', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00001', 'Durand', 0, 0, '', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('CCL00003', '', 'ECCA SARL', '', '', '', '', 1, 'A', '', '', '', '', '', '', '', 'FR', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'FR', '', '', '', '', '', '', '', '', '', '', '411ECCA', 0, 0, 0, '18/04/2018', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00002', 'Noirlan', 0, 0, '07/12/2024', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('VAN0001', 'Monsieur', 'VANNIER Yvan', 'PA0001', 'Particuliers', '', '', 1, 'A', '9 RUE PAUL LOUIS COURRIER', '', '', '', '77100', 'MEAUX', 'SEINE-ET-MARNE', 'FR', '', '', '', '', '', '', '', '', '', '', 'Monsieur', 'VANNIER Yvan', '9 RUE PAUL LOUIS COURRIER', '', '', '', '77100', 'MEAUX', 'SEINE-ET-MARNE', 'FR', '', '', '', '', '', '', '', '', '', '', '411VAN0001', 0, 0, 0, '08/07/2017', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00002', 'Noirlan', 0, 0, '08/07/2017', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('VOI0001', 'Monsieur', 'VOISINA Eric', 'PA0001', 'Particuliers', '', '', 1, 'A', '17 rue de l\'assomption', '', '', '', '75016', 'PARIS 16EME ARRONDISSEMENT', 'PARIS', 'FR', '', '', '', '', '', '', '', '', '', '', 'Monsieur', 'VOISINA Eric', '17 rue de l\'assomption', '', '', '', '75016', 'PARIS 16EME ARRONDISSEMENT', 'PARIS', 'FR', '', '', '', '', '', '', '', '', '', '', '411VOI0001', 0, 0, 0, '28/01/2018', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00001', 'Durand', 0, 0, '', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('LAM0001', 'Mademoiselle', 'LAMBERT Stéphanie', 'PA0001', 'Particuliers', '', '', 1, 'A', '3 IMPASSE DE LA CISERAIE', '', '', '', '91120', 'PALAISEAU', 'ESSONNE', 'FR', '', 'Mademoiselle', 'LAMBERT', 'Stéphanie', '', '', '', '', '', 'lambert.stephanie@free.fr', 'Mademoiselle', 'LAMBERT Stéphanie', '3 IMPASSE DE LA CISERAIE', '', '', '', '91120', 'PALAISEAU', 'ESSONNE', 'FR', '', 'Mademoiselle', 'LAMBERT', 'Stéphanie', '', '', '', '', '', 'lambert.stephanie@free.fr', '411LAM0001', 0, 0, 0, '08/07/2017', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00001', 'Durand', 0, 0, '08/07/2017', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('KAL0001', 'Monsieur', 'KALOU André', 'PA0001', 'Particuliers', '', '', 1, 'A', '105 Boulevard john kennedy', '', '', '', '91100', 'CORBEIL ESSONNES', 'ESSONNE', 'FR', '', 'Monsieur', 'KALOU', 'André', '', '', '01.65.85.74.45', '06.25.78.95.45', '', '', 'Monsieur', 'KALOU André', '105 Boulevard john kennedy', '', '', '', '91100', 'CORBEIL ESSONNES', 'ESSONNE', 'FR', '', 'Monsieur', 'KALOU', 'André', '', '', '01.65.85.74.45', '06.25.78.95.45', '', '', '411KAL0001', 0, 0, 0, '28/01/2018', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00002', 'Noirlan', 0, 0, '', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('SAN0001', 'Madame', 'SANDYA Céline', 'PA0001', 'Particuliers', '', '', 1, 'A', '53 rue de babylone', '', '', '', '75007', 'PARIS 7EME ARRONDISSEMENT', 'PARIS', 'FR', '', '', '', '', '', '', '', '', '', '', 'Madame', 'SANDYA Céline', '53 rue de babylone', '', '', '', '75007', 'PARIS 7EME ARRONDISSEMENT', 'PARIS', 'FR', '', '', '', '', '', '', '', '', '', '', '411SAN0001', 0, 0, 0, '28/01/2018', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00002', 'Noirlan', 0, 0, '', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('MUL0001', 'Monsieur', 'MULMERSON ED', 'PA0001', 'Particuliers', '', '', 1, 'A', '242 avenue jean jaures', '', '', '', '95100', 'ARGENTEUIL', 'VAL-D\'OISE', 'FR', '', 'Monsieur', 'MULMERSON', ' Ed', '', '', '', '', '', 'mulmerson.ed@free.fr', 'Monsieur', 'MULMERSON ED', '242 avenue jean jaures', '', '', '', '95100', 'ARGENTEUIL', 'VAL-D\'OISE', 'FR', '', 'Monsieur', 'MULMERSON', ' Ed', '', '', '', '', '', 'mulmerson.ed@free.fr', '411MUL0001', 0, 0, 0, '28/01/2018', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00002', 'Noirlan', 0, 0, '', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('LOR0001', 'Madame', 'LORENT ALINE', 'PA0001', 'Particuliers', '', '', 1, 'A', '7 rue lambert', '', '', '', '91410', 'DOURDAN', 'ESSONNE', 'FR', '', '', '', '', '', '', '', '', '', '', 'Madame', 'LORENT ALINE', '7 rue lambert', '', '', '', '91410', 'DOURDAN', 'ESSONNE', 'FR', '', '', '', '', '', '', '', '', '', '', '411LOR0001', 0, 0, 0, '28/01/2018', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00002', 'Noirlan', 0, 0, '', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('BDM0001', 'CE', 'BDMANIA', 'CE0001', 'Comités d\'entreprise', '', '', 1, 'A', '17 rue Centrale', '', '', '', '1200', 'BELLEGARDE SUR VALSERINE', 'AIN', 'FR', '', '', '', '', '', '', '', '', '', '', 'CE', 'BDMANIA', '17 rue Centrale', '', '', '', '1200', 'BELLEGARDE SUR VALSERINE', 'AIN', 'FR', '', '', '', '', '', '', '', '', '', '', '411BDM0001', 0, 0, 0, '08/07/2017', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00001', 'Durand', 0, 0, '18/04/2018', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('MAR0003', 'Madame', 'MARCHAND Danielle', 'PA0001', 'Particuliers', '', '', 1, 'A', '40 RUE CARNOT', '', '', '', '94270', 'LE KREMLIN BICETRE', 'VAL-DE-MARNE', 'FR', '', 'Madame', 'MARCHAND', 'Danielle', '', '', '', '', '', 'marchand.danielle@aol.fr', 'Madame', 'MARCHAND Danielle', '40 RUE CARNOT', '', '', '', '94270', 'LE KREMLIN BICETRE', 'VAL-DE-MARNE', 'FR', '', 'Madame', 'MARCHAND', 'Danielle', '', '', '', '', '', 'marchand.danielle@aol.fr', '411MAR0003', 0, 0, 0, '08/07/2017', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00001', 'Durand', 0, 0, '', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('JAR0001', 'Mademoiselle', 'JAREAU Claire', 'PA0001', 'Particuliers', '', '', 1, 'A', '16 rue de l\'abreuvoir', '', '', '', '78920', 'ECQUEVILLY', 'YVELINES', 'FR', '', '', '', '', '', '', '', '', '', '', 'Mademoiselle', 'JAREAU Claire', '16 rue de l\'abreuvoir', '', '', '', '78920', 'ECQUEVILLY', 'YVELINES', 'FR', '', '', '', '', '', '', '', '', '', '', '411JAR0001', 0, 0, 0, '07/07/2017', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00001', 'Durand', 0, 0, '', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('CCL00006', '', 'TONIER', '', '', '', '', 1, 'A', '159 Boulevard de Créteil', '', '', '', '94100', 'ST MAUR DES FOSSES', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', '', '', '', '', '', '', '159 Boulevard de Créteil', '', '', '', '94100', 'ST MAUR DES FOSSES', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', '', '', '', '', '411TONIER', 0, 0, 0, '18/04/2018', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00001', 'Durand', 0, 0, '18/04/2018', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('PET0001', 'CE', 'PETIT LOUP', 'CE0001', 'Comités d\'entreprise', '', '', 1, 'A', '178 avenue des Landes', '', '', '', '95000', 'NEUVILLE SUR OISE', 'VAL-D\'OISE', 'FR', '', '', '', '', '', '', '', '', '', '', 'CE', 'PETIT LOUP', '178 avenue des Landes', '', '', '', '95000', 'NEUVILLE SUR OISE', 'VAL-D\'OISE', 'FR', '', '', '', '', '', '', '', '', '', '', '411PET0001', 0, 0, 0, '08/07/2017', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00002', 'Noirlan', 0, 0, '08/07/2017', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('VOI0003', 'Madame', 'VINET Francine', '', '', '', '', 1, 'A', '1 Rue de boisse', '', '', '', '95000', 'CERGY', 'VAL-D\'OISE', 'FR', '', '', '', '', '', '', '', '', '', '', 'Madame', 'VINET Francine', '1 Rue de boisse', '', '', '', '95000', 'CERGY', 'VAL-D\'OISE', 'FR', '', '', '', '', '', '', '', '', '', '', '411VOI0003', 0, 0, 0, '28/01/2018', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00001', 'Durand', 0, 0, '', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('CL00002', 'Madame', 'TARDIEU Antoinette', 'PA0001', 'Particuliers', '', '', 1, 'A', '11 Avenue du coin du bois', '', '', '', '95000', 'BOISEMONT', 'VAL-D\'OISE', 'FR', '', '', '', '', '', '', '', '', '', '', 'Madame', 'TARDIEU Antoinette', '11 Avenue du coin du bois', '', '', '', '95000', 'BOISEMONT', 'VAL-D\'OISE', 'FR', '', '', '', '', '', '', '', '', '', '', '411CL00002', 0, 0, 0, '28/01/2018', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00001', 'Durand', 0, 0, '', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('ORM0001', 'Monsieur', 'ORMONT PAUL', 'PA0001', 'Particuliers', '', '', 1, 'A', '10 BIS RUE SAINTE HONORINE', '', '', '', '95150', 'TAVERNY', 'VAL-D\'OISE', 'FR', '', 'Monsieur', 'ORMONT', 'PAUL', '', '', '', '', '', 'ormont.paul@yahoo.fr', 'Monsieur', 'ORMONT PAUL', '10 BIS RUE SAINTE HONORINE', '', '', '', '95150', 'TAVERNY', 'VAL-D\'OISE', 'FR', '', 'Monsieur', 'ORMONT', 'PAUL', '', '', '', '', '', 'ormont.paul@yahoo.fr', '411ORM0001', 0, 0, 0, '28/01/2018', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00001', 'Durand', 0, 0, '', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('CCL00004', '', 'GESPI', '', '', '', '', 1, 'A', '28 rue de la Fontaine de l\'Yvette', '', '', '', '91140', 'VILLEBON SUR YVETTE', 'ESSONNE', 'FR', '', '', '', '', '', '', '', '', '', '', '', '', '28 rue de la Fontaine de l\'Yvette', '', '', '', '91140', 'VILLEBON SUR YVETTE', 'ESSONNE', 'FR', '', '', '', '', '', '', '', '', '', '', '411GESPI', 0, 0, 0, '18/04/2018', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00001', 'Durand', 0, 0, '18/04/2018', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('CCL00002', '', 'Clients et comptes rattachés', '', '', '', '', 1, 'A', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'Clients et comptes rattachés', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '410', 0, 0, 0, '', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 0, 0, '', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('LEG0001', 'Monsieur', 'LEGENNEC Yannick', 'PA0001', 'Particuliers', '', '', 1, 'A', '28 Rue de la fontaine de l\'yvette', '', '', '', '91140', 'VILLEBON SUR YVETTE', 'ESSONNE', 'FR', '', '', '', '', '', '', '', '', '', '', 'Monsieur', 'LEGENNEC Yannick', '28 Rue de la fontaine de l\'yvette', '', '', '', '91140', 'VILLEBON SUR YVETTE', 'ESSONNE', 'FR', '', '', '', '', '', '', '', '', '', '', '411LEG0001', 0, 0, 0, '28/01/2018', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00001', 'Durand', 0, 0, '', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('MAR0004', 'Madame', 'MARTINEAU Laura', 'PA0001', 'Particuliers', '', '', 1, 'A', '15 rue de l\'yser', '', '', '', '94400', 'VITRY SUR SEINE', 'VAL-DE-MARNE', 'FR', '', 'Madame', 'MARTINEAU', 'Laura', '', '', '', '', '', 'martineau.laura@aol.fr', 'Madame', 'MARTINEAU Laura', '15 rue de l\'yser', '', '', '', '94400', 'VITRY SUR SEINE', 'VAL-DE-MARNE', 'FR', '', 'Madame', 'MARTINEAU', 'Laura', '', '', '', '', '', 'martineau.laura@aol.fr', '411MAR0004', 0, 0, 0, '08/07/2017', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00002', 'Noirlan', 0, 0, '08/07/2017', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('GOU0001', 'Madame', 'GOUJUS Alexandra', 'PA0001', 'Particuliers', '', '', 1, 'A', 'avenue des freres lumiere', '', '', '', '78190', 'TRAPPES', 'YVELINES', 'FR', '', 'Madame', 'GOUJUS', 'Alexandra', '', '', '', '', '', 'goujus.alexandra@free.fr', 'Madame', 'GOUJUS Alexandra', 'avenue des freres lumiere', '', '', '', '78190', 'TRAPPES', 'YVELINES', 'FR', '', 'Madame', 'GOUJUS', 'Alexandra', '', '', '', '', '', 'goujus.alexandra@free.fr', '411GOU0001', 0, 0, 0, '28/01/2018', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00002', 'Noirlan', 0, 0, '', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('STA0001', 'Mademoiselle', 'STANLAB Emilie', 'PA0001', 'Particuliers', '', '', 1, 'A', '21 rue du renard', '', '', '', '75004', 'PARIS 4EME ARRONDISSEMENT', 'PARIS', 'FR', '', '', '', '', '', '', '', '', '', '', 'Mademoiselle', 'STANLAB Emilie', '21 rue du renard', '', '', '', '75004', 'PARIS 4EME ARRONDISSEMENT', 'PARIS', 'FR', '', '', '', '', '', '', '', '', '', '', '411STA0001', 0, 0, 0, '08/07/2017', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00001', 'Durand', 0, 0, '08/07/2017', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('VOI0002', 'Madame', 'VERRON Brigitte', 'PA0001', 'Particuliers', '', '', 1, 'A', '11 Avenue du coin du bois', '', '', '', '78120', 'Rambouillet', '78', 'FR', '', '', '', '', '', '', '', '', '', '', 'Madame', 'VERRON Brigitte', '11 Avenue du coin du bois', '', '', '', '78120', 'Rambouillet', '78', 'FR', '', '', '', '', '', '', '', '', '', '', '411VOI0002', 0, 0, 0, '28/01/2018', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00002', 'Noirlan', 0, 0, '', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('TUL0001', 'Mademoiselle', 'TULIA Sophie', 'PA0001', 'Particuliers', '', '', 1, 'A', '4 RUE ABEL', '', '', '', '75012', 'PARIS 12EME ARRONDISSEMENT', 'PARIS', 'FR', '', '', '', '', '', '', '', '', '', '', 'Mademoiselle', 'TULIA Sophie', '4 RUE ABEL', '', '', '', '75012', 'PARIS 12EME ARRONDISSEMENT', 'PARIS', 'FR', '', '', '', '', '', '', '', '', '', '', '411TUL0001', 0, 0, 0, '28/01/2018', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00001', 'Durand', 0, 0, '', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('CCL00005', '', 'PICOSO', '', '', '', '', 1, 'A', '7 rue Lambert', '', '', '', '91410', 'DOURDAN', 'ESSONNE', 'FR', '', '', '', '', '', '', '', '', '', '', '', '', '7 rue Lambert', '', '', '', '91410', 'DOURDAN', 'ESSONNE', 'FR', '', '', '', '', '', '', '', '', '', '', '411PICOSO', 0, 0, 0, '', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00002', 'Noirlan', 0, 0, '', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('MET0001', 'Madame', 'METALLIN Elodie', 'PA0001', 'Particuliers', '', '', 1, 'A', '3 allée charles V', '', '', '', '94300', 'VINCENNES', '', 'FR', '', 'Madame', 'METALLIN', 'Elodie', '', '', '', '', '', 'metallin.elodie@alice.fr', 'Madame', 'METALLIN Elodie', '3 allée charles V', '', '', '', '94300', 'VINCENNES', '', 'FR', '', 'Madame', 'METALLIN', 'Elodie', '', '', '', '', '', 'metallin.elodie@alice.fr', '411MET0001', 0, 0, 0, '28/01/2018', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00002', 'Noirlan', 0, 0, '', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('RIN0001', 'Mademoiselle', 'RINGUAI Nathalie', 'PA0001', 'Particuliers', '', '', 1, 'A', '37 rue des archives', '', '', '', '75003', 'PARIS 3EME ARRONDISSEMENT', 'PARIS', 'FR', '', 'Mademoiselle', 'RINGUAI', 'Nathalie', '', '', '', '', '', 'ringuai.nathalie@orange.fr', 'Mademoiselle', 'RINGUAI Nathalie', '37 rue des archives', '', '', '', '75003', 'PARIS 3EME ARRONDISSEMENT', 'PARIS', 'FR', '', 'Mademoiselle', 'RINGUAI', 'Nathalie', '', '', '', '', '', 'ringuai.nathalie@orange.fr', '411RIN0001', 0, 0, 0, '08/07/2017', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00002', 'Noirlan', 0, 0, '08/07/2017', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('CL00003', 'Madame', 'RAVIN Odile', 'PA0001', 'Particuliers', '', '', 1, 'A', '5 rue Mond', '', '', '', '93000', 'BOBIGNY', 'SEINE-ST-DENIS', 'FR', '', '', '', '', '', '', '', '', '', '', 'Madame', 'RAVIN Odile', '5 rue Mond', '', '', '', '93000', 'BOBIGNY', 'SEINE-ST-DENIS', 'FR', '', '', '', '', '', '', '', '', '', '', '411CL00003', 0, 0, 0, '07/07/2017', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00002', 'Noirlan', 0, 0, '08/07/2017', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('MAR0001', 'Monsieur', 'MARTIN Jean-Paul', 'PA0001', 'Particuliers', '', '', 1, 'A', '159 boulevard de creteil', '', '', '', '94100', 'SAINT MAUR DES FOSSES', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', '', '', '', '', 'Monsieur', 'MARTIN Jean-Paul', '159 boulevard de creteil', '', '', '', '94100', 'SAINT MAUR DES FOSSES', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', '', '', '', '', '411MAR0001', 0, 0, 0, '28/01/2018', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00001', 'Durand', 0, 0, '', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('LEC0001', 'Ce', 'LECTURA', 'CE0001', 'Comités d\'entreprise', '', '', 1, 'A', '49 square Diderot', '', '', '', '91000', 'EVRY', 'ESSONNE', 'FR', '', '', '', '', '', '', '', '', '', '', 'Ce', 'LECTURA', '49 square Diderot', '', '', '', '91000', 'EVRY', 'ESSONNE', 'FR', '', '', '', '', '', '', '', '', '', '', '411LEC0001', 0, 0, 0, '08/07/2017', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00002', 'Noirlan', 0, 0, '08/07/2017', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('TOR0001', 'Madame', 'TORRES Odile', 'PA0001', 'Particuliers', '', '', 1, 'A', '137 BOULEVARD SAINT MICHEL', '', '', '', '75005', 'PARIS 5EME ARRONDISSEMENT', 'PARIS', 'FR', '', '', '', '', '', '', '', '', '', '', 'Madame', 'TORRES Odile', '137 BOULEVARD SAINT MICHEL', '', '', '', '75005', 'PARIS 5EME ARRONDISSEMENT', 'PARIS', 'FR', '', '', '', '', '', '', '', '', '', '', '411TOR0001', 0, 0, 0, '28/01/2018', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00002', 'Noirlan', 0, 0, '', 'C', 0, '', 0, 'AUCUN', '', '', ''),
('ROQ0001', 'Monsieur', 'ROQUES Jean-Philippe', 'PA0001', 'Particuliers', '', '', 1, 'A', '23 rue d\'antin', '', '', '', '75002', 'PARIS 2EME ARRONDISSEMENT', 'PARIS', 'FR', '', 'Monsieur', 'ROQUES', 'Jean-Philippe', '', '', '', '', '', 'roques.jp@yahoo.fr', 'Monsieur', 'ROQUES Jean-Philippe', '23 rue d\'antin', '', '', '', '75002', 'PARIS 2EME ARRONDISSEMENT', 'PARIS', 'FR', '', 'Monsieur', 'ROQUES', 'Jean-Philippe', '', '', '', '', '', 'roques.jp@yahoo.fr', '411ROQ0001', 0, 0, 0, '28/01/2018', '', '', 'FRANCE', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'CO00001', 'Durand', 0, 0, '', 'C', 0, '', 0, 'AUCUN', '', '', '');

-- --------------------------------------------------------

--
-- Structure de la table `export_devis`
--

CREATE TABLE `export_devis` (
  `Acompte - Montant de l'acompte` int(1) DEFAULT NULL,
  `Document - Numéro du document` varchar(12) DEFAULT NULL,
  `Document - Date` varchar(10) DEFAULT NULL,
  `Document - Code client` varchar(8) DEFAULT NULL,
  `Document - Civilité` varchar(8) DEFAULT NULL,
  `Document - Nom du client` varchar(11) DEFAULT NULL,
  `Document - Adresse 1 (facturation)` varchar(15) DEFAULT NULL,
  `Document - Adresse 2 (facturation)` varchar(10) DEFAULT NULL,
  `Document - Adresse 3 (facturation)` varchar(10) DEFAULT NULL,
  `Document - Adresse 4 (facturation)` varchar(10) DEFAULT NULL,
  `Document - Code postal (facturation)` int(5) DEFAULT NULL,
  `Document - Ville (facturation)` varchar(24) DEFAULT NULL,
  `Document - Département (facturation)` varchar(14) DEFAULT NULL,
  `Document - Code Pays (facturation)` varchar(2) DEFAULT NULL,
  `Document - Nom (contact) (facturation)` varchar(10) DEFAULT NULL,
  `Document - Prénom (facturation)` varchar(10) DEFAULT NULL,
  `Document - Téléphone fixe (facturation)` varchar(10) DEFAULT NULL,
  `Document - Téléphone portable (facturation)` varchar(10) DEFAULT NULL,
  `Document - Fax (facturation)` varchar(10) DEFAULT NULL,
  `Document - E-mail (facturation)` varchar(10) DEFAULT NULL,
  `Document - Nom (adresse) (livraison)` varchar(11) DEFAULT NULL,
  `Document - Civilité (adresse) (livraison)` varchar(8) DEFAULT NULL,
  `Document - Adresse 1 (livraison)` varchar(15) DEFAULT NULL,
  `Document - Adresse 2 (livraison)` varchar(10) DEFAULT NULL,
  `Document - Adresse 3 (livraison)` varchar(10) DEFAULT NULL,
  `Document - Adresse 4 (livraison)` varchar(10) DEFAULT NULL,
  `Document - Code postal (livraison)` int(5) DEFAULT NULL,
  `Document - Ville (livraison)` varchar(24) DEFAULT NULL,
  `Document - Département (livraison)` varchar(14) DEFAULT NULL,
  `Document - Code Pays (livraison)` varchar(2) DEFAULT NULL,
  `Document - Nom (contact) (livraison)` varchar(10) DEFAULT NULL,
  `Document - Prénom (livraison)` varchar(10) DEFAULT NULL,
  `Document - Téléphone fixe (livraison)` varchar(10) DEFAULT NULL,
  `Document - Téléphone portable (livraison)` varchar(10) DEFAULT NULL,
  `Document - Fax (livraison)` varchar(10) DEFAULT NULL,
  `Document - E-mail (livraison)` varchar(10) DEFAULT NULL,
  `Document - Territorialité` varchar(6) DEFAULT NULL,
  `Document - Numéro de TVA intracommunautaire` varchar(10) DEFAULT NULL,
  `Document - % remise` int(1) DEFAULT NULL,
  `Document - Montant de la remise` varchar(3) DEFAULT NULL,
  `Document - % escompte` int(1) DEFAULT NULL,
  `Document - Montant de l'escompte` varchar(4) DEFAULT NULL,
  `Document - Code frais de port` varchar(10) DEFAULT NULL,
  `Document - Frais de port HT` int(2) DEFAULT NULL,
  `Document - Taux de TVA port` varchar(4) DEFAULT NULL,
  `Document - Code TVA port` varchar(36) DEFAULT NULL,
  `Document - Port non soumis ą escompte` int(1) DEFAULT NULL,
  `Document - Total Brut HT` varchar(6) DEFAULT NULL,
  `Document - Total TTC` varchar(6) DEFAULT NULL,
  `Document - Notes` varchar(10) DEFAULT NULL,
  `Document - Notes en texte brut` varchar(10) DEFAULT NULL,
  `Document - Référence` varchar(10) DEFAULT NULL,
  `Document - Code commercial/collaborateur` varchar(7) DEFAULT NULL,
  `Document - Code mode de rčglement` varchar(3) DEFAULT NULL,
  `Document - Etat du devis` int(1) DEFAULT NULL,
  `Ligne - Code ligne de document` varchar(36) DEFAULT NULL,
  `Ligne - Code article` varchar(8) DEFAULT NULL,
  `Ligne - Description` varchar(269) DEFAULT NULL,
  `Ligne - Description commerciale en clair` varchar(127) DEFAULT NULL,
  `Ligne - Quantité` int(1) DEFAULT NULL,
  `Ligne - Taux de TVA` varchar(4) DEFAULT NULL,
  `Ligne - Code TVA` varchar(36) DEFAULT NULL,
  `Ligne - Type de ligne` int(1) DEFAULT NULL,
  `Ligne - PV HT` varchar(6) DEFAULT NULL,
  `Ligne - PV TTC` varchar(6) DEFAULT NULL,
  `Ligne - % remise unitaire cumulé` int(1) DEFAULT NULL,
  `Ligne - Montant de remise unitaire HT cumulé` varchar(3) DEFAULT NULL,
  `Ligne - Montant Net HT` varchar(6) DEFAULT NULL,
  `Ligne - Montant Net TTC` varchar(6) DEFAULT NULL,
  `Ligne - Code commercial/collaborateur` varchar(7) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Déchargement des données de la table `export_devis`
--

INSERT INTO `export_devis` (`Acompte - Montant de l'acompte`, `Document - Numéro du document`, `Document - Date`, `Document - Code client`, `Document - Civilité`, `Document - Nom du client`, `Document - Adresse 1 (facturation)`, `Document - Adresse 2 (facturation)`, `Document - Adresse 3 (facturation)`, `Document - Adresse 4 (facturation)`, `Document - Code postal (facturation)`, `Document - Ville (facturation)`, `Document - Département (facturation)`, `Document - Code Pays (facturation)`, `Document - Nom (contact) (facturation)`, `Document - Prénom (facturation)`, `Document - Téléphone fixe (facturation)`, `Document - Téléphone portable (facturation)`, `Document - Fax (facturation)`, `Document - E-mail (facturation)`, `Document - Nom (adresse) (livraison)`, `Document - Civilité (adresse) (livraison)`, `Document - Adresse 1 (livraison)`, `Document - Adresse 2 (livraison)`, `Document - Adresse 3 (livraison)`, `Document - Adresse 4 (livraison)`, `Document - Code postal (livraison)`, `Document - Ville (livraison)`, `Document - Département (livraison)`, `Document - Code Pays (livraison)`, `Document - Nom (contact) (livraison)`, `Document - Prénom (livraison)`, `Document - Téléphone fixe (livraison)`, `Document - Téléphone portable (livraison)`, `Document - Fax (livraison)`, `Document - E-mail (livraison)`, `Document - Territorialité`, `Document - Numéro de TVA intracommunautaire`, `Document - % remise`, `Document - Montant de la remise`, `Document - % escompte`, `Document - Montant de l'escompte`, `Document - Code frais de port`, `Document - Frais de port HT`, `Document - Taux de TVA port`, `Document - Code TVA port`, `Document - Port non soumis ą escompte`, `Document - Total Brut HT`, `Document - Total TTC`, `Document - Notes`, `Document - Notes en texte brut`, `Document - Référence`, `Document - Code commercial/collaborateur`, `Document - Code mode de rčglement`, `Document - Etat du devis`, `Ligne - Code ligne de document`, `Ligne - Code article`, `Ligne - Description`, `Ligne - Description commerciale en clair`, `Ligne - Quantité`, `Ligne - Taux de TVA`, `Ligne - Code TVA`, `Ligne - Type de ligne`, `Ligne - PV HT`, `Ligne - PV TTC`, `Ligne - % remise unitaire cumulé`, `Ligne - Montant de remise unitaire HT cumulé`, `Ligne - Montant Net HT`, `Ligne - Montant Net TTC`, `Ligne - Code commercial/collaborateur`) VALUES
(0, 'DE00000001', '07/12/2024', 'CCL00003', '', 'ECCA SARL', '5 rue de rivoli', '', '', '', 75001, 'PARIS 1ER ARRONDISSEMENT', 'PARIS', 'FR', '', '', '', '', '', '', '', '', '5 rue de rivoli', '', '', '', 75001, 'PARIS 1ER ARRONDISSEMENT', 'PARIS', 'FR', '', '', '', '', '', '', 'FRANCE', '', 2, '3,9', 1, '2,01', '', 10, '20', '36cab0de-3e5b-4bee-a556-8eabb1673e76', 0, '201,1', '233,28', '', '', '', 'CO00002', '', 4, '76f4ab94-2f17-4cd9-a7b9-ecd7f228a856', 'ACTI0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\n\\viewkind4\\uc1\\pard\\f0\\fs17 FIGURINE HYBRIDE\\par\n}\n', 'FIGURINE HYBRIDE', 2, '20', '36cab0de-3e5b-4bee-a556-8eabb1673e76', 2, '50', '60', 5, '2,5', '95', '114', 'CO00002'),
(0, 'DE00000001', '07/12/2024', 'CCL00003', '', 'ECCA SARL', '5 rue de rivoli', '', '', '', 75001, 'PARIS 1ER ARRONDISSEMENT', 'PARIS', 'FR', '', '', '', '', '', '', '', '', '5 rue de rivoli', '', '', '', 75001, 'PARIS 1ER ARRONDISSEMENT', 'PARIS', 'FR', '', '', '', '', '', '', 'FRANCE', '', 2, '3,9', 1, '2,01', '', 10, '20', '36cab0de-3e5b-4bee-a556-8eabb1673e76', 0, '201,1', '233,28', '', '', '', 'CO00002', '', 4, '846a5678-4043-4da3-8b5d-2962134e65f5', 'ACTI0002', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\n\\viewkind4\\uc1\\pard\\f0\\fs17 VOITURE HERO\\par\n}\n', 'VOITURE HERO', 1, '5,5', '7575b022-1c00-4cbb-a83b-162242143634', 2, '40', '42,2', 0, '0', '40', '42,2', 'CO00002'),
(0, 'DE00000001', '07/12/2024', 'CCL00003', '', 'ECCA SARL', '5 rue de rivoli', '', '', '', 75001, 'PARIS 1ER ARRONDISSEMENT', 'PARIS', 'FR', '', '', '', '', '', '', '', '', '5 rue de rivoli', '', '', '', 75001, 'PARIS 1ER ARRONDISSEMENT', 'PARIS', 'FR', '', '', '', '', '', '', 'FRANCE', '', 2, '3,9', 1, '2,01', '', 10, '20', '36cab0de-3e5b-4bee-a556-8eabb1673e76', 0, '201,1', '233,28', '', '', '', 'CO00002', '', 4, '81b3be4f-ea65-4351-bad1-df9f8bdc11d1', 'ACTI0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\n\\viewkind4\\uc1\\pard\\f0\\fs17 FIGURINE HYBRIDE modifi\\\'e9\\par\n}\n', 'FIGURINE HYBRIDE modifié', 1, '20', '36cab0de-3e5b-4bee-a556-8eabb1673e76', 2, '60', '72', 0, '0', '60', '72', 'CO00002'),
(0, 'DE00000002', '19/12/2024', 'CCL00003', '', 'ECCA SARL', '5 rue de rivoli', '', '', '', 75001, 'PARIS 1ER ARRONDISSEMENT', 'PARIS', 'FR', '', '', '', '', '', '', '', '', '5 rue de rivoli', '', '', '', 75001, 'PARIS 1ER ARRONDISSEMENT', 'PARIS', 'FR', '', '', '', '', '', '', 'FRANCE', '', 2, '6,3', 1, '3,19', '', 10, '20', '36cab0de-3e5b-4bee-a556-8eabb1673e76', 0, '318,7', '372,98', '', '', '', 'CO00002', '', 0, 'a8905814-1a01-4c88-a045-2a8517825eb9', 'ACTI0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\n\\viewkind4\\uc1\\pard\\f0\\fs17 FIGURINE HYBRIDE\\par\n}\n', 'FIGURINE HYBRIDE', 2, '20', '36cab0de-3e5b-4bee-a556-8eabb1673e76', 2, '50', '60', 5, '2,5', '95', '114', 'CO00002'),
(0, 'DE00000002', '19/12/2024', 'CCL00003', '', 'ECCA SARL', '5 rue de rivoli', '', '', '', 75001, 'PARIS 1ER ARRONDISSEMENT', 'PARIS', 'FR', '', '', '', '', '', '', '', '', '5 rue de rivoli', '', '', '', 75001, 'PARIS 1ER ARRONDISSEMENT', 'PARIS', 'FR', '', '', '', '', '', '', 'FRANCE', '', 2, '6,3', 1, '3,19', '', 10, '20', '36cab0de-3e5b-4bee-a556-8eabb1673e76', 0, '318,7', '372,98', '', '', '', 'CO00002', '', 0, '58f6fa41-230e-4203-be65-9fb0ffb41daf', 'ACTI0002', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\n\\viewkind4\\uc1\\pard\\f0\\fs17 VOITURE HERO\\par\n}\n', 'VOITURE HERO', 1, '5,5', '7575b022-1c00-4cbb-a83b-162242143634', 2, '40', '42,2', 0, '0', '40', '42,2', 'CO00002'),
(0, 'DE00000002', '19/12/2024', 'CCL00003', '', 'ECCA SARL', '5 rue de rivoli', '', '', '', 75001, 'PARIS 1ER ARRONDISSEMENT', 'PARIS', 'FR', '', '', '', '', '', '', '', '', '5 rue de rivoli', '', '', '', 75001, 'PARIS 1ER ARRONDISSEMENT', 'PARIS', 'FR', '', '', '', '', '', '', 'FRANCE', '', 2, '6,3', 1, '3,19', '', 10, '20', '36cab0de-3e5b-4bee-a556-8eabb1673e76', 0, '318,7', '372,98', '', '', '', 'CO00002', '', 0, '1b4bc241-368b-42c9-9698-778f0438b47e', 'ACTI0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\n\\viewkind4\\uc1\\pard\\f0\\fs17 FIGURINE HYBRIDE modifi\\\'e9\\par\n}\n', 'FIGURINE HYBRIDE modifié', 3, '20', '36cab0de-3e5b-4bee-a556-8eabb1673e76', 2, '60', '72', 0, '0', '180', '216', 'CO00002'),
(0, 'DE0900000001', '07/07/2017', 'CL00003', 'Madame', 'RAVIN Odile', '5 rue Mond', '', '', '', 93000, 'BOBIGNY', 'SEINE-ST-DENIS', 'FR', '', '', '', '', '', '', 'RAVIN Odile', 'Madame', '5 rue Mond', '', '', '', 93000, 'BOBIGNY', 'SEINE-ST-DENIS', 'FR', '', '', '', '', '', '', 'FRANCE', '', 0, '0', 0, '0', '', 0, '19,6', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '251,88', '301,25', '', '', '', '', 'CH2', 3, '76e844d7-bb4e-4542-842c-2a21975df036', 'ACTI0002', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\n\\viewkind4\\uc1\\pard\\f0\\fs17 VOITURE HERO\\par\n}\n', 'VOITURE HERO', 1, '19,6', '823f1060-71b2-419a-b70a-2107c554b35b', 2, '17,47', '20,89', 0, '0', '17,47', '20,89', ''),
(0, 'DE0900000001', '07/07/2017', 'CL00003', 'Madame', 'RAVIN Odile', '5 rue Mond', '', '', '', 93000, 'BOBIGNY', 'SEINE-ST-DENIS', 'FR', '', '', '', '', '', '', 'RAVIN Odile', 'Madame', '5 rue Mond', '', '', '', 93000, 'BOBIGNY', 'SEINE-ST-DENIS', 'FR', '', '', '', '', '', '', 'FRANCE', '', 0, '0', 0, '0', '', 0, '19,6', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '251,88', '301,25', '', '', '', '', 'CH2', 3, '3f2374ec-a120-40db-901e-058c8c8bd976', 'ATEL0002', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\n\\viewkind4\\uc1\\pard\\f0\\fs17 ATELIER BRICOLAGE\\par\n}\n', 'ATELIER BRICOLAGE', 5, '19,6', '823f1060-71b2-419a-b70a-2107c554b35b', 3, '31,35', '37,49', 0, '0', '156,75', '187,47', ''),
(0, 'DE0900000001', '07/07/2017', 'CL00003', 'Madame', 'RAVIN Odile', '5 rue Mond', '', '', '', 93000, 'BOBIGNY', 'SEINE-ST-DENIS', 'FR', '', '', '', '', '', '', 'RAVIN Odile', 'Madame', '5 rue Mond', '', '', '', 93000, 'BOBIGNY', 'SEINE-ST-DENIS', 'FR', '', '', '', '', '', '', 'FRANCE', '', 0, '0', 0, '0', '', 0, '19,6', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '251,88', '301,25', '', '', '', '', 'CH2', 3, '629cd8f5-ac06-4fe3-a19f-0d1a1169c2ac', 'GOUT0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\n\\viewkind4\\uc1\\pard\\f0\\fs17 GOUTER SIMPLE\\par\nGo\\\'fbter compos\\\'e9 d\'une cr\\\'eape ou une part de gateau, un bonbon et une boisson froide (soda ou jus de fruit au choix)\\par\n}\n', 'GOUTER SIMPLE\nGoūter composé d\'une crźpe ou une part de gateau, un bonbon et une boisson froide (soda ou jus de fruit au choix)', 5, '19,6', '823f1060-71b2-419a-b70a-2107c554b35b', 3, '8,36', '10', 0, '0', '41,8', '49,99', ''),
(0, 'DE0900000001', '07/07/2017', 'CL00003', 'Madame', 'RAVIN Odile', '5 rue Mond', '', '', '', 93000, 'BOBIGNY', 'SEINE-ST-DENIS', 'FR', '', '', '', '', '', '', 'RAVIN Odile', 'Madame', '5 rue Mond', '', '', '', 93000, 'BOBIGNY', 'SEINE-ST-DENIS', 'FR', '', '', '', '', '', '', 'FRANCE', '', 0, '0', 0, '0', '', 0, '19,6', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '251,88', '301,25', '', '', '', '', 'CH2', 3, '5ffeaadd-a7b4-4721-af17-c530457dd99c', 'LOCO0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\n\\viewkind4\\uc1\\pard\\f0\\fs17 LOCOMOTIVE VAPEUR SON ET LUMIERE\\par\n}\n', 'LOCOMOTIVE VAPEUR SON ET LUMIERE', 1, '19,6', '823f1060-71b2-419a-b70a-2107c554b35b', 2, '35,86', '42,89', 0, '0', '35,86', '42,89', ''),
(0, 'DE0900000002', '07/07/2017', 'MAR0002', 'Monsieur', 'MARTIN Eric', '52 rue pasteur', '', '', '', 94120, 'FONTENAY SOUS BOIS', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', 'MARTIN Eric', 'Monsieur', '52 rue pasteur', '', '', '', 94120, 'FONTENAY SOUS BOIS', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', 'FRANCE', '', 0, '0', 0, '0', '', 0, '19,6', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '213,91', '255,84', '', '', '', '', '', 3, 'a0b0f0f5-6bc8-4173-a30d-5959cdc7b6e3', 'DEST0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\n\\viewkind4\\uc1\\pard\\f0\\fs17 JEUX FAMILIAL ELECTRONIQUE\\par\n}\n', 'JEUX FAMILIAL ELECTRONIQUE', 1, '19,6', '823f1060-71b2-419a-b70a-2107c554b35b', 2, '50,49', '60,39', 0, '0', '50,49', '60,39', ''),
(0, 'DE0900000002', '07/07/2017', 'MAR0002', 'Monsieur', 'MARTIN Eric', '52 rue pasteur', '', '', '', 94120, 'FONTENAY SOUS BOIS', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', 'MARTIN Eric', 'Monsieur', '52 rue pasteur', '', '', '', 94120, 'FONTENAY SOUS BOIS', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', 'FRANCE', '', 0, '0', 0, '0', '', 0, '19,6', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '213,91', '255,84', '', '', '', '', '', 3, '986a9c75-ff2a-45d3-93cf-a0c33452fab3', 'ENSE0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\n\\viewkind4\\uc1\\pard\\f0\\fs17 ENSEMBLE LAVE VAISSELLE\\par\n}\n', 'ENSEMBLE LAVE VAISSELLE', 1, '19,6', '823f1060-71b2-419a-b70a-2107c554b35b', 2, '110,36', '131,99', 0, '0', '110,36', '131,99', ''),
(0, 'DE0900000002', '07/07/2017', 'MAR0002', 'Monsieur', 'MARTIN Eric', '52 rue pasteur', '', '', '', 94120, 'FONTENAY SOUS BOIS', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', 'MARTIN Eric', 'Monsieur', '52 rue pasteur', '', '', '', 94120, 'FONTENAY SOUS BOIS', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', 'FRANCE', '', 0, '0', 0, '0', '', 0, '19,6', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '213,91', '255,84', '', '', '', '', '', 3, 'bd89e4ea-7783-4773-97d1-f2061b8fb5ad', 'ETOI0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\n\\viewkind4\\uc1\\pard\\f0\\fs17 ETOILES ET PLANETES LIVRE 9 ANS ET PLUS\\par\n}\n', 'ETOILES ET PLANETES LIVRE 9 ANS ET PLUS', 1, '19,6', '823f1060-71b2-419a-b70a-2107c554b35b', 2, '8,27', '9,89', 0, '0', '8,27', '9,89', ''),
(0, 'DE0900000002', '07/07/2017', 'MAR0002', 'Monsieur', 'MARTIN Eric', '52 rue pasteur', '', '', '', 94120, 'FONTENAY SOUS BOIS', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', 'MARTIN Eric', 'Monsieur', '52 rue pasteur', '', '', '', 94120, 'FONTENAY SOUS BOIS', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', 'FRANCE', '', 0, '0', 0, '0', '', 0, '19,6', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '213,91', '255,84', '', '', '', '', '', 3, '7d21565a-4b4e-40e7-8a0e-50aa2bbe090f', 'FISH0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\n\\viewkind4\\uc1\\pard\\f0\\fs17 MAQUETTE HOMO SAPIENS\\par\n}\n', 'MAQUETTE HOMO SAPIENS', 1, '19,6', '823f1060-71b2-419a-b70a-2107c554b35b', 2, '10,95', '13,1', 0, '0', '10,95', '13,1', ''),
(0, 'DE0900000002', '07/07/2017', 'MAR0002', 'Monsieur', 'MARTIN Eric', '52 rue pasteur', '', '', '', 94120, 'FONTENAY SOUS BOIS', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', 'MARTIN Eric', 'Monsieur', '52 rue pasteur', '', '', '', 94120, 'FONTENAY SOUS BOIS', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', 'FRANCE', '', 0, '0', 0, '0', '', 0, '19,6', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '213,91', '255,84', '', '', '', '', '', 3, '090de12a-ea33-41f6-aa2d-e546f5e3f5fe', 'GARA0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\n\\viewkind4\\uc1\\pard\\f0\\fs17 GARAGE VOITURES\\par\n}\n', 'GARAGE VOITURES', 1, '19,6', '823f1060-71b2-419a-b70a-2107c554b35b', 2, '28,5', '34,09', 0, '0', '28,5', '34,09', ''),
(0, 'DE0900000002', '07/07/2017', 'MAR0002', 'Monsieur', 'MARTIN Eric', '52 rue pasteur', '', '', '', 94120, 'FONTENAY SOUS BOIS', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', 'MARTIN Eric', 'Monsieur', '52 rue pasteur', '', '', '', 94120, 'FONTENAY SOUS BOIS', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', 'FRANCE', '', 0, '0', 0, '0', '', 0, '19,6', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '213,91', '255,84', '', '', '', '', '', 3, 'a7b99c9b-29f8-4f5a-94cd-e9a08655388a', 'GIRA0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\n\\viewkind4\\uc1\\pard\\f0\\fs17 HIPPOPOTAME MALE\\par\n}\n', 'HIPPOPOTAME MALE', 1, '19,6', '823f1060-71b2-419a-b70a-2107c554b35b', 2, '5,34', '6,39', 0, '0', '5,34', '6,39', '');

-- --------------------------------------------------------

--
-- Structure de la table `export_factures`
--

CREATE TABLE `export_factures` (
  `Document - Numéro du document` varchar(12) DEFAULT NULL,
  `Document - Date` varchar(10) DEFAULT NULL,
  `Document - Code client` varchar(8) DEFAULT NULL,
  `Document - Civilité` varchar(12) DEFAULT NULL,
  `Document - Nom du client` varchar(16) DEFAULT NULL,
  `Document - Adresse 1 (facturation)` varchar(33) DEFAULT NULL,
  `Document - Adresse 2 (facturation)` varchar(10) DEFAULT NULL,
  `Document - Adresse 3 (facturation)` varchar(10) DEFAULT NULL,
  `Document - Adresse 4 (facturation)` varchar(10) DEFAULT NULL,
  `Document - Code postal (facturation)` varchar(5) DEFAULT NULL,
  `Document - Ville (facturation)` varchar(26) DEFAULT NULL,
  `Document - Département (facturation)` varchar(12) DEFAULT NULL,
  `Document - Code Pays (facturation)` varchar(2) DEFAULT NULL,
  `Document - Nom (contact) (facturation)` varchar(9) DEFAULT NULL,
  `Document - Prénom (facturation)` varchar(8) DEFAULT NULL,
  `Document - Téléphone fixe (facturation)` varchar(15) DEFAULT NULL,
  `Document - Téléphone portable (facturation)` varchar(10) DEFAULT NULL,
  `Document - Fax (facturation)` varchar(10) DEFAULT NULL,
  `Document - E-mail (facturation)` varchar(26) DEFAULT NULL,
  `Document - Nom (adresse) (livraison)` varchar(16) DEFAULT NULL,
  `Document - Civilité (adresse) (livraison)` varchar(12) DEFAULT NULL,
  `Document - Adresse 1 (livraison)` varchar(33) DEFAULT NULL,
  `Document - Adresse 2 (livraison)` varchar(10) DEFAULT NULL,
  `Document - Adresse 3 (livraison)` varchar(10) DEFAULT NULL,
  `Document - Adresse 4 (livraison)` varchar(10) DEFAULT NULL,
  `Document - Code postal (livraison)` varchar(5) DEFAULT NULL,
  `Document - Ville (livraison)` varchar(26) DEFAULT NULL,
  `Document - Département (livraison)` varchar(12) DEFAULT NULL,
  `Document - Code Pays (livraison)` varchar(2) DEFAULT NULL,
  `Document - Nom (contact) (livraison)` varchar(9) DEFAULT NULL,
  `Document - Prénom (livraison)` varchar(8) DEFAULT NULL,
  `Document - Téléphone fixe (livraison)` varchar(15) DEFAULT NULL,
  `Document - Téléphone portable (livraison)` varchar(10) DEFAULT NULL,
  `Document - Fax (livraison)` varchar(10) DEFAULT NULL,
  `Document - E-mail (livraison)` varchar(26) DEFAULT NULL,
  `Document - Territorialité` varchar(6) DEFAULT NULL,
  `Document - Numéro de TVA intracommunautaire` varchar(10) DEFAULT NULL,
  `Document - % remise` varchar(10) DEFAULT NULL,
  `Document - Montant de la remise` varchar(10) DEFAULT NULL,
  `Document - % escompte` varchar(10) DEFAULT NULL,
  `Document - Montant de l'escompte` varchar(10) DEFAULT NULL,
  `Document - Code frais de port` varchar(10) DEFAULT NULL,
  `Document - Frais de port HT` varchar(11) DEFAULT NULL,
  `Document - Taux de TVA port` varchar(5) DEFAULT NULL,
  `Document - Code TVA port` varchar(36) DEFAULT NULL,
  `Document - Port non soumis ą escompte` int(1) DEFAULT NULL,
  `Document - Total Brut HT` varchar(13) DEFAULT NULL,
  `Document - Total TTC` varchar(13) DEFAULT NULL,
  `Document - Notes` varchar(10) DEFAULT NULL,
  `Document - Notes en texte brut` varchar(10) DEFAULT NULL,
  `Document - Référence` varchar(10) DEFAULT NULL,
  `Document - Code commercial/collaborateur` varchar(7) DEFAULT NULL,
  `Document - Code mode de rčglement` varchar(4) DEFAULT NULL,
  `Ligne - Code ligne de document` varchar(36) DEFAULT NULL,
  `Ligne - Code article` varchar(8) DEFAULT NULL,
  `Ligne - Description` varchar(308) DEFAULT NULL,
  `Ligne - Description commerciale en clair` varchar(157) DEFAULT NULL,
  `Ligne - Date de livraison` varchar(10) DEFAULT NULL,
  `Ligne - Quantité` varchar(11) DEFAULT NULL,
  `Ligne - Taux de TVA` varchar(5) DEFAULT NULL,
  `Ligne - Code TVA` varchar(36) DEFAULT NULL,
  `Ligne - Type de ligne` int(1) DEFAULT NULL,
  `Ligne - PV HT` varchar(12) DEFAULT NULL,
  `Ligne - PV TTC` varchar(12) DEFAULT NULL,
  `Ligne - % remise unitaire cumulé` varchar(10) DEFAULT NULL,
  `Ligne - Montant de remise unitaire HT cumulé` varchar(10) DEFAULT NULL,
  `Ligne - Montant Net HT` varchar(13) DEFAULT NULL,
  `Ligne - Montant Net TTC` varchar(13) DEFAULT NULL,
  `Ligne - Code commercial/collaborateur` varchar(7) DEFAULT NULL,
  `Ligne - Codes des lignes de commandes` varchar(10) DEFAULT NULL,
  `Ligne - Codes des commandes` varchar(10) DEFAULT NULL,
  `Ligne - Quantités ą livrer` varchar(10) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Déchargement des données de la table `export_factures`
--

INSERT INTO `export_factures` (`Document - Numéro du document`, `Document - Date`, `Document - Code client`, `Document - Civilité`, `Document - Nom du client`, `Document - Adresse 1 (facturation)`, `Document - Adresse 2 (facturation)`, `Document - Adresse 3 (facturation)`, `Document - Adresse 4 (facturation)`, `Document - Code postal (facturation)`, `Document - Ville (facturation)`, `Document - Département (facturation)`, `Document - Code Pays (facturation)`, `Document - Nom (contact) (facturation)`, `Document - Prénom (facturation)`, `Document - Téléphone fixe (facturation)`, `Document - Téléphone portable (facturation)`, `Document - Fax (facturation)`, `Document - E-mail (facturation)`, `Document - Nom (adresse) (livraison)`, `Document - Civilité (adresse) (livraison)`, `Document - Adresse 1 (livraison)`, `Document - Adresse 2 (livraison)`, `Document - Adresse 3 (livraison)`, `Document - Adresse 4 (livraison)`, `Document - Code postal (livraison)`, `Document - Ville (livraison)`, `Document - Département (livraison)`, `Document - Code Pays (livraison)`, `Document - Nom (contact) (livraison)`, `Document - Prénom (livraison)`, `Document - Téléphone fixe (livraison)`, `Document - Téléphone portable (livraison)`, `Document - Fax (livraison)`, `Document - E-mail (livraison)`, `Document - Territorialité`, `Document - Numéro de TVA intracommunautaire`, `Document - % remise`, `Document - Montant de la remise`, `Document - % escompte`, `Document - Montant de l'escompte`, `Document - Code frais de port`, `Document - Frais de port HT`, `Document - Taux de TVA port`, `Document - Code TVA port`, `Document - Port non soumis ą escompte`, `Document - Total Brut HT`, `Document - Total TTC`, `Document - Notes`, `Document - Notes en texte brut`, `Document - Référence`, `Document - Code commercial/collaborateur`, `Document - Code mode de rčglement`, `Ligne - Code ligne de document`, `Ligne - Code article`, `Ligne - Description`, `Ligne - Description commerciale en clair`, `Ligne - Date de livraison`, `Ligne - Quantité`, `Ligne - Taux de TVA`, `Ligne - Code TVA`, `Ligne - Type de ligne`, `Ligne - PV HT`, `Ligne - PV TTC`, `Ligne - % remise unitaire cumulé`, `Ligne - Montant de remise unitaire HT cumulé`, `Ligne - Montant Net HT`, `Ligne - Montant Net TTC`, `Ligne - Code commercial/collaborateur`, `Ligne - Codes des lignes de commandes`, `Ligne - Codes des commandes`, `Ligne - Quantités ą livrer`) VALUES
('FA00000001', '18/04/2018', 'CCL00004', '', 'GESPI', '28 rue de la Fontaine de l\'Yvette', '', '', '', '91140', 'VILLEBON SUR YVETTE', 'ESSONNE', 'FR', '', '', '', '', '', '', '', '', '28 rue de la Fontaine de l\'Yvette', '', '', '', '91140', 'VILLEBON SUR YVETTE', 'ESSONNE', 'FR', '', '', '', '', '', '', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '162,00000000', '194,40000000', '', '', '', 'CO00001', '', 'a2f87fd6-32c9-4dd9-b389-7c880a29f311', 'ANIM0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 ANIMATEUR/ANIMATRICE POUR LA JOURNEE\\par\r\n}\r\n', 'ANIMATEUR/ANIMATRICE POUR LA JOURNEE', '', '1,00000000', '20,00', '36cab0de-3e5b-4bee-a556-8eabb1673e76', 3, '162,00000000', '194,40000000', '0', '0', '162,00000000', '194,40000000', 'CO00001', '', '', ''),
('FA00000002', '18/04/2018', 'CCL00003', '', 'ECCA SARL', '', '', '', '', '75013', 'PARIS 13EME ARRONDISSEMENT', 'PARIS', 'FR', '', '', '', '', '', '', '', '', '', '', '', '', '75013', 'PARIS 13EME ARRONDISSEMENT', 'PARIS', 'FR', '', '', '', '', '', '', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '36,77000000', '44,12000000', '', '', '', 'CO00002', '', '4eaf40a4-0d66-42af-8bb8-0f37f5e8dc6c', 'ACTI0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 FIGURINE HYBRIDE\\par\r\n}\r\n', 'FIGURINE HYBRIDE', '', '1,00000000', '20,00', '36cab0de-3e5b-4bee-a556-8eabb1673e76', 2, '36,77000000', '44,12000000', '0', '0', '36,77000000', '44,12000000', 'CO00002', '', '', ''),
('FA00000003', '18/04/2018', 'BDM0001', 'CE', 'BDMANIA', '17 rue Centrale', '', '', '', '01200', 'BELLEGARDE SUR VALSERINE', 'AIN', 'FR', '', '', '', '', '', '', 'BDMANIA', 'CE', '17 rue Centrale', '', '', '', '01200', 'BELLEGARDE SUR VALSERINE', 'AIN', 'FR', '', '', '', '', '', '', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '371,03000000', '445,24000000', '', '', '', 'CO00001', '', '0eb97ddc-045f-4258-805d-77491b8ed005', 'ANIM0004', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 PERE NOEL POUR LA JOURNEE\\par\r\n}\r\n', 'PERE NOEL POUR LA JOURNEE', '', '1,00000000', '20,00', '36cab0de-3e5b-4bee-a556-8eabb1673e76', 3, '209,03000000', '250,84000000', '0', '0', '209,03000000', '250,84000000', 'CO00001', '', '', ''),
('FA00000003', '18/04/2018', 'BDM0001', 'CE', 'BDMANIA', '17 rue Centrale', '', '', '', '01200', 'BELLEGARDE SUR VALSERINE', 'AIN', 'FR', '', '', '', '', '', '', 'BDMANIA', 'CE', '17 rue Centrale', '', '', '', '01200', 'BELLEGARDE SUR VALSERINE', 'AIN', 'FR', '', '', '', '', '', '', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '371,03000000', '445,24000000', '', '', '', 'CO00001', '', 'ad54556a-3833-4201-b41c-54f397837758', 'ANIM0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 ANIMATEUR/ANIMATRICE POUR LA JOURNEE\\par\r\n}\r\n', 'ANIMATEUR/ANIMATRICE POUR LA JOURNEE', '', '1,00000000', '20,00', '36cab0de-3e5b-4bee-a556-8eabb1673e76', 3, '162,00000000', '194,40000000', '0', '0', '162,00000000', '194,40000000', 'CO00001', '', '', ''),
('FA00000004', '18/04/2018', 'CCL00006', '', 'TONIER', '159 Boulevard de Créteil', '', '', '', '94100', 'ST MAUR DES FOSSES', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', '', '', '159 Boulevard de Créteil', '', '', '', '94100', 'ST MAUR DES FOSSES', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '209,63000000', '251,56000000', '', '', '', 'CO00001', '', 'd39de3b6-8e44-4fca-8c2b-f44d1a8f9486', 'ANIM0002', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 ASSISTANT/ASSISTANTE POUR LA JOURNEE\\par\r\n}\r\n', 'ASSISTANT/ASSISTANTE POUR LA JOURNEE', '', '1,00000000', '20,00', '36cab0de-3e5b-4bee-a556-8eabb1673e76', 3, '209,63000000', '251,56000000', '0', '0', '209,63000000', '251,56000000', 'CO00001', '', '', ''),
('FA00000005', '10/03/2025', 'CCL00003', '', 'ECCA SARL', '', '', '', '', '75013', 'PARIS 13EME ARRONDISSEMENT', 'PARIS', 'FR', '', '', '', '', '', '', '', '', '', '', '', '', '75013', 'PARIS 13EME ARRONDISSEMENT', 'PARIS', 'FR', '', '', '', '', '', '', 'FRANCE', '', '2,00000000', '1,40000000', '1,00000000', '0,79000000', '', '10,00000000', '20,00', '36cab0de-3e5b-4bee-a556-8eabb1673e76', 0, '78,57000000', '88,16000000', '', '', '', 'CO00002', '', '47918fbd-e509-48d1-9c2d-4fce79b6eac6', 'ACTI0002', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 VOITURE HERO\\par\r\n}\r\n', 'VOITURE HERO', '', '2,00000000', '20,00', '36cab0de-3e5b-4bee-a556-8eabb1673e76', 2, '17,47000000', '20,96000000', '5,00000000', '0,87000000', '33,20000000', '39,84000000', 'CO00002', '', '', ''),
('FA00000005', '10/03/2025', 'CCL00003', '', 'ECCA SARL', '', '', '', '', '75013', 'PARIS 13EME ARRONDISSEMENT', 'PARIS', 'FR', '', '', '', '', '', '', '', '', '', '', '', '', '75013', 'PARIS 13EME ARRONDISSEMENT', 'PARIS', 'FR', '', '', '', '', '', '', 'FRANCE', '', '2,00000000', '1,40000000', '1,00000000', '0,79000000', '', '10,00000000', '20,00', '36cab0de-3e5b-4bee-a556-8eabb1673e76', 0, '78,57000000', '88,16000000', '', '', '', 'CO00002', '', 'b914d5f0-c005-4b31-a2f6-0bb04b7fc175', 'ACTI0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 FIGURINE HYBRIDE\\par\r\n}\r\n', 'FIGURINE HYBRIDE', '', '1,00000000', '5,50', '7575b022-1c00-4cbb-a83b-162242143634', 2, '36,77000000', '38,79000000', '0', '0', '36,77000000', '38,79000000', 'CO00002', '', '', ''),
('FA0900000001', '08/07/2017', 'MAR0002', 'Monsieur', 'MARTIN Eric', '52 rue pasteur', '', '', '', '94120', 'FONTENAY SOUS BOIS', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', 'MARTIN Eric', 'Monsieur', '52 rue pasteur', '', '', '', '94120', 'FONTENAY SOUS BOIS', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '857,00000000', '1024,97000000', '', '', '', '', '', '6c13ebe8-d8f6-4467-8ef5-2e3f37224027', 'ANIM0002', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 ASSISTANT/ASSISTANTE POUR LA JOURNEE\\par\r\n}\r\n', 'ASSISTANT/ASSISTANTE POUR LA JOURNEE', '08/07/2017', '1,00000000', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 3, '62,71000000', '75,00000000', '0', '0', '62,71000000', '75,00000000', '', '', '', ''),
('FA0900000001', '08/07/2017', 'MAR0002', 'Monsieur', 'MARTIN Eric', '52 rue pasteur', '', '', '', '94120', 'FONTENAY SOUS BOIS', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', 'MARTIN Eric', 'Monsieur', '52 rue pasteur', '', '', '', '94120', 'FONTENAY SOUS BOIS', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '857,00000000', '1024,97000000', '', '', '', '', '', 'adf13748-8f2d-4b8f-bf2d-578c77fdb06e', 'ANIM0003', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 MAGICIEN POUR LA JOURNEE\\par\r\n}\r\n', 'MAGICIEN POUR LA JOURNEE', '08/07/2017', '1,00000000', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 3, '365,80000000', '437,50000000', '0', '0', '365,80000000', '437,50000000', '', '', '', ''),
('FA0900000001', '08/07/2017', 'MAR0002', 'Monsieur', 'MARTIN Eric', '52 rue pasteur', '', '', '', '94120', 'FONTENAY SOUS BOIS', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', 'MARTIN Eric', 'Monsieur', '52 rue pasteur', '', '', '', '94120', 'FONTENAY SOUS BOIS', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '857,00000000', '1024,97000000', '', '', '', '', '', '27335d61-0445-482a-b614-bf05da8d2244', 'ATEL0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 ATELIER CREATION\\par\r\n}\r\n', 'ATELIER CREATION', '08/07/2017', '1,00000000', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 3, '31,35000000', '37,49000000', '0', '0', '31,35000000', '37,49000000', '', '', '', ''),
('FA0900000001', '08/07/2017', 'MAR0002', 'Monsieur', 'MARTIN Eric', '52 rue pasteur', '', '', '', '94120', 'FONTENAY SOUS BOIS', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', 'MARTIN Eric', 'Monsieur', '52 rue pasteur', '', '', '', '94120', 'FONTENAY SOUS BOIS', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '857,00000000', '1024,97000000', '', '', '', '', '', 'fd082634-d8a6-435c-93d4-ba7f1a1d0490', 'ATEL0004', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 ATELIER SCULPTURE SUR BALLONS\\par\r\n}\r\n', 'ATELIER SCULPTURE SUR BALLONS', '08/07/2017', '1,00000000', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 3, '31,35000000', '37,49000000', '0', '0', '31,35000000', '37,49000000', '', '', '', ''),
('FA0900000001', '08/07/2017', 'MAR0002', 'Monsieur', 'MARTIN Eric', '52 rue pasteur', '', '', '', '94120', 'FONTENAY SOUS BOIS', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', 'MARTIN Eric', 'Monsieur', '52 rue pasteur', '', '', '', '94120', 'FONTENAY SOUS BOIS', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '857,00000000', '1024,97000000', '', '', '', '', '', 'ccc5ffef-4584-4cd1-acbf-e49aec57a84b', 'DECO0002', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 DECOR BALLONS  HELIUM [100 BALLONS)\\par\r\n}\r\n', 'DECOR BALLONS  HELIUM [100 BALLONS)', '08/07/2017', '1,00000000', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 3, '156,78000000', '187,51000000', '0', '0', '156,78000000', '187,51000000', '', '', '', ''),
('FA0900000001', '08/07/2017', 'MAR0002', 'Monsieur', 'MARTIN Eric', '52 rue pasteur', '', '', '', '94120', 'FONTENAY SOUS BOIS', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', 'MARTIN Eric', 'Monsieur', '52 rue pasteur', '', '', '', '94120', 'FONTENAY SOUS BOIS', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '857,00000000', '1024,97000000', '', '', '', '', '', 'd112bb46-7d5c-4c26-940e-f8dce7f3ac40', 'DECO0004', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 DECOR THEME BABAR\\par\r\n}\r\n', 'DECOR THEME BABAR', '08/07/2017', '1,00000000', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 3, '104,51000000', '124,99000000', '0', '0', '104,51000000', '124,99000000', '', '', '', ''),
('FA0900000001', '08/07/2017', 'MAR0002', 'Monsieur', 'MARTIN Eric', '52 rue pasteur', '', '', '', '94120', 'FONTENAY SOUS BOIS', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', 'MARTIN Eric', 'Monsieur', '52 rue pasteur', '', '', '', '94120', 'FONTENAY SOUS BOIS', 'VAL-DE-MARNE', 'FR', '', '', '', '', '', '', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '857,00000000', '1024,97000000', '', '', '', '', '', 'e6146699-fb45-4adb-9ea3-80bcb06c007e', 'GOUT0002', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 GOUTER ELABORE\\par\r\nGo\\\'fbter compos\\\'e9 d\'une cr\\\'eape ou une part de gateau, une brochette de bonbons, barbe \\\'e0 papa et une boisson froide (soda ou jus de fruit au choix)\\par\r\n}\r\n', 'GOUTER ELABORE\nGoūter composé d\'une crźpe ou une part de gateau, une brochette de bonbons, barbe ą papa et une boisson froide (soda ou jus de fruit au choix)', '08/07/2017', '10,00000000', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 3, '10,45000000', '12,50000000', '0', '0', '104,50000000', '124,98000000', '', '', '', ''),
('FA0900000002', '08/07/2017', 'RIN0001', 'Mademoiselle', 'RINGUAI Nathalie', '37 rue des archives', '', '', '', '75003', 'PARIS 3EME ARRONDISSEMENT', 'PARIS', 'FR', 'RINGUAI', 'Nathalie', '', '', '', 'ringuai.nathalie@orange.fr', 'RINGUAI Nathalie', 'Mademoiselle', '37 rue des archives', '', '', '', '75003', 'PARIS 3EME ARRONDISSEMENT', 'PARIS', 'FR', 'RINGUAI', 'Nathalie', '', '', '', 'ringuai.nathalie@orange.fr', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '127,69000000', '152,72000000', '', '', '', '', 'CH30', '8d3ae92f-6f51-42d2-b12a-f0f077e43ae0', '', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 Transf\\\'e9r\\\'e9 de : Bon de livraison N\\\'b0 BL0900000001 du 05/01/2009.\\par\r\n\\par\r\n}\r\n', 'Transféré de : Bon de livraison N° BL0900000001 du 05/01/2009.\n', '', '', '', '', 9, '', '', '', '', '', '', '', '', '', ''),
('FA0900000002', '08/07/2017', 'RIN0001', 'Mademoiselle', 'RINGUAI Nathalie', '37 rue des archives', '', '', '', '75003', 'PARIS 3EME ARRONDISSEMENT', 'PARIS', 'FR', 'RINGUAI', 'Nathalie', '', '', '', 'ringuai.nathalie@orange.fr', 'RINGUAI Nathalie', 'Mademoiselle', '37 rue des archives', '', '', '', '75003', 'PARIS 3EME ARRONDISSEMENT', 'PARIS', 'FR', 'RINGUAI', 'Nathalie', '', '', '', 'ringuai.nathalie@orange.fr', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '127,69000000', '152,72000000', '', '', '', '', 'CH30', 'd9c4b71e-3691-4b53-8ee1-c7574963c29b', '', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 Commande par t\\\'e9l\\\'e9phone\\par\r\n}\r\n', 'Commande par téléphone', '', '', '', '', 4, '', '', '', '', '', '', '', '', '', ''),
('FA0900000002', '08/07/2017', 'RIN0001', 'Mademoiselle', 'RINGUAI Nathalie', '37 rue des archives', '', '', '', '75003', 'PARIS 3EME ARRONDISSEMENT', 'PARIS', 'FR', 'RINGUAI', 'Nathalie', '', '', '', 'ringuai.nathalie@orange.fr', 'RINGUAI Nathalie', 'Mademoiselle', '37 rue des archives', '', '', '', '75003', 'PARIS 3EME ARRONDISSEMENT', 'PARIS', 'FR', 'RINGUAI', 'Nathalie', '', '', '', 'ringuai.nathalie@orange.fr', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '127,69000000', '152,72000000', '', '', '', '', 'CH30', 'ba52022a-223d-4e7d-9859-f846005251ec', 'OURS0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 OURS BEIGE 23 CM \\par\r\n}\r\n', 'OURS BEIGE 23 CM ', '08/07/2017', '1,00000000', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 2, '14,61000000', '17,47000000', '0', '0', '14,61000000', '17,47000000', '', '', '', ''),
('FA0900000002', '08/07/2017', 'RIN0001', 'Mademoiselle', 'RINGUAI Nathalie', '37 rue des archives', '', '', '', '75003', 'PARIS 3EME ARRONDISSEMENT', 'PARIS', 'FR', 'RINGUAI', 'Nathalie', '', '', '', 'ringuai.nathalie@orange.fr', 'RINGUAI Nathalie', 'Mademoiselle', '37 rue des archives', '', '', '', '75003', 'PARIS 3EME ARRONDISSEMENT', 'PARIS', 'FR', 'RINGUAI', 'Nathalie', '', '', '', 'ringuai.nathalie@orange.fr', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '127,69000000', '152,72000000', '', '', '', '', 'CH30', 'cae6dfa1-6781-43f8-b1f3-49b5fd477e5b', 'PACO0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 PYJAMA BICOLOR\\par\r\n}\r\n', 'PYJAMA BICOLOR', '08/07/2017', '1,00000000', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 2, '6,42000000', '7,68000000', '0', '0', '6,42000000', '7,68000000', '', '', '', ''),
('FA0900000002', '08/07/2017', 'RIN0001', 'Mademoiselle', 'RINGUAI Nathalie', '37 rue des archives', '', '', '', '75003', 'PARIS 3EME ARRONDISSEMENT', 'PARIS', 'FR', 'RINGUAI', 'Nathalie', '', '', '', 'ringuai.nathalie@orange.fr', 'RINGUAI Nathalie', 'Mademoiselle', '37 rue des archives', '', '', '', '75003', 'PARIS 3EME ARRONDISSEMENT', 'PARIS', 'FR', 'RINGUAI', 'Nathalie', '', '', '', 'ringuai.nathalie@orange.fr', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '127,69000000', '152,72000000', '', '', '', '', 'CH30', '01e92d29-9d78-46d1-ab0d-9af102d1a707', 'PEIG0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 PEIGNOIR DE BAINS\\par\r\n}\r\n', 'PEIGNOIR DE BAINS', '08/07/2017', '1,00000000', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 2, '41,39000000', '49,50000000', '0', '0', '41,39000000', '49,50000000', '', '', '', ''),
('FA0900000002', '08/07/2017', 'RIN0001', 'Mademoiselle', 'RINGUAI Nathalie', '37 rue des archives', '', '', '', '75003', 'PARIS 3EME ARRONDISSEMENT', 'PARIS', 'FR', 'RINGUAI', 'Nathalie', '', '', '', 'ringuai.nathalie@orange.fr', 'RINGUAI Nathalie', 'Mademoiselle', '37 rue des archives', '', '', '', '75003', 'PARIS 3EME ARRONDISSEMENT', 'PARIS', 'FR', 'RINGUAI', 'Nathalie', '', '', '', 'ringuai.nathalie@orange.fr', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '127,69000000', '152,72000000', '', '', '', '', 'CH30', '924a80f9-8835-4237-831c-76b1ca26a0bf', 'POCH0002', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 POCHETTE SURPRISE 6 EUROS PAR ENFANT\\par\r\n}\r\n', 'POCHETTE SURPRISE 6 EUROS PAR ENFANT', '08/07/2017', '6,00000000', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 3, '6,28000000', '7,51000000', '0', '0', '37,68000000', '45,07000000', '', '', '', ''),
('FA0900000002', '08/07/2017', 'RIN0001', 'Mademoiselle', 'RINGUAI Nathalie', '37 rue des archives', '', '', '', '75003', 'PARIS 3EME ARRONDISSEMENT', 'PARIS', 'FR', 'RINGUAI', 'Nathalie', '', '', '', 'ringuai.nathalie@orange.fr', 'RINGUAI Nathalie', 'Mademoiselle', '37 rue des archives', '', '', '', '75003', 'PARIS 3EME ARRONDISSEMENT', 'PARIS', 'FR', 'RINGUAI', 'Nathalie', '', '', '', 'ringuai.nathalie@orange.fr', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '127,69000000', '152,72000000', '', '', '', '', 'CH30', '68b02173-d2c6-473d-beb8-0ae332585d2f', 'POUP0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 POUPEE LILI\\par\r\n}\r\n', 'POUPEE LILI', '08/07/2017', '1,00000000', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 2, '27,59000000', '33,00000000', '0', '0', '27,59000000', '33,00000000', '', '', '', ''),
('FA0900000003', '08/07/2017', 'MOL0001', 'Monsieur', 'MOLINA Franēois', '43 rue de taverny', '', '', '', '95130', 'FRANCONVILLE LA GARENNE', 'VAL-D\'OISE', 'FR', 'MOLINA', 'Franēois', '01  55 66 99 88', '', '', '', 'MOLINA Franēois', 'Monsieur', '43 rue de taverny', '', '', '', '95130', 'FRANCONVILLE LA GARENNE', 'VAL-D\'OISE', 'FR', 'MOLINA', 'Franēois', '01  55 66 99 88', '', '', '', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '705,45000000', '843,72000000', '', '', '', '', '', '83665817-88a0-4b0d-a6ee-e8213e029729', 'ANIM0006', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 CLOWNS POUR LA JOURNEE\\par\r\n}\r\n', 'CLOWNS POUR LA JOURNEE', '08/07/2017', '1,00000000', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 3, '313,55000000', '375,01000000', '0', '0', '313,55000000', '375,01000000', '', '', '', ''),
('FA0900000003', '08/07/2017', 'MOL0001', 'Monsieur', 'MOLINA Franēois', '43 rue de taverny', '', '', '', '95130', 'FRANCONVILLE LA GARENNE', 'VAL-D\'OISE', 'FR', 'MOLINA', 'Franēois', '01  55 66 99 88', '', '', '', 'MOLINA Franēois', 'Monsieur', '43 rue de taverny', '', '', '', '95130', 'FRANCONVILLE LA GARENNE', 'VAL-D\'OISE', 'FR', 'MOLINA', 'Franēois', '01  55 66 99 88', '', '', '', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '705,45000000', '843,72000000', '', '', '', '', '', 'aa63f8da-1517-4609-8103-ccfbf9940bc2', 'DECO0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 DECOR BALLONS SIMPLES\\par\r\n}\r\n', 'DECOR BALLONS SIMPLES', '08/07/2017', '1,00000000', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 3, '52,26000000', '62,50000000', '0', '0', '52,26000000', '62,50000000', '', '', '', ''),
('FA0900000003', '08/07/2017', 'MOL0001', 'Monsieur', 'MOLINA Franēois', '43 rue de taverny', '', '', '', '95130', 'FRANCONVILLE LA GARENNE', 'VAL-D\'OISE', 'FR', 'MOLINA', 'Franēois', '01  55 66 99 88', '', '', '', 'MOLINA Franēois', 'Monsieur', '43 rue de taverny', '', '', '', '95130', 'FRANCONVILLE LA GARENNE', 'VAL-D\'OISE', 'FR', 'MOLINA', 'Franēois', '01  55 66 99 88', '', '', '', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '705,45000000', '843,72000000', '', '', '', '', '', '6608f4d1-2a5c-4b4a-aaf0-a9691c12ff3d', 'DECO0004', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 DECOR THEME BABAR\\par\r\n}\r\n', 'DECOR THEME BABAR', '08/07/2017', '1,00000000', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 3, '104,51000000', '124,99000000', '0', '0', '104,51000000', '124,99000000', '', '', '', ''),
('FA0900000003', '08/07/2017', 'MOL0001', 'Monsieur', 'MOLINA Franēois', '43 rue de taverny', '', '', '', '95130', 'FRANCONVILLE LA GARENNE', 'VAL-D\'OISE', 'FR', 'MOLINA', 'Franēois', '01  55 66 99 88', '', '', '', 'MOLINA Franēois', 'Monsieur', '43 rue de taverny', '', '', '', '95130', 'FRANCONVILLE LA GARENNE', 'VAL-D\'OISE', 'FR', 'MOLINA', 'Franēois', '01  55 66 99 88', '', '', '', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '705,45000000', '843,72000000', '', '', '', '', '', 'f34d111c-8dfd-48ca-96f9-cdbe7592c1bf', 'GOUT0002', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 GOUTER ELABORE\\par\r\nGo\\\'fbter compos\\\'e9 d\'une cr\\\'eape ou une part de gateau, une brochette de bonbons, barbe \\\'e0 papa et une boisson froide (soda ou jus de fruit au choix)\\par\r\n}\r\n', 'GOUTER ELABORE\nGoūter composé d\'une crźpe ou une part de gateau, une brochette de bonbons, barbe ą papa et une boisson froide (soda ou jus de fruit au choix)', '08/07/2017', '20,00000000', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 3, '10,45000000', '12,50000000', '0', '0', '209,00000000', '249,96000000', '', '', '', ''),
('FA0900000003', '08/07/2017', 'MOL0001', 'Monsieur', 'MOLINA Franēois', '43 rue de taverny', '', '', '', '95130', 'FRANCONVILLE LA GARENNE', 'VAL-D\'OISE', 'FR', 'MOLINA', 'Franēois', '01  55 66 99 88', '', '', '', 'MOLINA Franēois', 'Monsieur', '43 rue de taverny', '', '', '', '95130', 'FRANCONVILLE LA GARENNE', 'VAL-D\'OISE', 'FR', 'MOLINA', 'Franēois', '01  55 66 99 88', '', '', '', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '705,45000000', '843,72000000', '', '', '', '', '', 'd1476944-ee23-4655-ac64-e9baeed30f34', 'JEUX0003', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 CLUEDO HUMAIN\\par\r\n}\r\n', 'CLUEDO HUMAIN', '08/07/2017', '1,00000000', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 3, '26,13000000', '31,25000000', '0', '0', '26,13000000', '31,25000000', '', '', '', ''),
('FA0900000004', '08/07/2017', 'MAR0004', 'Madame', 'MARTINEAU Laura', '15 rue de l\'yser', '', '', '', '94400', 'VITRY SUR SEINE', 'VAL-DE-MARNE', 'FR', 'MARTINEAU', 'Laura', '', '', '', 'martineau.laura@aol.fr', 'MARTINEAU Laura', 'Madame', '15 rue de l\'yser', '', '', '', '94400', 'VITRY SUR SEINE', 'VAL-DE-MARNE', 'FR', 'MARTINEAU', 'Laura', '', '', '', 'martineau.laura@aol.fr', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '187,33000000', '224,05000000', '', '', '', '', '', 'f4a6ed64-131d-4689-b58e-460d91ea519f', '', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 Transf\\\'e9r\\\'e9 de : Bon de livraison N\\\'b0 BL0900000002 du 15/01/2009.\\par\r\n\\par\r\n}\r\n', 'Transféré de : Bon de livraison N° BL0900000002 du 15/01/2009.\n', '', '', '', '', 9, '', '', '', '', '', '', '', '', '', ''),
('FA0900000004', '08/07/2017', 'MAR0004', 'Madame', 'MARTINEAU Laura', '15 rue de l\'yser', '', '', '', '94400', 'VITRY SUR SEINE', 'VAL-DE-MARNE', 'FR', 'MARTINEAU', 'Laura', '', '', '', 'martineau.laura@aol.fr', 'MARTINEAU Laura', 'Madame', '15 rue de l\'yser', '', '', '', '94400', 'VITRY SUR SEINE', 'VAL-DE-MARNE', 'FR', 'MARTINEAU', 'Laura', '', '', '', 'martineau.laura@aol.fr', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '187,33000000', '224,05000000', '', '', '', '', '', '4c92793d-4588-4ed2-8fc3-51111a8f1a84', '', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 Commande par fax\\par\r\n}\r\n', 'Commande par fax', '', '', '', '', 4, '', '', '', '', '', '', '', '', '', ''),
('FA0900000004', '08/07/2017', 'MAR0004', 'Madame', 'MARTINEAU Laura', '15 rue de l\'yser', '', '', '', '94400', 'VITRY SUR SEINE', 'VAL-DE-MARNE', 'FR', 'MARTINEAU', 'Laura', '', '', '', 'martineau.laura@aol.fr', 'MARTINEAU Laura', 'Madame', '15 rue de l\'yser', '', '', '', '94400', 'VITRY SUR SEINE', 'VAL-DE-MARNE', 'FR', 'MARTINEAU', 'Laura', '', '', '', 'martineau.laura@aol.fr', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '187,33000000', '224,05000000', '', '', '', '', '', 'd1e53d09-c0a7-4338-b0c4-00a5c7e295e3', 'JUNG0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 JUNGLE MUSICAL PUZZLES\\par\r\n}\r\n', 'JUNGLE MUSICAL PUZZLES', '08/07/2017', '1,00000000', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 2, '20,14000000', '24,09000000', '0', '0', '20,14000000', '24,09000000', '', '', '', ''),
('FA0900000004', '08/07/2017', 'MAR0004', 'Madame', 'MARTINEAU Laura', '15 rue de l\'yser', '', '', '', '94400', 'VITRY SUR SEINE', 'VAL-DE-MARNE', 'FR', 'MARTINEAU', 'Laura', '', '', '', 'martineau.laura@aol.fr', 'MARTINEAU Laura', 'Madame', '15 rue de l\'yser', '', '', '', '94400', 'VITRY SUR SEINE', 'VAL-DE-MARNE', 'FR', 'MARTINEAU', 'Laura', '', '', '', 'martineau.laura@aol.fr', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '187,33000000', '224,05000000', '', '', '', '', '', '29b96973-3cdc-4c5e-8c6e-ed46f9d1313b', 'LA0G0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 LA GARE ANIMEE LIVRE DE 0 A 3 ANS\\par\r\n}\r\n', 'LA GARE ANIMEE LIVRE DE 0 A 3 ANS', '08/07/2017', '3,00000000', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 2, '4,60000000', '5,50000000', '0', '0', '13,80000000', '16,50000000', '', '', '', ''),
('FA0900000004', '08/07/2017', 'MAR0004', 'Madame', 'MARTINEAU Laura', '15 rue de l\'yser', '', '', '', '94400', 'VITRY SUR SEINE', 'VAL-DE-MARNE', 'FR', 'MARTINEAU', 'Laura', '', '', '', 'martineau.laura@aol.fr', 'MARTINEAU Laura', 'Madame', '15 rue de l\'yser', '', '', '', '94400', 'VITRY SUR SEINE', 'VAL-DE-MARNE', 'FR', 'MARTINEAU', 'Laura', '', '', '', 'martineau.laura@aol.fr', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '187,33000000', '224,05000000', '', '', '', '', '', '48fb76a2-3146-46b5-995a-d3c5aa6013fc', 'LE0C0002', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 LE CORPS HUMAIN LIVRE DE 9 ANS ET PLUS\\par\r\n}\r\n', 'LE CORPS HUMAIN LIVRE DE 9 ANS ET PLUS', '08/07/2017', '1,00000000', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 2, '11,03000000', '13,19000000', '0', '0', '11,03000000', '13,19000000', '', '', '', ''),
('FA0900000004', '08/07/2017', 'MAR0004', 'Madame', 'MARTINEAU Laura', '15 rue de l\'yser', '', '', '', '94400', 'VITRY SUR SEINE', 'VAL-DE-MARNE', 'FR', 'MARTINEAU', 'Laura', '', '', '', 'martineau.laura@aol.fr', 'MARTINEAU Laura', 'Madame', '15 rue de l\'yser', '', '', '', '94400', 'VITRY SUR SEINE', 'VAL-DE-MARNE', 'FR', 'MARTINEAU', 'Laura', '', '', '', 'martineau.laura@aol.fr', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '187,33000000', '224,05000000', '', '', '', '', '', 'bff725fd-85a2-45ca-b37b-33e05a24fa24', 'LION0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 LION SAUVAGE EN PELUCHE 23 CM\\par\r\n}\r\n', 'LION SAUVAGE EN PELUCHE 23 CM', '08/07/2017', '2,00000000', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 2, '18,30000000', '21,89000000', '0', '0', '36,60000000', '43,77000000', '', '', '', ''),
('FA0900000004', '08/07/2017', 'MAR0004', 'Madame', 'MARTINEAU Laura', '15 rue de l\'yser', '', '', '', '94400', 'VITRY SUR SEINE', 'VAL-DE-MARNE', 'FR', 'MARTINEAU', 'Laura', '', '', '', 'martineau.laura@aol.fr', 'MARTINEAU Laura', 'Madame', '15 rue de l\'yser', '', '', '', '94400', 'VITRY SUR SEINE', 'VAL-DE-MARNE', 'FR', 'MARTINEAU', 'Laura', '', '', '', 'martineau.laura@aol.fr', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '187,33000000', '224,05000000', '', '', '', '', '', '94667735-6b7f-4323-8faa-1c6758296341', 'MA0P0002', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 MA PLAGE ANIMEE LIVRE DE 0 A 3 ANS\\par\r\n}\r\n', 'MA PLAGE ANIMEE LIVRE DE 0 A 3 ANS', '08/07/2017', '3,00000000', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 2, '4,60000000', '5,50000000', '0', '0', '13,80000000', '16,50000000', '', '', '', ''),
('FA0900000004', '08/07/2017', 'MAR0004', 'Madame', 'MARTINEAU Laura', '15 rue de l\'yser', '', '', '', '94400', 'VITRY SUR SEINE', 'VAL-DE-MARNE', 'FR', 'MARTINEAU', 'Laura', '', '', '', 'martineau.laura@aol.fr', 'MARTINEAU Laura', 'Madame', '15 rue de l\'yser', '', '', '', '94400', 'VITRY SUR SEINE', 'VAL-DE-MARNE', 'FR', 'MARTINEAU', 'Laura', '', '', '', 'martineau.laura@aol.fr', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '187,33000000', '224,05000000', '', '', '', '', '', '74ab0372-bd94-42fd-8ff2-98cd630cf292', 'REFR0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 REFRIGERATEUR \\par\r\n}\r\n', 'REFRIGERATEUR ', '08/07/2017', '2,00000000', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 2, '41,30000000', '49,39000000', '0', '0', '82,60000000', '98,79000000', '', '', '', ''),
('FA0900000004', '08/07/2017', 'MAR0004', 'Madame', 'MARTINEAU Laura', '15 rue de l\'yser', '', '', '', '94400', 'VITRY SUR SEINE', 'VAL-DE-MARNE', 'FR', 'MARTINEAU', 'Laura', '', '', '', 'martineau.laura@aol.fr', 'MARTINEAU Laura', 'Madame', '15 rue de l\'yser', '', '', '', '94400', 'VITRY SUR SEINE', 'VAL-DE-MARNE', 'FR', 'MARTINEAU', 'Laura', '', '', '', 'martineau.laura@aol.fr', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '187,33000000', '224,05000000', '', '', '', '', '', '1f4874bd-edb2-41ff-b74d-1d62b31ce4cb', 'PAPI0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 PAPIER CADEAU ET ETIQUETTAGE\\par\r\n}\r\n', 'PAPIER CADEAU ET ETIQUETTAGE', '08/07/2017', '6,00000000', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 3, '1,56000000', '1,87000000', '0', '0', '9,36000000', '11,19000000', '', '', '', ''),
('FA0900000005', '08/07/2017', 'PET0001', 'CE', 'PETIT LOUP', '178 avenue des Landes', '', '', '', '95000', 'NEUVILLE SUR OISE', 'VAL-D\'OISE', 'FR', '', '', '', '', '', '', 'PETIT LOUP', 'CE', '178 avenue des Landes', '', '', '', '95000', 'NEUVILLE SUR OISE', 'VAL-D\'OISE', 'FR', '', '', '', '', '', '', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '3981,99000000', '4762,46000000', '', '', '', '', '', '1dde2fba-15a3-4091-b2ea-3e6cfd4bba05', 'GOUT0004', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 GOUTER DE 15H 18H POUR 10 ENFANTS\\par\r\n}\r\n', 'GOUTER DE 15H 18H POUR 10 ENFANTS', '08/07/2017', '1,00000000', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 3, '303,09000000', '362,50000000', '0', '0', '303,09000000', '362,50000000', '', '', '', ''),
('FA0900000005', '08/07/2017', 'PET0001', 'CE', 'PETIT LOUP', '178 avenue des Landes', '', '', '', '95000', 'NEUVILLE SUR OISE', 'VAL-D\'OISE', 'FR', '', '', '', '', '', '', 'PETIT LOUP', 'CE', '178 avenue des Landes', '', '', '', '95000', 'NEUVILLE SUR OISE', 'VAL-D\'OISE', 'FR', '', '', '', '', '', '', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '3981,99000000', '4762,46000000', '', '', '', '', '', 'd99c0695-136c-4d65-a9b3-324f4517a84d', 'STAG0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 STAGE DE D\'EQUITATION 1 SEMAINE  (5 JOURS]\\par\r\n}\r\n', 'STAGE DE D\'EQUITATION 1 SEMAINE  (5 JOURS]', '08/07/2017', '10,00000000', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 3, '326,09000000', '390,00000000', '0', '0', '3260,90000000', '3900,04000000', '', '', '', ''),
('FA0900000005', '08/07/2017', 'PET0001', 'CE', 'PETIT LOUP', '178 avenue des Landes', '', '', '', '95000', 'NEUVILLE SUR OISE', 'VAL-D\'OISE', 'FR', '', '', '', '', '', '', 'PETIT LOUP', 'CE', '178 avenue des Landes', '', '', '', '95000', 'NEUVILLE SUR OISE', 'VAL-D\'OISE', 'FR', '', '', '', '', '', '', 'FRANCE', '', '0', '0', '0', '0', '', '0', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 0, '3981,99000000', '4762,46000000', '', '', '', '', '', '2ce849dd-d94e-4e2e-8116-863d3bb7b985', 'STAG0004', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 STAGE DE PONEY CLUB JOURNEE : \\par\r\n- THEORIE, SOIN DES PONEYS,\\par\r\n- PROMENADE EN FOR\\\'caT,\\par\r\n- VOLTIGE,\\par\r\n- JEUX \\\'c9QUESTRES,\\par\r\n- REPAS ET GO\\\'dbTER AU PONEY CLUB.\\par\r\n}\r\n', 'STAGE DE PONEY CLUB JOURNEE : \n- THEORIE, SOIN DES PONEYS,\n- PROMENADE EN FORŹT,\n- VOLTIGE,\n- JEUX ÉQUESTRES,\n- REPAS ET GOŪTER AU PONEY CLUB.', '08/07/2017', '20,00000000', '19,60', '823f1060-71b2-419a-b70a-2107c554b35b', 3, '20,90000000', '25,00000000', '0', '0', '418,00000000', '499,93000000', '', '', '', '');

-- --------------------------------------------------------

--
-- Structure de la table `facture`
--

CREATE TABLE `facture` (
  `numero_document` varchar(12) NOT NULL,
  `date_document` date DEFAULT NULL,
  `code_client` varchar(8) DEFAULT NULL,
  `civilite_client` varchar(12) DEFAULT NULL,
  `nom_client` varchar(50) DEFAULT NULL,
  `adresse_facturation` varchar(50) DEFAULT NULL,
  `code_postal_facturation` varchar(10) DEFAULT NULL,
  `ville_facturation` varchar(50) DEFAULT NULL,
  `code_pays_facturation` varchar(5) DEFAULT NULL,
  `adresse_livraison` varchar(50) DEFAULT NULL,
  `code_postal_livraison` varchar(10) DEFAULT NULL,
  `ville_livraison` varchar(50) DEFAULT NULL,
  `code_pays_livraison` varchar(5) DEFAULT NULL,
  `remise_pct` decimal(5,2) DEFAULT NULL,
  `remise_montant` decimal(10,2) DEFAULT NULL,
  `escompte_pct` decimal(5,2) DEFAULT NULL,
  `escompte_montant` decimal(10,2) DEFAULT NULL,
  `frais_port_ht` decimal(10,2) DEFAULT NULL,
  `total_brut_ht` decimal(10,2) DEFAULT NULL,
  `total_ttc` decimal(10,2) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `code_commercial` varchar(7) DEFAULT NULL,
  `code_mode_reglement` varchar(4) DEFAULT NULL,
  `validation` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `facture`
--

INSERT INTO `facture` (`numero_document`, `date_document`, `code_client`, `civilite_client`, `nom_client`, `adresse_facturation`, `code_postal_facturation`, `ville_facturation`, `code_pays_facturation`, `adresse_livraison`, `code_postal_livraison`, `ville_livraison`, `code_pays_livraison`, `remise_pct`, `remise_montant`, `escompte_pct`, `escompte_montant`, `frais_port_ht`, `total_brut_ht`, `total_ttc`, `notes`, `code_commercial`, `code_mode_reglement`, `validation`) VALUES
('FA00000001', '2018-04-18', 'CCL00004', '', 'GESPI', '28 rue de la Fontaine de l\'Yvette', '91140', 'VILLEBON SUR YVETTE', 'FR', '28 rue de la Fontaine de l\'Yvette', '91140', 'VILLEBON SUR YVETTE', 'FR', 0.00, 0.00, 0.00, 0.00, 0.00, 162.00, 194.40, '', 'CO00001', '', 1),
('FA00000002', '2018-04-18', 'CCL00003', '', 'ECCA SARL', '', '75013', 'PARIS 13EME ARRONDISSEMENT', 'FR', '', '75013', 'PARIS 13EME ARRONDISSEMENT', 'FR', 0.00, 0.00, 0.00, 0.00, 0.00, 36.77, 44.12, '', 'CO00002', '', 1),
('FA00000003', '2018-04-18', 'BDM0001', 'CE', 'BDMANIA', '17 rue Centrale', '01200', 'BELLEGARDE SUR VALSERINE', 'FR', '17 rue Centrale', '01200', 'BELLEGARDE SUR VALSERINE', 'FR', 0.00, 0.00, 0.00, 0.00, 0.00, 371.03, 445.24, '', 'CO00001', '', 1),
('FA00000004', '2018-04-18', 'CCL00006', '', 'TONIER', '159 Boulevard de Créteil', '94100', 'ST MAUR DES FOSSES', 'FR', '159 Boulevard de Créteil', '94100', 'ST MAUR DES FOSSES', 'FR', 0.00, 0.00, 0.00, 0.00, 0.00, 209.63, 251.56, '', 'CO00001', '', 1),
('FA00000005', '2025-03-10', 'CCL00003', '', 'ECCA SARL', '', '75013', 'PARIS 13EME ARRONDISSEMENT', 'FR', '', '75013', 'PARIS 13EME ARRONDISSEMENT', 'FR', 2.00, 1.40, 1.00, 0.79, 10.00, 78.57, 88.16, '', 'CO00002', '', 1),
('FA0900000001', '2017-07-08', 'MAR0002', 'Monsieur', 'MARTIN Eric', '52 rue pasteur', '94120', 'FONTENAY SOUS BOIS', 'FR', '52 rue pasteur', '94120', 'FONTENAY SOUS BOIS', 'FR', 0.00, 0.00, 0.00, 0.00, 0.00, 857.00, 1024.97, '', '', '', 1),
('FA0900000002', '2017-07-08', 'RIN0001', 'Mademoiselle', 'RINGUAI Nathalie', '37 rue des archives', '75003', 'PARIS 3EME ARRONDISSEMENT', 'FR', '37 rue des archives', '75003', 'PARIS 3EME ARRONDISSEMENT', 'FR', 0.00, 0.00, 0.00, 0.00, 0.00, 127.69, 152.72, '', '', 'CH30', 1),
('FA0900000003', '2017-07-08', 'MOL0001', 'Monsieur', 'MOLINA Franēois', '43 rue de taverny', '95130', 'FRANCONVILLE LA GARENNE', 'FR', '43 rue de taverny', '95130', 'FRANCONVILLE LA GARENNE', 'FR', 0.00, 0.00, 0.00, 0.00, 0.00, 705.45, 843.72, '', '', '', 1),
('FA0900000004', '2017-07-08', 'MAR0004', 'Madame', 'MARTINEAU Laura', '15 rue de l\'yser', '94400', 'VITRY SUR SEINE', 'FR', '15 rue de l\'yser', '94400', 'VITRY SUR SEINE', 'FR', 0.00, 0.00, 0.00, 0.00, 0.00, 187.33, 224.05, '', '', '', 1),
('FA0900000005', '2017-07-08', 'PET0001', 'CE', 'PETIT LOUP', '178 avenue des Landes', '95000', 'NEUVILLE SUR OISE', 'FR', '178 avenue des Landes', '95000', 'NEUVILLE SUR OISE', 'FR', 0.00, 0.00, 0.00, 0.00, 0.00, 3981.99, 4762.46, '', '', '', 1);


-- --------------------------------------------------------

--
-- Structure de la table `factureligne`
--

CREATE TABLE `factureligne` (
  `id_factureLigne` int(11) NOT NULL,
  `numero_facture` varchar(12) DEFAULT NULL,
  `code_article` varchar(8) DEFAULT NULL,
  `description_article` text DEFAULT NULL,
  `quantite` decimal(10,2) DEFAULT NULL,
  `taux_tva` decimal(5,2) DEFAULT NULL,
  `prix_ht` decimal(10,2) DEFAULT NULL,
  `total_ligne_ht` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `factureligne`
--

INSERT INTO `factureligne` (`id_factureLigne`, `numero_facture`, `code_article`, `description_article`, `quantite`, `taux_tva`, `prix_ht`, `total_ligne_ht`) VALUES
(1, 'FA00000001', 'ANIM0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 ANIMATEUR/ANIMATRICE POUR LA JOURNEE\\par\r\n}\r\n', 1.00, 20.00, 162.00, 162.00),
(2, 'FA00000002', 'ACTI0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 FIGURINE HYBRIDE\\par\r\n}\r\n', 1.00, 20.00, 36.77, 36.77),
(3, 'FA00000003', 'ANIM0004', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 PERE NOEL POUR LA JOURNEE\\par\r\n}\r\n', 1.00, 20.00, 209.03, 209.03),
(4, 'FA00000003', 'ANIM0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 ANIMATEUR/ANIMATRICE POUR LA JOURNEE\\par\r\n}\r\n', 1.00, 20.00, 162.00, 162.00),
(5, 'FA00000004', 'ANIM0002', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 ASSISTANT/ASSISTANTE POUR LA JOURNEE\\par\r\n}\r\n', 1.00, 20.00, 209.63, 209.63),
(6, 'FA00000005', 'ACTI0002', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 VOITURE HERO\\par\r\n}\r\n', 2.00, 20.00, 17.47, 33.20),
(7, 'FA00000005', 'ACTI0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 FIGURINE HYBRIDE\\par\r\n}\r\n', 1.00, 5.50, 36.77, 36.77),
(8, 'FA0900000001', 'ANIM0002', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 ASSISTANT/ASSISTANTE POUR LA JOURNEE\\par\r\n}\r\n', 1.00, 19.60, 62.71, 62.71),
(9, 'FA0900000001', 'ANIM0003', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 MAGICIEN POUR LA JOURNEE\\par\r\n}\r\n', 1.00, 19.60, 365.80, 365.80),
(10, 'FA0900000001', 'ATEL0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 ATELIER CREATION\\par\r\n}\r\n', 1.00, 19.60, 31.35, 31.35),
(11, 'FA0900000001', 'ATEL0004', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 ATELIER SCULPTURE SUR BALLONS\\par\r\n}\r\n', 1.00, 19.60, 31.35, 31.35),
(12, 'FA0900000001', 'DECO0002', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 DECOR BALLONS  HELIUM [100 BALLONS)\\par\r\n}\r\n', 1.00, 19.60, 156.78, 156.78),
(13, 'FA0900000001', 'DECO0004', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 DECOR THEME BABAR\\par\r\n}\r\n', 1.00, 19.60, 104.51, 104.51),
(14, 'FA0900000001', 'GOUT0002', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 GOUTER ELABORE\\par\r\nGo\\\'fbter compos\\\'e9 d\'une cr\\\'eape ou une part de gateau, une brochette de bonbons, barbe \\\'e0 papa et une boisson froide (soda ou jus de fruit au choix)\\par\r\n}\r\n', 10.00, 19.60, 10.45, 104.50),
(15, 'FA0900000002', '', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 Transf\\\'e9r\\\'e9 de : Bon de livraison N\\\'b0 BL0900000001 du 05/01/2009.\\par\r\n\\par\r\n}\r\n', NULL, NULL, NULL, NULL),
(16, 'FA0900000002', '', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 Commande par t\\\'e9l\\\'e9phone\\par\r\n}\r\n', NULL, NULL, NULL, NULL),
(17, 'FA0900000002', 'OURS0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 OURS BEIGE 23 CM \\par\r\n}\r\n', 1.00, 19.60, 14.61, 14.61),
(18, 'FA0900000002', 'PACO0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 PYJAMA BICOLOR\\par\r\n}\r\n', 1.00, 19.60, 6.42, 6.42),
(19, 'FA0900000002', 'PEIG0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 PEIGNOIR DE BAINS\\par\r\n}\r\n', 1.00, 19.60, 41.39, 41.39),
(20, 'FA0900000002', 'POCH0002', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 POCHETTE SURPRISE 6 EUROS PAR ENFANT\\par\r\n}\r\n', 6.00, 19.60, 6.28, 37.68),
(21, 'FA0900000002', 'POUP0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 POUPEE LILI\\par\r\n}\r\n', 1.00, 19.60, 27.59, 27.59),
(22, 'FA0900000003', 'ANIM0006', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 CLOWNS POUR LA JOURNEE\\par\r\n}\r\n', 1.00, 19.60, 313.55, 313.55),
(23, 'FA0900000003', 'DECO0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 DECOR BALLONS SIMPLES\\par\r\n}\r\n', 1.00, 19.60, 52.26, 52.26),
(24, 'FA0900000003', 'DECO0004', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 DECOR THEME BABAR\\par\r\n}\r\n', 1.00, 19.60, 104.51, 104.51),
(25, 'FA0900000003', 'GOUT0002', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 GOUTER ELABORE\\par\r\nGo\\\'fbter compos\\\'e9 d\'une cr\\\'eape ou une part de gateau, une brochette de bonbons, barbe \\\'e0 papa et une boisson froide (soda ou jus de fruit au choix)\\par\r\n}\r\n', 20.00, 19.60, 10.45, 209.00),
(26, 'FA0900000003', 'JEUX0003', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 CLUEDO HUMAIN\\par\r\n}\r\n', 1.00, 19.60, 26.13, 26.13),
(27, 'FA0900000004', '', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 Transf\\\'e9r\\\'e9 de : Bon de livraison N\\\'b0 BL0900000002 du 15/01/2009.\\par\r\n\\par\r\n}\r\n', NULL, NULL, NULL, NULL),
(28, 'FA0900000004', '', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 Commande par fax\\par\r\n}\r\n', NULL, NULL, NULL, NULL),
(29, 'FA0900000004', 'JUNG0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 JUNGLE MUSICAL PUZZLES\\par\r\n}\r\n', 1.00, 19.60, 20.14, 20.14),
(30, 'FA0900000004', 'LA0G0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 LA GARE ANIMEE LIVRE DE 0 A 3 ANS\\par\r\n}\r\n', 3.00, 19.60, 4.60, 13.80),
(31, 'FA0900000004', 'LE0C0002', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 LE CORPS HUMAIN LIVRE DE 9 ANS ET PLUS\\par\r\n}\r\n', 1.00, 19.60, 11.03, 11.03),
(32, 'FA0900000004', 'LION0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 LION SAUVAGE EN PELUCHE 23 CM\\par\r\n}\r\n', 2.00, 19.60, 18.30, 36.60),
(33, 'FA0900000004', 'MA0P0002', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 MA PLAGE ANIMEE LIVRE DE 0 A 3 ANS\\par\r\n}\r\n', 3.00, 19.60, 4.60, 13.80),
(34, 'FA0900000004', 'REFR0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 REFRIGERATEUR \\par\r\n}\r\n', 2.00, 19.60, 41.30, 82.60),
(35, 'FA0900000004', 'PAPI0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 PAPIER CADEAU ET ETIQUETTAGE\\par\r\n}\r\n', 6.00, 19.60, 1.56, 9.36),
(36, 'FA0900000005', 'GOUT0004', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 GOUTER DE 15H 18H POUR 10 ENFANTS\\par\r\n}\r\n', 1.00, 19.60, 303.09, 303.09),
(37, 'FA0900000005', 'STAG0001', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 STAGE DE D\'EQUITATION 1 SEMAINE  (5 JOURS]\\par\r\n}\r\n', 10.00, 19.60, 326.09, 3260.90),
(38, 'FA0900000005', 'STAG0004', '{\\rtf1\\ansi\\ansicpg1252\\deff0\\deflang1036{\\fonttbl{\\f0\\fnil\\fcharset0 Microsoft Sans Serif;}}\r\n\\viewkind4\\uc1\\pard\\f0\\fs17 STAGE DE PONEY CLUB JOURNEE : \\par\r\n- THEORIE, SOIN DES PONEYS,\\par\r\n- PROMENADE EN FOR\\\'caT,\\par\r\n- VOLTIGE,\\par\r\n- JEUX \\\'c9QUESTRES,\\par\r\n- REPAS ET GO\\\'dbTER AU PONEY CLUB.\\par\r\n}\r\n', 20.00, 19.60, 20.90, 418.00);

--
-- Déclencheurs `facture`
--
DELIMITER $$

-- 1. TRIGGER AVANT INSERTION FACTURE (Numérotation Auto)
DROP TRIGGER IF EXISTS `before_insert_facture`$$
CREATE TRIGGER `before_insert_facture` BEFORE INSERT ON `facture` FOR EACH ROW 
BEGIN
    DECLARE next_num INT;
    DECLARE prefix VARCHAR(2);
    DECLARE current_year CHAR(4);
    
    -- Date par défaut
    IF NEW.date_document IS NULL THEN 
        SET NEW.date_document = CURDATE(); 
    END IF;

    -- Génération du numéro : FA ou AV + Année + Compteur
    IF NEW.numero_document IS NULL OR NEW.numero_document = '' THEN
        SET current_year = YEAR(NEW.date_document);
        
        -- Choix du préfixe
        IF NEW.total_ttc < 0 THEN 
            SET prefix = 'AV'; 
        ELSE 
            SET prefix = 'FA'; 
        END IF;
        
        -- Compteur Max + 1
        SELECT COALESCE(MAX(CAST(SUBSTRING(numero_document, 7) AS UNSIGNED)), 0) + 1 
        INTO next_num
        FROM facture
        WHERE SUBSTRING(numero_document, 1, 2) = prefix
        AND SUBSTRING(numero_document, 3, 4) = current_year;
        
        SET NEW.numero_document = CONCAT(prefix, current_year, LPAD(next_num, 3, '0'));
    END IF;
END$$

-- 2. TRIGGER AVANT UPDATE FACTURE (Protection)
DROP TRIGGER IF EXISTS `before_update_facture`$$
CREATE TRIGGER `before_update_facture` BEFORE UPDATE ON `facture` FOR EACH ROW 
BEGIN
    -- Interdire modif numéro
    IF OLD.numero_document != NEW.numero_document THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Modification du numéro de facture interdite';
    END IF;
    
    -- Si validé, protection stricte
    IF OLD.validation = 1 THEN
        -- On autorise uniquement quelques cas techniques, sinon on bloque
        IF OLD.nom_client != NEW.nom_client OR OLD.total_ttc != NEW.total_ttc THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Facture validée : Modification interdite';
        END IF;
    END IF;
END$$

-- 3. TRIGGER AVANT DELETE FACTURE (Protection)
DROP TRIGGER IF EXISTS `before_delete_facture`$$
CREATE TRIGGER `before_delete_facture` BEFORE DELETE ON `facture` FOR EACH ROW 
BEGIN
    IF OLD.validation = 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Suppression interdite - La facture est validée';
    END IF;
END$$

-- 4. TRIGGERS CALCUL AUTO (Sur factureLigne)
DROP TRIGGER IF EXISTS `after_factureligne_insert`$$
CREATE TRIGGER `after_factureligne_insert` AFTER INSERT ON `factureligne` FOR EACH ROW 
BEGIN
    UPDATE facture 
    SET total_brut_ht = (SELECT COALESCE(SUM(total_ligne_ht), 0) FROM factureligne WHERE numero_facture = NEW.numero_facture)
    WHERE numero_document = NEW.numero_facture;
END$$

DROP TRIGGER IF EXISTS `after_factureligne_update`$$
CREATE TRIGGER `after_factureligne_update` AFTER UPDATE ON `factureligne` FOR EACH ROW 
BEGIN
    UPDATE facture 
    SET total_brut_ht = (SELECT COALESCE(SUM(total_ligne_ht), 0) FROM factureligne WHERE numero_facture = NEW.numero_facture)
    WHERE numero_document = NEW.numero_facture;
END$$

DROP TRIGGER IF EXISTS `after_factureligne_delete`$$
CREATE TRIGGER `after_factureligne_delete` AFTER DELETE ON `factureligne` FOR EACH ROW 
BEGIN
    UPDATE facture 
    SET total_brut_ht = (SELECT COALESCE(SUM(total_ligne_ht), 0) FROM factureligne WHERE numero_facture = OLD.numero_facture)
    WHERE numero_document = OLD.numero_facture;
END$$

-- 5. TRIGGERS PROTECTION LIGNE (Sur factureLigne)
DROP TRIGGER IF EXISTS `before_update_factureligne`$$
CREATE TRIGGER `before_update_factureligne` BEFORE UPDATE ON `factureligne` FOR EACH ROW 
BEGIN
    DECLARE facture_validee TINYINT;
    SELECT validation INTO facture_validee FROM facture WHERE numero_document = OLD.numero_facture;
    
    IF facture_validee = 1 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Modification ligne interdite - Facture validée';
    END IF;
END$$

DROP TRIGGER IF EXISTS `before_delete_factureligne`$$
CREATE TRIGGER `before_delete_factureligne` BEFORE DELETE ON `factureligne` FOR EACH ROW 
BEGIN
    DECLARE facture_validee TINYINT;
    SELECT validation INTO facture_validee FROM facture WHERE numero_document = OLD.numero_facture;
    
    IF facture_validee = 1 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Suppression ligne interdite - Facture validée';
    END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Doublure de structure pour la vue `vue_articles`
-- (Voir ci-dessous la vue réelle)
--
CREATE TABLE `vue_articles` (
`code_article` varchar(20)
,`nom` varchar(100)
,`prix_achat_ht` decimal(12,2)
,`prix_vente_ht` decimal(12,2)
,`taux_tva` decimal(5,2)
,`prix_vente_ttc` decimal(22,8)
,`description` text
,`unite_vente` varchar(10)
,`article_actif` tinyint(1)
,`code_categorie` varchar(20)
);

-- --------------------------------------------------------

--
-- Doublure de structure pour la vue `vue_devis`
-- (Voir ci-dessous la vue réelle)
--
CREATE TABLE `vue_devis` (
`numero` varchar(12)
,`nom_client` varchar(50)
,`date_devis` date
,`code_commercial` varchar(10)
,`code_mode_payement` varchar(10)
,`etat_devis` tinyint(1)
,`brut_ht` decimal(10,2)
,`frais_port_ht` decimal(10,2)
,`pourcentage_remise` decimal(5,2)
,`montant_remise` decimal(10,2)
,`montant_escompte` decimal(10,2)
,`total_facture_ttc` decimal(10,2)
,`total_ht_calcule` decimal(32,2)
,`total_tva_calcule` decimal(41,8)
,`total_ttc_calcule` decimal(42,8)
);

-- --------------------------------------------------------

--
-- Doublure de structure pour la vue `vue_devisligne`
-- (Voir ci-dessous la vue réelle)
--
CREATE TABLE `vue_devisligne` (
`id_ligne` varchar(36)
,`numero_devis` varchar(12)
,`code_article` varchar(8)
,`description` text
,`quantite` decimal(10,2)
,`pv_ht` decimal(10,2)
,`taux_tva` decimal(5,2)
,`total_ligne_ht` decimal(10,2)
,`montant_tva_calcule` decimal(19,8)
,`total_ligne_ttc` decimal(20,8)
);

-- --------------------------------------------------------

--
-- Doublure de structure pour la vue `vue_facture`
-- (Voir ci-dessous la vue réelle)
--
CREATE TABLE `vue_facture` (
`numero_document` varchar(12)
,`nom_client` varchar(50)
,`date_document` date
,`brut_ht` decimal(10,2)
,`remise_pct` decimal(5,2)
,`remise_montant` decimal(10,2)
,`escompte_pct` decimal(5,2)
,`escompte_montant` decimal(10,2)
,`frais_port_ht` decimal(10,2)
,`total_facture_ttc` decimal(10,2)
,`code_commercial` varchar(7)
,`code_mode_reglement` varchar(4)
,`total_ht_calcule` decimal(32,2)
,`total_ttc_calcule` decimal(42,8)
,`total_tva_calcule` decimal(41,8)
);

-- --------------------------------------------------------

--
-- Doublure de structure pour la vue `vue_factureligne`
-- (Voir ci-dessous la vue réelle)
--
CREATE TABLE `vue_factureligne` (
`id_factureLigne` int(11)
,`numero_facture` varchar(12)
,`code_article` varchar(8)
,`description_article` text
,`quantite` decimal(10,2)
,`prix_ht` decimal(10,2)
,`taux_tva` decimal(5,2)
,`total_ligne_ht` decimal(10,2)
,`montant_tva_calcule` decimal(19,8)
,`total_ligne_ttc` decimal(20,8)
);

-- --------------------------------------------------------

--
-- Structure de la vue `vue_articles`
--
DROP TABLE IF EXISTS `vue_articles`;

CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `vue_articles`  AS SELECT `article`.`code_article` AS `code_article`, `article`.`nom` AS `nom`, `article`.`prix_achat_ht` AS `prix_achat_ht`, `article`.`prix_vente_ht` AS `prix_vente_ht`, `article`.`taux_tva` AS `taux_tva`, `article`.`prix_vente_ht`* (1 + `article`.`taux_tva` / 100) AS `prix_vente_ttc`, `article`.`description` AS `description`, `article`.`unite_vente` AS `unite_vente`, `article`.`article_actif` AS `article_actif`, `article`.`code_categorie` AS `code_categorie` FROM `article` ;

-- --------------------------------------------------------

--
-- Structure de la vue `vue_devis`
--
DROP TABLE IF EXISTS `vue_devis`;

CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `vue_devis`  AS SELECT `d`.`numero` AS `numero`, `d`.`nom_client` AS `nom_client`, `d`.`date_devis` AS `date_devis`, `d`.`code_commercial` AS `code_commercial`, `d`.`code_mode_payement` AS `code_mode_payement`, `d`.`etat_devis` AS `etat_devis`, `d`.`total_brut_ht` AS `brut_ht`, `d`.`frais_port_ht` AS `frais_port_ht`, `d`.`pourcentage_remise` AS `pourcentage_remise`, `d`.`montant_remise` AS `montant_remise`, `d`.`montant_escompte` AS `montant_escompte`, `d`.`total_ttc` AS `total_facture_ttc`, coalesce(sum(`dl`.`total_ligne_ht`),0) AS `total_ht_calcule`, coalesce(sum(`dl`.`montant_tva_calcule`),0) AS `total_tva_calcule`, coalesce(sum(`dl`.`total_ligne_ttc`),0) AS `total_ttc_calcule` FROM (`devis` `d` left join `vue_devisligne` `dl` on(`d`.`numero` = `dl`.`numero_devis`)) GROUP BY `d`.`numero`, `d`.`nom_client`, `d`.`date_devis`, `d`.`code_commercial`, `d`.`code_mode_payement`, `d`.`etat_devis`, `d`.`total_brut_ht`, `d`.`frais_port_ht`, `d`.`pourcentage_remise`, `d`.`montant_remise`, `d`.`montant_escompte`, `d`.`total_ttc` ;

-- --------------------------------------------------------

--
-- Structure de la vue `vue_devisligne`
--
DROP TABLE IF EXISTS `vue_devisligne`;

CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `vue_devisligne`  AS SELECT `devisLigne`.`id_ligne` AS `id_ligne`, `devisLigne`.`numero_devis` AS `numero_devis`, `devisLigne`.`code_article` AS `code_article`, `devisLigne`.`description` AS `description`, `devisLigne`.`quantite` AS `quantite`, `devisLigne`.`pv_ht` AS `pv_ht`, `devisLigne`.`taux_tva` AS `taux_tva`, `devisLigne`.`montant_net_ht` AS `total_ligne_ht`, `devisLigne`.`montant_net_ht`* (`devisLigne`.`taux_tva` / 100) AS `montant_tva_calcule`, `devisLigne`.`montant_net_ht`* (1 + `devisLigne`.`taux_tva` / 100) AS `total_ligne_ttc` FROM `devisLigne` ;

-- --------------------------------------------------------

--
-- Structure de la vue `vue_facture`
--
DROP TABLE IF EXISTS `vue_facture`;

CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `vue_facture`  AS SELECT `f`.`numero_document` AS `numero_document`, `f`.`nom_client` AS `nom_client`, `f`.`date_document` AS `date_document`, `f`.`total_brut_ht` AS `brut_ht`, `f`.`remise_pct` AS `remise_pct`, `f`.`remise_montant` AS `remise_montant`, `f`.`escompte_pct` AS `escompte_pct`, `f`.`escompte_montant` AS `escompte_montant`, `f`.`frais_port_ht` AS `frais_port_ht`, `f`.`total_ttc` AS `total_facture_ttc`, `f`.`code_commercial` AS `code_commercial`, `f`.`code_mode_reglement` AS `code_mode_reglement`, coalesce(sum(`fl`.`total_ligne_ht`),0) AS `total_ht_calcule`, coalesce(sum(`fl`.`total_ligne_ttc`),0) AS `total_ttc_calcule`, coalesce(sum(`fl`.`montant_tva_calcule`),0) AS `total_tva_calcule` FROM (`facture` `f` left join `vue_factureligne` `fl` on(`f`.`numero_document` = `fl`.`numero_facture`)) GROUP BY `f`.`numero_document`, `f`.`nom_client`, `f`.`date_document`, `f`.`total_brut_ht`, `f`.`remise_pct`, `f`.`remise_montant`, `f`.`escompte_pct`, `f`.`escompte_montant`, `f`.`frais_port_ht`, `f`.`total_ttc`, `f`.`code_commercial`, `f`.`code_mode_reglement` ;

-- --------------------------------------------------------

--
-- Structure de la vue `vue_factureligne`
--
DROP TABLE IF EXISTS `vue_factureligne`;

CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `vue_factureligne`  AS SELECT `factureligne`.`id_factureLigne` AS `id_factureLigne`, `factureligne`.`numero_facture` AS `numero_facture`, `factureligne`.`code_article` AS `code_article`, `factureligne`.`description_article` AS `description_article`, `factureligne`.`quantite` AS `quantite`, `factureligne`.`prix_ht` AS `prix_ht`, `factureligne`.`taux_tva` AS `taux_tva`, `factureligne`.`total_ligne_ht` AS `total_ligne_ht`, `factureligne`.`total_ligne_ht`* (`factureligne`.`taux_tva` / 100) AS `montant_tva_calcule`, `factureligne`.`total_ligne_ht`* (1 + `factureligne`.`taux_tva` / 100) AS `total_ligne_ttc` FROM `factureligne` ;

--
-- Index pour les tables déchargées
--

--
-- Index pour la table `adresse_facturation`
--
ALTER TABLE `adresse_facturation`
  ADD PRIMARY KEY (`code_tiers`);

--
-- Index pour la table `adresse_livraison`
--
ALTER TABLE `adresse_livraison`
  ADD PRIMARY KEY (`code_tiers`);

--
-- Index pour la table `article`
--
ALTER TABLE `article`
  ADD PRIMARY KEY (`code_article`),
  ADD KEY `code_categorie` (`code_categorie`);

--
-- Index pour la table `categoriearticle`
--
ALTER TABLE `categoriearticle`
  ADD PRIMARY KEY (`code_categorie`);

--
-- Index pour la table `client`
--
ALTER TABLE `client`
  ADD PRIMARY KEY (`code_tiers`);

--
-- Index pour la table `devis`
--
ALTER TABLE `devis`
  ADD PRIMARY KEY (`numero`);

--
-- Index pour la table `devisLigne`
--
ALTER TABLE `devisLigne`
  ADD PRIMARY KEY (`id_ligne`);

--
-- Index pour la table `facture`
--
ALTER TABLE `facture`
  ADD PRIMARY KEY (`numero_document`);

--
-- Index pour la table `factureligne`
--
ALTER TABLE `factureligne`
  ADD PRIMARY KEY (`id_factureLigne`),
  ADD KEY `numero_facture` (`numero_facture`);

--
-- AUTO_INCREMENT pour les tables déchargées
--

--
-- AUTO_INCREMENT pour la table `factureligne`
--
ALTER TABLE `factureligne`
  MODIFY `id_factureLigne` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=64;

--
-- Contraintes pour les tables déchargées
--

--
-- Contraintes pour la table `article`
--
ALTER TABLE `article`
  ADD CONSTRAINT `article_ibfk_1` FOREIGN KEY (`code_categorie`) REFERENCES `categoriearticle` (`code_categorie`);

--
-- Contraintes pour la table `factureligne`
--
ALTER TABLE `factureligne`
  ADD CONSTRAINT `factureligne_ibfk_1` FOREIGN KEY (`numero_facture`) REFERENCES `facture` (`numero_document`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
