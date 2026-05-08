# Projet Data Warehouse F1 — DW_F1

## Vue d'ensemble

Ce projet met en place un **entrepôt de données complet** (Data Warehouse) pour la **Formule 1**, couvrant 70+ ans de données (1950-2024).

**Objectif :** Centraliser et transformer des données multi-sources hétérogènes (CSV, Excel, API JSON) via un pipeline ETL avec **SSIS**, les charger dans **SQL Server**, et les analyser via des **dashboards interactifs Power BI**.

---

## Structure du projet

```
DW/
├── README.md                           # Ce fichier
├── ApiStandingsScript.cs               # Script C# SSIS (extraction API Jolpica)
├── F1_Dashboard.pbix                   # Dashboard Power BI complet
├── csv files/                          # Fichiers CSV sources (Kaggle Ergast)
│   ├── circuits.csv
│   ├── constructors.csv
│   ├── drivers.csv
│   ├── races.csv
│   └── results.csv
├── excel/                              # Fichiers Excel
│   └── F1_Season_Standings.xlsx        # Données championnat par saison (2009-2024)
└── sql/
    ├── 00_README.sql                   # Guide d'exécution des scripts SQL
    ├── 01_create_database_and_tables.sql   # Création base + tables
    ├── 02_alter_fixes.sql              # Corrections ALTER TABLE
    ├── 03_api_standings_reference.sql  # Référence données API
    ├── 04_sql_agent_job.sql            # Job SQL Server Agent (scheduler)
    └── 05_validation_queries.sql       # Requêtes de vérification
```

---

## Sources de données

| Source | Type | Contenu |
|--------|------|---------|
| **Kaggle Ergast** | 5 fichiers CSV | 861 pilotes, 1 125 courses, 26 759 résultats (1950-2024) |
| **Excel manuel** | F1_Season_Standings.xlsx | 16 saisons (2009-2024), classements pilotes/écuries |
| **API Jolpica** | JSON REST | Classements 2023 (22 pilotes, points, victoires) |

---

## Architecture — Data Warehouse DW_F1

### Schéma en étoile

```
                    ┌─── DIM_Circuits
                    │
DIM_Drivers ────────┤
                    │─── FACT_Results ─────┤─── DIM_Constructors
                    │
                    └─── DIM_Races
                    
DIM_Season_Standings (optionnel, relation manuelle sur year)
```

### Tables

**Dimensions (descriptives) :**
- `DIM_Circuits` (77) — circuits, localisation GPS, altitudes
- `DIM_Drivers` (861) — pilotes, dates de naissance, nationalités
- `DIM_Constructors` (212) — écuries, nationalités
- `DIM_Races` (1 125) — courses, sessions (FP1, FP2, FP3, quali, sprint)
- `DIM_Season_Standings` (16) — champions par saison 2009-2024

**Faits (mesures) :**
- `FACT_Results` (26 759) — résultats courses (points, positions, temps, laps)

**Staging (zones tampons) :**
- `STG_Drivers`, `STG_Races`, `STG_Results` — intermédiaires CSV
- `STG_API_Standings` — classements API Jolpica

---

## Installation & Exécution

### 1. Préparer la base SQL Server

```sql
-- Lancer les scripts dans cet ordre (SSMS) :
sql/01_create_database_and_tables.sql
sql/02_alter_fixes.sql
```

**Résultat attendu :** Base `DW_F1` créée, 7 tables + relations.

### 2. Charger les données via SSIS

Créer **4 packages SSIS** dans Visual Studio 2022 :

| Package | Rôle | Source |
|---------|------|--------|
| `Load_CSV_Sources.dtsx` | Charge 5 CSV Kaggle | DIM_* + FACT_Results |
| `Load_Excel_Standings.dtsx` | Charge Excel | DIM_Season_Standings |
| `Load_API_Jolpica.dtsx` | Charge CSV API | STG_API_Standings |
| `Master.dtsx` | Orchestre les 3 précédents | Execute Package Task × 3 |

**Point clé : Script C# (`ApiStandingsScript.cs`)**
- Récupère l'API JSON Jolpica en HTTP GET
- Parse les classements pilotes 2023 avec Regex
- Génère `api_standings.csv` (22 lignes)
- Gérer les `NULL` (format MySQL `\N`)

### 3. Valider les chargements

```sql
-- Lancer SSMS :
sql/05_validation_queries.sql
```

**Résultat attendu :**
```
DIM_Circuits          → 77 lignes
DIM_Constructors      → 212 lignes
DIM_Drivers           → 861 lignes
DIM_Races             → 1 125 lignes
DIM_Season_Standings  → 16 lignes
STG_API_Standings     → 22 lignes
FACT_Results          → 26 759 lignes
```

### 4. Configurer SQL Server Agent (optionnel)

```sql
-- Lancer SSMS (base msdb) :
sql/04_sql_agent_job.sql
```

