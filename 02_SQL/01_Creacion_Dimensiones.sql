USE Futbol_DWH;
GO

-- 1. Crear Tabla de Clubes
CREATE TABLE FutbolBI.DimClub (
    SK_Club INT IDENTITY(1,1) PRIMARY KEY, -- Llave inventada automática
    BK_club_id INT NOT NULL,               -- ID original de Transfermarkt
    name NVARCHAR(255),
    stadium_name NVARCHAR(255),
    coach_name NVARCHAR(255),
    valido BIT DEFAULT 1,                  -- Para el historial (SCD Tipo 2)
    fecharegistro DATETIME DEFAULT GETDATE()
);
GO

-- 2. Crear Tabla de Jugadores
CREATE TABLE FutbolBI.DimJugador (
    SK_Jugador INT IDENTITY(1,1) PRIMARY KEY,
    BK_player_id INT NOT NULL,
    name NVARCHAR(255),
    position NVARCHAR(100),
    foot NVARCHAR(50),
    date_of_birth DATETIME,
    height_in_cm INT,
    country_of_citizenship NVARCHAR(100),
    valido BIT DEFAULT 1,
    fecharegistro DATETIME DEFAULT GETDATE()
);
GO

-- 3. Crear Tabla de Calendario
CREATE TABLE FutbolBI.DimFecha (
    SK_Fecha INT PRIMARY KEY,              -- Será numérico, ej: 20261116
    fecha DATE,
    anio INT,
    mes INT,
    dia INT,
    nombre_dia NVARCHAR(50),
    nombre_mes NVARCHAR(50)
);
GO