-- 02: Ajustements de types/colonnes faits pendant le projet.
-- A lancer apres la creation des tables.

USE DW_F1;
GO

ALTER TABLE DIM_Drivers ALTER COLUMN dob NVARCHAR(20) NULL;

ALTER TABLE DIM_Races ALTER COLUMN date        NVARCHAR(20) NULL;
ALTER TABLE DIM_Races ALTER COLUMN fp1_date    NVARCHAR(20) NULL;
ALTER TABLE DIM_Races ALTER COLUMN fp2_date    NVARCHAR(20) NULL;
ALTER TABLE DIM_Races ALTER COLUMN fp3_date    NVARCHAR(20) NULL;
ALTER TABLE DIM_Races ALTER COLUMN quali_date  NVARCHAR(20) NULL;
ALTER TABLE DIM_Races ALTER COLUMN sprint_date NVARCHAR(20) NULL;

ALTER TABLE DIM_Races ADD fp1_time     NVARCHAR(20) NULL;
ALTER TABLE DIM_Races ADD fp2_time     NVARCHAR(20) NULL;
ALTER TABLE DIM_Races ADD fp3_time     NVARCHAR(20) NULL;
ALTER TABLE DIM_Races ADD quali_time   NVARCHAR(20) NULL;
ALTER TABLE DIM_Races ADD sprint_time  NVARCHAR(20) NULL;

ALTER TABLE FACT_Results ALTER COLUMN fastestLapSpeed NVARCHAR(20) NULL;

ALTER TABLE DIM_Season_Standings ALTER COLUMN Champion_Driver      NVARCHAR(100) NULL;
ALTER TABLE DIM_Season_Standings ALTER COLUMN Nationality          NVARCHAR(100) NULL;
ALTER TABLE DIM_Season_Standings ALTER COLUMN Constructor          NVARCHAR(100) NULL;
ALTER TABLE DIM_Season_Standings ALTER COLUMN Champion_Constructor NVARCHAR(100) NULL;

ALTER TABLE STG_API_Standings ALTER COLUMN driverCode NVARCHAR(10) NULL;
ALTER TABLE STG_API_Standings ALTER COLUMN driverId   NVARCHAR(50) NULL;
GO

PRINT 'PARTIE 2 terminee : corrections appliquees.';
GO
