USE Futbol_DWH;
GO

-- =========================================================
-- 0. PROCEDIMIENTO PARA REFRESCAR STAGE (Filtrado desde Raw)
-- =========================================================
CREATE OR ALTER PROCEDURE FutbolBI.sp_Cargar_Stage
AS
BEGIN
    SET NOCOUNT ON;

    -- Limpiar y recargar las apariciones filtradas de jugadores colombianos
    TRUNCATE TABLE Stage.Apariciones_Colombia;

    INSERT INTO Stage.Apariciones_Colombia
    SELECT A.*
    FROM Stage.appearances_raw A
    INNER JOIN Stage.Jugadores_Colombia J
        ON A.player_id = J.player_id;
END;
GO


USE Futbol_DWH;
GO

-- =========================================================
-- 1. PROCEDIMIENTO PARA CARGAR TODAS LAS DIMENSIONES
--    (Incluye SCD Tipo 2 en DimClub)
-- =========================================================
CREATE OR ALTER PROCEDURE FutbolBI.sp_Cargar_Dimensiones
AS
BEGIN
    SET NOCOUNT ON;

    -- A. Cargar Clubes (SCD Tipo 2 - Conserva historial)
    -- 1. Apagar registros vigentes que cambiaron de nombre, estadio o técnico
    UPDATE D
    SET D.valido = 0
    FROM FutbolBI.DimClub D
    INNER JOIN Stage.Clubes_Colombia S 
        ON D.BK_club_id = S.club_id
    WHERE D.valido = 1
      AND (
          ISNULL(D.name, '') <> ISNULL(S.name, '') OR
          ISNULL(D.stadium_name, '') <> ISNULL(S.stadium_name, '') OR
          ISNULL(D.coach_name, '') <> ISNULL(S.coach_name, '')
      );

    -- 2. Insertar clubes nuevos o las nuevas versiones vigentes
    INSERT INTO FutbolBI.DimClub (BK_club_id, name, stadium_name, coach_name, valido, fecharegistro)
    SELECT DISTINCT S.club_id, S.name, S.stadium_name, S.coach_name, 1, GETDATE()
    FROM Stage.Clubes_Colombia S
    WHERE S.club_id IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 
          FROM FutbolBI.DimClub D
          WHERE D.BK_club_id = S.club_id
            AND D.valido = 1
      );

    -- B. Cargar Jugadores (SCD Tipo 1 - Solo inserta nuevos)
    INSERT INTO FutbolBI.DimJugador (BK_player_id, name, position, foot, date_of_birth, height_in_cm, country_of_citizenship)
    SELECT DISTINCT player_id, name, position, foot, date_of_birth, height_in_cm, country_of_citizenship 
    FROM Stage.Jugadores_Colombia
    WHERE player_id IS NOT NULL
      AND player_id NOT IN (SELECT BK_player_id FROM FutbolBI.DimJugador);

    -- C. Actualizar Calendario (DimFecha)
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
--    (Carga incremental en FactValoraciones y FactPartidos)
-- =========================================================
CREATE OR ALTER PROCEDURE FutbolBI.sp_Cargar_Hechos
AS
BEGIN
    SET NOCOUNT ON;

    -- A. Carga incremental de FactValoraciones
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