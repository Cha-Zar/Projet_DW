-- 01: Creation de la base et des tables principales.
-- Ce script repart de zero (DROP + CREATE).

USE master;
GO

IF DB_ID('DW_F1') IS NOT NULL
BEGIN
    ALTER DATABASE DW_F1 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DW_F1;
END
GO

CREATE DATABASE DW_F1
    COLLATE SQL_Latin1_General_CP1_CI_AS;
GO

USE DW_F1;
GO

-- Dimensions
CREATE TABLE DIM_Circuits (
    circuitId   INT             NOT NULL,
    circuitRef  NVARCHAR(100)   NOT NULL,
    name        NVARCHAR(200)   NOT NULL,
    location    NVARCHAR(100)   NULL,
    country     NVARCHAR(100)   NULL,
    lat         DECIMAL(10, 6)  NULL,
    lng         DECIMAL(10, 6)  NULL,
    alt         INT             NULL,
    url         NVARCHAR(500)   NULL,
    CONSTRAINT PK_DIM_Circuits PRIMARY KEY (circuitId)
);

CREATE TABLE DIM_Constructors (
    constructorId   INT             NOT NULL,
    constructorRef  NVARCHAR(100)   NOT NULL,
    name            NVARCHAR(200)   NOT NULL,
    nationality     NVARCHAR(100)   NULL,
    url             NVARCHAR(500)   NULL,
    CONSTRAINT PK_DIM_Constructors PRIMARY KEY (constructorId)
);

CREATE TABLE DIM_Drivers (
    driverId    INT             NOT NULL,
    driverRef   NVARCHAR(100)   NOT NULL,
    number      NVARCHAR(10)    NULL,
    code        NVARCHAR(10)    NULL,
    forename    NVARCHAR(100)   NOT NULL,
    surname     NVARCHAR(100)   NOT NULL,
    dob         NVARCHAR(20)    NULL,
    nationality NVARCHAR(100)   NULL,
    url         NVARCHAR(500)   NULL,
    CONSTRAINT PK_DIM_Drivers PRIMARY KEY (driverId)
);

CREATE TABLE DIM_Races (
    raceId       INT             NOT NULL,
    year         SMALLINT        NOT NULL,
    round        TINYINT         NOT NULL,
    circuitId    INT             NOT NULL,
    name         NVARCHAR(200)   NOT NULL,
    date         NVARCHAR(20)    NULL,
    time         NVARCHAR(20)    NULL,
    url          NVARCHAR(500)   NULL,
    fp1_date     NVARCHAR(20)    NULL,
    fp1_time     NVARCHAR(20)    NULL,
    fp2_date     NVARCHAR(20)    NULL,
    fp2_time     NVARCHAR(20)    NULL,
    fp3_date     NVARCHAR(20)    NULL,
    fp3_time     NVARCHAR(20)    NULL,
    quali_date   NVARCHAR(20)    NULL,
    quali_time   NVARCHAR(20)    NULL,
    sprint_date  NVARCHAR(20)    NULL,
    sprint_time  NVARCHAR(20)    NULL,
    CONSTRAINT PK_DIM_Races PRIMARY KEY (raceId),
    CONSTRAINT FK_DIM_Races_Circuit FOREIGN KEY (circuitId)
        REFERENCES DIM_Circuits (circuitId)
);

CREATE TABLE DIM_Season_Standings (
    Season               SMALLINT        NOT NULL,
    Champion_Driver      NVARCHAR(100)   NULL,
    Nationality          NVARCHAR(100)   NULL,
    Constructor          NVARCHAR(100)   NULL,
    Wins                 INT             NULL,
    Podiums              INT             NULL,
    Poles                INT             NULL,
    Points               DECIMAL(8, 2)   NULL,
    Races_Entered        INT             NULL,
    Champion_Constructor NVARCHAR(100)   NULL,
    Total_Races          INT             NULL,
    CONSTRAINT PK_DIM_Season PRIMARY KEY (Season)
);

-- Faits
CREATE TABLE FACT_Results (
    resultId         INT             NOT NULL,
    raceId           INT             NOT NULL,
    driverId         INT             NOT NULL,
    constructorId    INT             NOT NULL,
    number           NVARCHAR(10)    NULL,
    grid             INT             NOT NULL,
    position         NVARCHAR(10)    NULL,
    positionText     NVARCHAR(10)    NULL,
    positionOrder    INT             NOT NULL,
    points           DECIMAL(5, 2)   NOT NULL,
    laps             INT             NOT NULL,
    time             NVARCHAR(30)    NULL,
    milliseconds     NVARCHAR(20)    NULL,
    fastestLap       NVARCHAR(10)    NULL,
    rank             NVARCHAR(10)    NULL,
    fastestLapTime   NVARCHAR(20)    NULL,
    fastestLapSpeed  NVARCHAR(20)    NULL,
    statusId         INT             NOT NULL,
    CONSTRAINT PK_FACT_Results PRIMARY KEY (resultId),
    CONSTRAINT FK_Results_Race        FOREIGN KEY (raceId)
        REFERENCES DIM_Races (raceId),
    CONSTRAINT FK_Results_Driver      FOREIGN KEY (driverId)
        REFERENCES DIM_Drivers (driverId),
    CONSTRAINT FK_Results_Constructor FOREIGN KEY (constructorId)
        REFERENCES DIM_Constructors (constructorId)
);
GO

-- Staging
CREATE TABLE STG_Drivers (
    driverId    NVARCHAR(20), driverRef   NVARCHAR(100),
    number      NVARCHAR(10), code        NVARCHAR(10),
    forename    NVARCHAR(100), surname    NVARCHAR(100),
    dob         NVARCHAR(20), nationality NVARCHAR(100),
    url         NVARCHAR(500)
);

CREATE TABLE STG_Races (
    raceId      NVARCHAR(20), year        NVARCHAR(10),
    round       NVARCHAR(10), circuitId   NVARCHAR(20),
    name        NVARCHAR(200), date       NVARCHAR(20),
    time        NVARCHAR(20), url         NVARCHAR(500),
    fp1_date    NVARCHAR(20), fp1_time    NVARCHAR(20),
    fp2_date    NVARCHAR(20), fp2_time    NVARCHAR(20),
    fp3_date    NVARCHAR(20), fp3_time    NVARCHAR(20),
    quali_date  NVARCHAR(20), quali_time  NVARCHAR(20),
    sprint_date NVARCHAR(20), sprint_time NVARCHAR(20)
);

CREATE TABLE STG_Results (
    resultId        NVARCHAR(20), raceId          NVARCHAR(20),
    driverId        NVARCHAR(20), constructorId   NVARCHAR(20),
    number          NVARCHAR(20), grid            NVARCHAR(20),
    position        NVARCHAR(20), positionText    NVARCHAR(20),
    positionOrder   NVARCHAR(20), points          NVARCHAR(20),
    laps            NVARCHAR(20), time            NVARCHAR(30),
    milliseconds    NVARCHAR(20), fastestLap      NVARCHAR(20),
    rank            NVARCHAR(20), fastestLapTime  NVARCHAR(20),
    fastestLapSpeed NVARCHAR(20), statusId        NVARCHAR(20)
);

CREATE TABLE STG_API_Standings (
    season      SMALLINT,
    round       INT,
    driverCode  NVARCHAR(10),
    driverId    NVARCHAR(50),
    points      DECIMAL(8, 2),
    wins        INT,
    position    INT
);
GO

PRINT 'PARTIE 1 terminee : base et tables creees.';
GO
