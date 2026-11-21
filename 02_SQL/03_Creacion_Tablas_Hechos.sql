USE Futbol_DWH;
GO

-- 1. Crear la Tabla de Hechos de Valoraciones (El Costo del Jugador)
CREATE TABLE FutbolBI.FactValoraciones (
    FSK_Jugador INT,
    FSK_Club INT,
    FSK_Fecha INT,
    BK_player_id INT,     -- Dimensión degenerada (Para auditoría)
    BK_club_id INT,       -- Dimensión degenerada (Para auditoría)
    market_value_in_eur INT,
    
    -- Estableciendo los cables conectores con las dimensiones
    FOREIGN KEY (FSK_Jugador) REFERENCES FutbolBI.DimJugador(SK_Jugador),
    FOREIGN KEY (FSK_Club) REFERENCES FutbolBI.DimClub(SK_Club),
    FOREIGN KEY (FSK_Fecha) REFERENCES FutbolBI.DimFecha(SK_Fecha)
);
GO

-- 2. Crear la Tabla de Hechos de Partidos (El Rendimiento en Cancha)
CREATE TABLE FutbolBI.FactPartidos (
    FSK_Jugador INT,
    FSK_Club INT,
    FSK_Fecha INT,
    BK_player_id INT,
    BK_club_id INT,
    BK_appearance_id NVARCHAR(100), -- ID único de esa aparición en el partido
    minutes_played INT,
    goals INT,
    assists INT,
    yellow_cards INT,
    red_cards INT,

    -- Comparten exactamente las mismas dimensiones (Constelación de Hechos)
    FOREIGN KEY (FSK_Jugador) REFERENCES FutbolBI.DimJugador(SK_Jugador),
    FOREIGN KEY (FSK_Club) REFERENCES FutbolBI.DimClub(SK_Club),
    FOREIGN KEY (FSK_Fecha) REFERENCES FutbolBI.DimFecha(SK_Fecha)
);
GO