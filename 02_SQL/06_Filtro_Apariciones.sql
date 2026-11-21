USE Futbol_DWH;
GO

-- Filtramos las apariciones cruzándolas con nuestro catálogo de jugadores colombianos
SELECT A.*
INTO Stage.Apariciones_Colombia
FROM Stage.appearances_raw A
INNER JOIN Stage.Jugadores_Colombia J
    ON A.player_id = J.player_id;
GO