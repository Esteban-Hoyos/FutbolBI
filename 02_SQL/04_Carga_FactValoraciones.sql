USE Futbol_DWH;
GO

-- 1. Vaciamos la tabla de hechos primero (buena práctica de ETL para evitar duplicados si lo corres dos veces)
TRUNCATE TABLE FutbolBI.FactValoraciones;
GO

-- 2. Inyectamos los datos traduciendo las llaves originales (BK) a nuestras llaves (SK)
INSERT INTO FutbolBI.FactValoraciones (
    FSK_Jugador, 
    FSK_Club, 
    FSK_Fecha, 
    BK_player_id, 
    BK_club_id, 
    market_value_in_eur
)
SELECT 
    J.SK_Jugador, 
    C.SK_Club, 
    F.SK_Fecha, 
    V.player_id, 
    V.current_club_id, 
    V.market_value_in_eur
FROM Stage.Valoraciones_Colombia V
-- Cruzamos con la Dimensión Jugador (asegurando que traemos la versión activa con valido = 1)
INNER JOIN FutbolBI.DimJugador J 
    ON V.player_id = J.BK_player_id AND J.valido = 1
-- Cruzamos con la Dimensión Club
INNER JOIN FutbolBI.DimClub C 
    ON V.current_club_id = C.BK_club_id AND C.valido = 1
-- Cruzamos con el Calendario Automático
INNER JOIN FutbolBI.DimFecha F 
    ON V.date = F.fecha;
GO

-- 3. Comprobamos el resultado final
SELECT TOP 20 * FROM FutbolBI.FactValoraciones;