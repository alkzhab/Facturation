# Projet Facturation

Ce projet gère la **facturation client** de manière automatisée et sécurisée.  
Il permet de **transformer les données brutes reçues des clients**, de les intégrer dans les tables internes, et de fournir un **site web pour la gestion client et la génération d’avoirs**.

## Fonctionnalités

### Traitement des données
- **Import des données brutes** : Récupère les fichiers ou flux envoyés par les clients.  
- **Transformation et adaptation** : Ajuste les données pour les intégrer dans nos tables internes.  
- **Intégrité des données** : Utilisation de **procédures stockées** et **triggers** pour assurer l’immuabilité des tables et éviter toute modification non autorisée.

### Gestion via le site web
- **Modification des clients** : Met à jour les informations clients de manière sécurisée.  
- **Génération d’avoirs** : Crée automatiquement les avoirs selon les modifications et annulations de factures.  
- **Dashboard administrateur** : Visualise les données clients et l’état des facturations.

## Technologies utilisées
- **Base de données** : SQL (MySQL)
- **Procédures stockées & Triggers** : Gestion de l’intégrité et immuabilité des données  
- **Frontend** : HTML, CSS, JavaScript  
- **Backend** : PHP
