-- 04: Requetes de verification rapide apres chargement.

USE DW_F1;
GO

SELECT 'DIM_Circuits'          AS TableName, COUNT(*) AS Rows FROM DIM_Circuits          UNION ALL
SELECT 'DIM_Constructors',                   COUNT(*) FROM DIM_Constructors              UNION ALL
SELECT 'DIM_Drivers',                        COUNT(*) FROM DIM_Drivers                   UNION ALL
SELECT 'DIM_Races',                          COUNT(*) FROM DIM_Races                     UNION ALL
SELECT 'DIM_Season_Standings',               COUNT(*) FROM DIM_Season_Standings          UNION ALL
SELECT 'STG_API_Standings',                  COUNT(*) FROM STG_API_Standings             UNION ALL
SELECT 'FACT_Results',                       COUNT(*) FROM FACT_Results;
GO
