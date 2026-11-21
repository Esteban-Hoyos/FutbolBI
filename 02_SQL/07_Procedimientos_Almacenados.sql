USE Futbol_DWH;
GO

-- =========================================================
-- 1. PROCEDIMIENTO PARA CARGAR TODAS LAS DIMENSIONES
-- =========================================================
CREATE OR ALTER PROCEDURE FutbolBI.sp_Cargar_Dimensiones
AS
BEGIN
    SET NOCOUNT ON;

    -- A. Cargar Clubes
    INSERT INTO FutbolBI.DimClub (BK_club_id, name, stadium_name, coach_name)
    SELECT DISTINCT club_id, name, stadium_name, coach_name 
    FROM Stage.Clubes_Colombia
    WHERE club_id IS NOT NULL
      AND club_id NOT IN (SELECT BK_club_id FROM FutbolBI.DimClub); -- Evitar duplicados

    -- B. Cargar Jugadores
    INSERT INTO FutbolBI.DimJugador (BK_player_id, name, position, foot, date_of_birth, height_in_cm, country_of_citizenship)
    SELECT DISTINCT player_id, name, position, foot, date_of_birth, height_in_cm, country_of_citizenship 
    FROM Stage.Jugadores_Colombia
    WHERE player_id IS NOT NULL
      AND player_id NOT IN (SELECT BK_player_id FROM FutbolBI.DimJugador); -- Evitar duplicados

    -- C. Actualizar Calendario
    DECLARE @FechaMinima DATE = (SELECT MIN(date) FROM Stage.Valoraciones_Colombia);
    DECLARE @FechaMaxima DATE = (SELECT MAX(date) FROM Stage.Valoraciones_Colombia);

    WHILE @FechaMinima <= @FechaMaxima
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM FutbolBI.DimFecha WHERE SK_Fecha = CONVERT(INT, FORMAT(@FechaMinima, 'yyyyMMdd')))
        BEGIN
            INSERT INTO FutbolBI.DimFecha (SK_Fecha, fecha, anio, mes, dia, nombre_dia, nombre_mes)
            VALUES (
                CONVERT(INT, FORMAT(@FechaMinima, 'yyyyMMdd')),
                @FechaMinima, YEAR(@FechaMinima), MONTH(@FechaMinima), DAY(@FechaMinima),
                DATENAME(WEEKDAY, @FechaMinima), DATENAME(MONTH, @FechaMinima)
            );
        END
        SET @FechaMinima = DATEADD(DAY, 1, @FechaMinima);
    END;
END;
GO

-- =========================================================
-- 2. PROCEDIMIENTO PARA CARGAR TODAS LAS TABLAS DE HECHOS
-- =========================================================
USE Futbol_DWH;
GO

CREATE OR ALTER PROCEDURE FutbolBI.sp_Cargar_Hechos
AS
BEGIN
    SET NOCOUNT ON;

    -- =========================================================
    -- A. CARGA INCREMENTAL DE FactValoraciones
    -- =========================================================
    INSERT INTO FutbolBI.FactValoraciones (
        FSK_Jugador, FSK_Club, FSK_Fecha, 
        BK_player_id, BK_club_id, market_value_in_eur
    )
    SELECT 
        J.SK_Jugador, C.SK_Club, F.SK_Fecha, 
        V.player_id, V.current_club_id, V.market_value_in_eur
    FROM Stage.Valoraciones_Colombia V
    INNER JOIN FutbolBI.DimJugador J ON V.player_id = J.BK_player_id AND J.valido = 1
    INNER JOIN FutbolBI.DimClub C ON V.current_club_id = C.BK_club_id AND C.valido = 1
    INNER JOIN FutbolBI.DimFecha F ON V.date = F.fecha
    WHERE NOT EXISTS (
        SELECT 1 
        FROM FutbolBI.FactValoraciones FV
        WHERE FV.FSK_Jugador = J.SK_Jugador
          AND FV.FSK_Fecha = F.SK_Fecha
    );

    -- =========================================================
    -- B. CARGA INCREMENTAL DE FactPartidos
    -- =========================================================
    INSERT INTO FutbolBI.FactPartidos (
        FSK_Jugador, FSK_Club, FSK_Fecha, 
        BK_player_id, BK_club_id, BK_appearance_id,
        minutes_played, goals, assists, yellow_cards, red_cards
    )
    SELECT 
        J.SK_Jugador, ISNULL(C.SK_Club, -1), F.SK_Fecha, 
        A.player_id, A.player_club_id, A.appearance_id, 
        A.minutes_played, A.goals, A.assists, A.yellow_cards, A.red_cards
    FROM Stage.Apariciones_Colombia A
    INNER JOIN FutbolBI.DimJugador J ON A.player_id = J.BK_player_id AND J.valido = 1
    INNER JOIN FutbolBI.DimFecha F ON A.date = F.fecha
    LEFT JOIN FutbolBI.DimClub C ON A.player_club_id = C.BK_club_id AND C.valido = 1
    WHERE NOT EXISTS (
        SELECT 1 
        FROM FutbolBI.FactPartidos FP
        WHERE FP.BK_appearance_id = A.appearance_id
    );
END;
GO