Crée un job `ETL_F1_Daily_Load` exécutant `Master.dtsx` chaque jour à minuit.

### 5. Connexion Power BI Desktop

1. Accueil → Obtenir les données → SQL Server
2. Serveur : `localhost`
3. Base : `DW_F1`
4. Mode : **Import**
5. Tables : `DIM_*` + `FACT_Results`

**Power BI détecte automatiquement les relations (FK).**

---

## Mesures DAX (Power BI)

```dax
TotalPoints       = SUM(FACT_Results[points])
TotalWins         = CALCULATE(COUNTROWS(FACT_Results), FACT_Results[position] = 1)
Podiums           = CALCULATE(COUNTROWS(FACT_Results), FACT_Results[position] <= 3)
WinRate           = DIVIDE([TotalWins], COUNTROWS(FACT_Results), 0)
AvgPointsPerRace  = DIVIDE([TotalPoints], COUNTROWS(FACT_Results), 0)
```

---

## Dashboards Power BI

### Dashboard 1: Driver Performance
- Graphique barres : Top 10 pilotes (points carrière)
- Cartes : Victoires (1 128), Podiums (14 000+)
- Filtre : Année

### Dashboard 2: Constructor Battle
- Barres : Écuries (Ferrari 249 vict., McLaren 185 vict.)
- Camembert : Part des victoires
- Filtre : Année

### Dashboard 3: Circuit Analysis
- Carte Bing : 77 circuits mondiaux (GPS)
- Histogramme : Circuits par points
- Filtre : Pays

### Dashboard 4: Season Overview
- Courbes : Évolution points/année
- Barres : Victoires/saison
- Cartes : Moyennes/saison
- Filtre : Champion

---

## Points techniques clés

### Gestion des NULL
- Fichiers Kaggle CSV encodent NULL comme `\N` (convention MySQL)
- SSIS : Convertir via `Derived Column` → `[col] == "\\N" ? NULL(...) : [col]`

### Unicode (NVARCHAR)
- Tous les types texte → `NVARCHAR` (SQL Server)
- SSIS Data Flow → `DT_WSTR` (Unicode)
- Évite erreurs d'encoding accents/caractères spéciaux

### Conversions de types
- CSV sources : tout en `DT_STR` (chaînes)
- Flat File Source → Advanced → Types numériques en `DT_I4` (INT) ou `DT_R8` (DECIMAL)

### API Jolpica
- Endpoint : `https://api.jolpi.ca/ergast/f1/2023/driverStandings.json`
- Pas d'authentification requise
- Regex extraction : `position`, `points`, `wins`, `driverId`, `code`

---

## Troubleshooting

| Problème | Solution |
|----------|----------|
| "FK constraint violation" | Vérifier que dimensions chargées AVANT faits |
| "Data type mismatch" | Vérifier types SQL vs SSIS (INT ↔ DT_I4, NVARCHAR ↔ DT_WSTR) |
| "NULL non remplacés" | Vérifier Derived Column regex : `"\\N"` (double backslash) |
| "API timeout" | Augmenter timeout HttpClient C# : `client.Timeout = TimeSpan.FromSeconds(60)` |
| "Power BI relations cassées" | Vérifier clés primaires/étrangères dans Object Explorer SSMS |

---

## Fichiers importants

- **`F1_Dashboard.pbix`** — Dashboard Power BI complet (4 pages : Driver Performance, Constructor Battle, Circuit Analysis, Season Overview)
- **`ApiStandingsScript.cs`** — Script C# SSIS (à intégrer dans Script Task du package `Load_API_Jolpica.dtsx`)
- **`csv files/`** — 5 fichiers CSV sources depuis Kaggle Ergast (circuits, constructors, drivers, races, results)
- **`excel/F1_Season_Standings.xlsx`** — Données de championnat 2009-2024
- **`sql/01_create_database_and_tables.sql`** — Point de départ (lancer en premier)
- **`sql/05_validation_queries.sql`** — Vérification après chargement

---

## Contacts & Documentation

- **SQL Server Integration Services (SSIS)** : [Microsoft Docs](https://learn.microsoft.com/en-us/sql/integration-services/)
- **Power BI Desktop** : [Microsoft Docs](https://learn.microsoft.com/en-us/power-bi/fundamentals/)
- **API Jolpica F1** : [api.jolpi.ca](https://api.jolpi.ca/ergast/f1/)
- **Dataset Kaggle Ergast** : [kaggle.com/rohanrao/formula-1-world-championship-1950-2020](https://www.kaggle.com/rohanrao/formula-1-world-championship-1950-2020)

---

**Auteurs :** BEN SALAH Chahine, JAOUADI Yassine, AFI Elaa, MASTOURI Mohamed Ali  
**Encadrante :** MENSI Rihab  
**Année académique :** 2025-2026  
**Université :** Faculté des Sciences de Tunis
