USE Futbol_DWH;
GO

-- 1. Cargar DimClub cruzando desde la base de datos Staging
INSERT INTO FutbolBI.DimClub (BK_club_id, name, stadium_name, coach_name)
SELECT DISTINCT 
    club_id, 
    name, 
    stadium_name, 
    coach_name 
FROM Stage.Clubes_Colombia
WHERE club_id IS NOT NULL;
GO

-- 2. Cargar DimJugador cruzando desde la base de datos Staging
INSERT INTO FutbolBI.DimJugador (BK_player_id, name, position, foot, date_of_birth, height_in_cm, country_of_citizenship)
SELECT DISTINCT 
    player_id, 
    name, 
    position, 
    foot, 
    date_of_birth, 
    height_in_cm, 
    country_of_citizenship 
FROM Stage.Jugadores_Colombia
WHERE player_id IS NOT NULL;
GO

-- 3. Generar el Calendario (DimFecha) basado en las fechas de tus valoraciones
DECLARE @FechaMinima DATE = (SELECT MIN(date) FROM Stage.Valoraciones_Colombia);
DECLARE @FechaMaxima DATE = (SELECT MAX(date) FROM Stage.Valoraciones_Colombia);

WHILE @FechaMinima <= @FechaMaxima
BEGIN
    INSERT INTO FutbolBI.DimFecha (SK_Fecha, fecha, anio, mes, dia, nombre_dia, nombre_mes)
    VALUES (
        CONVERT(INT, FORMAT(@FechaMinima, 'yyyyMMdd')), -- Ej: Convierte 2026-11-16 a 20261116
        @FechaMinima,
        YEAR(@FechaMinima),
        MONTH(@FechaMinima),
        DAY(@FechaMinima),
        DATENAME(WEEKDAY, @FechaMinima),
        DATENAME(MONTH, @FechaMinima)
    );
    
    -- Sumar un día para el siguiente ciclo del bucle
    SET @FechaMinima = DATEADD(DAY, 1, @FechaMinima);
END;
GO

-- 4. Validar cómo quedaron los catálogos con sus SK automáticos
SELECT TOP 10 * FROM FutbolBI.DimClub;
SELECT TOP 10 * FROM FutbolBI.DimJugador;