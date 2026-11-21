USE Futbol_DWH;
GO

-- 1. Insertar el "Miembro Desconocido" forzando el ID -1 en tu Dimensión
SET IDENTITY_INSERT FutbolBI.DimClub ON;

IF NOT EXISTS (SELECT 1 FROM FutbolBI.DimClub WHERE SK_Club = -1)
BEGIN
    INSERT INTO FutbolBI.DimClub (SK_Club, BK_club_id, name, stadium_name, coach_name, valido)
    VALUES (-1, -1, 'Club Externo / Sin Registrar', 'N/A', 'N/A', 1);
END

SET IDENTITY_INSERT FutbolBI.DimClub OFF;
GO

-- 2. Recargar FactPartidos usando LEFT JOIN para rescatar los 4,156 partidos
TRUNCATE TABLE FutbolBI.FactPartidos;
GO

INSERT INTO FutbolBI.FactPartidos (
    FSK_Jugador, FSK_Club, FSK_Fecha, BK_player_id, BK_club_id, BK_appearance_id,
    minutes_played, goals, assists, yellow_cards, red_cards
)
SELECT 
    J.SK_Jugador, 
    ISNULL(C.SK_Club, -1), -- Si el club no está en DimClub, se le asigna el SK -1
    F.SK_Fecha, 
    A.player_id, 
    A.player_club_id, 
    A.appearance_id, 
    A.minutes_played, 
    A.goals, 
    A.assists, 
    A.yellow_cards, 
    A.red_cards
FROM Stage.Apariciones_Colombia A
-- Mantenemos INNER JOIN para jugadores y fechas porque esos sí existen completos
INNER JOIN FutbolBI.DimJugador J 
    ON A.player_id = J.BK_player_id AND J.valido = 1
INNER JOIN FutbolBI.DimFecha F 
    ON A.date = F.fecha
-- Cambiamos a LEFT JOIN para los clubes
LEFT JOIN FutbolBI.DimClub C 
    ON A.player_club_id = C.BK_club_id AND C.valido = 1;
GO

-- 3. Verificación final: ¿Cuántos partidos entraron a la tabla de hechos?
SELECT COUNT(*) AS Total_Partidos_Cargados FROM FutbolBI.FactPartidos;