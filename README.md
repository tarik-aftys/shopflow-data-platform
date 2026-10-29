# ShopFlow Data Platform

ShopFlow Data Platform est un projet de data engineering qui construit un pipeline ELT de bout en bout à partir du dataset e-commerce Olist.

Le projet utilise **Apache Airflow** pour l’orchestration, **PostgreSQL** pour le stockage, **dbt** pour les transformations, et **Docker Compose** pour exécuter l’environnement local.

Objectif : charger des fichiers CSV bruts, les transformer en modèles analytiques (staging, intermediate, marts), puis produire des tables prêtes pour l’analyse métier.

## Fonctionnalités principales

- Orchestration automatisée du pipeline avec Airflow (ingestion + transformations).
- Chargement des données brutes CSV dans PostgreSQL.
- Transformations dbt en couches :
  - **staging** : nettoyage et standardisation des données,
  - **intermediate** : logique métier et enrichissement,
  - **marts** : tables analytiques finales.
- Snapshots dbt pour le suivi historique (SCD Type 2).
- Exécution locale reproductible via Docker Compose.

## Forme du projet (structure)

Le projet suit une architecture en couches :

1. **Raw** : données sources brutes.
2. **Staging** : préparation technique.
3. **Intermediate** : calculs métier.
4. **Marts** : dimensions et faits prêts pour l’analyse.

Cette organisation facilite la maintenance, les tests de qualité et la réutilisation des modèles analytiques.
