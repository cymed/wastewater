-- View: tww_hydr.vw_fehler_schacht_tiefe
-- Kontrolliert Deckel_Kote und Abwasserknoten_Sohlenkote,
-- Fehlerhinweis wenn Schachttiefen auffällig oder Koten fehlen
-- Anzahl Knoten und Deckel
-- Gegengefälle im Schacht in separater View, da pro Abwasserknoten 

-- DROP VIEW tww_hydr.vw_fehler_schacht_tiefe;

CREATE OR REPLACE VIEW tww_hydr.vw_fehler_schacht_tiefe
 AS
  
 SELECT wws.obj_id AS ws_obj_id,
 	wws.identifier,
    CASE
		WHEN ch_f_hy._is_primary THEN 'primary'::text
		ELSE 'secondary'::text
	END AS hierarchy,
	wws.co_level As co_level,
	--wws.wn_bottom_level As Sohlenkote,
	rpmin.hp_minlevel as Sohlenkote,
    wws._depth,
 	
    CASE
		WHEN (rpmin.hp_minlevel = 0 or rpmin.hp_minlevel is NULL) and (wws.co_level = 0 or wws.co_level is NULL) THEN 'cover and und bottom level 0 or missing -> undefined depth'::text
    	WHEN wws.co_level = 0 or wws.co_level is NULL THEN 'Cover level 0 or missing -> undefined depth'::text
		WHEN rpmin.hp_minlevel = 0 or rpmin.hp_minlevel is NULL THEN 'bottom level 0 or missing -> undefined depth'::text
        WHEN wws.co_level - rpmin.hp_minlevel < 0.2  THEN 'Check depth (too low)'::text
	    WHEN wws.co_level - rpmin.hp_minlevel > 6  THEN 'Check depth (deep / too deep)'::text
	    ELSE ''::text
    END AS fehler_schacht,
	(SELECT COUNT(*)
	 FROM tww_od.vw_wastewater_node wn
	WHERE wn.fk_wastewater_structure::text = wws.obj_id::text) AS Anz_Knoten,
	(SELECT COUNT(*)
	 FROM tww_od.vw_cover co
	WHERE co.fk_wastewater_structure::text = wws.obj_id::text) AS Anz_Deckel,

    wws.situation_geometry,
    wws._channel_usage_current
   FROM tww_od.vw_tww_wastewater_structure wws
     LEFT JOIN tww_hydr.vw_reachpoint_minlevel rpmin ON rpmin.wn_obj_id::text = wws.wn_obj_id::text
 ;
 
 
ALTER TABLE tww_hydr.vw_fehler_schacht_tiefe
    OWNER TO postgres;

GRANT ALL ON TABLE tww_hydr.vw_fehler_schacht_tiefe TO tww_user;
GRANT ALL ON TABLE tww_hydr.vw_fehler_schacht_tiefe TO postgres;
GRANT SELECT, REFERENCES, TRIGGER ON TABLE tww_hydr.vw_fehler_schacht_tiefe TO tww_viewer;


-- View: tww_hydr.vw_fehler_knoten_gegengefaelle
-- Kontrolliert Differenz Einlauf- / Auslauf.Koten
-- Fehlermeldung bei Gegengefälle oder bei Absturz grösser 1m
-- Enthält auch die PAA/SAA Info der Einläufe, da Abstürze wohl nur bei PAA interessieren
-- Anzahl_Auslaeufe: beachten wenn nicht 1

-- View: tww_hydr.vw_fehler_knoten_gegengefaelle

-- DROP VIEW tww_hydr.vw_fehler_knoten_gegengefaelle;

CREATE OR REPLACE VIEW tww_hydr.vw_fehler_knoten_gegengefaelle
 AS
 WITH cnt AS (
         SELECT wn.obj_id AS obj_id,
            count(re.obj_id) AS no_out,
			min(rp.level) AS min_lvl
           FROM tww_od.wastewater_node wn
		   LEFT JOIN tww_od.reach_point rp ON rp.fk_wastewater_networkelement=wn.obj_id
		   LEFT JOIN tww_od.reach re on re.fk_reach_point_to=rp.obj_id
          GROUP BY wn.obj_id
        )
 SELECT rp.obj_id,
	wn.obj_id as wn_obj_id,
    ne_wn.identifier AS wn_identifier,
    wn._function_hierarchic  AS wn_function_hierarchic,
    rp.level AS rp_level,
    rp.identifier AS rp_identifier,
    ch.function_hierarchic AS re_from_function_hierarchic,
    cnt.min_lvl AS level_out_min,
        CASE
            WHEN (rp.level<cnt.min_lvl AND rp.level>0)  THEN 'counterslope'::text
            WHEN rp.level-cnt.min_lvl >1 THEN 'drop > 1 m'::text
            ELSE NULL
        END AS error_description,
    rp.level-cnt.min_lvl AS diff_i_o,
        CASE
            WHEN ss.function IS NOT NULL THEN ssf.value_de::text
            WHEN dp.obj_id IS NOT NULL THEN 'discharge_point'::text
            ELSE mnf.value_de::text
        END AS ws_function,
    cnt.no_out AS anz_auslaeufe,
    rp.situation_geometry
   FROM tww_od.reach_point rp
     LEFT JOIN tww_od.reach re ON rp.obj_id::text = re.fk_reach_point_to::text
	 LEFT JOIN tww_od.wastewater_networkelement ne_re ON ne_re.obj_id::text = re.obj_id::text
	 LEFT JOIN tww_od.channel ch ON ch.obj_id::text =ne_re.fk_wastewater_structure
     LEFT JOIN tww_od.wastewater_node wn ON rp.fk_wastewater_networkelement::text = wn.obj_id::text
     LEFT JOIN tww_od.wastewater_networkelement ne_wn on ne_wn.obj_id=wn.obj_id
     LEFT JOIN tww_od.special_structure ss ON ss.obj_id::text = ne_wn.fk_wastewater_structure::text
     LEFT JOIN tww_vl.special_structure_function ssf ON ssf.code = ss.function
     LEFT JOIN tww_od.manhole mn ON mn.obj_id::text = ne_wn.fk_wastewater_structure::text
     LEFT JOIN tww_vl.manhole_function mnf ON mnf.code = mn.function
     LEFT JOIN tww_od.discharge_point dp ON dp.obj_id::text = ne_wn.fk_wastewater_structure::text
     LEFT JOIN cnt ON cnt.obj_id::text = wn.obj_id::text
  WHERE re.obj_id IS NOT NULL and ((rp.level<cnt.min_lvl AND rp.level>0) OR rp.level-cnt.min_lvl >1);

ALTER TABLE tww_hydr.vw_fehler_knoten_gegengefaelle
    OWNER TO postgres;

GRANT ALL ON TABLE tww_hydr.vw_fehler_knoten_gegengefaelle TO tww_user;
GRANT ALL ON TABLE tww_hydr.vw_fehler_knoten_gegengefaelle TO postgres;
GRANT SELECT, REFERENCES, TRIGGER ON TABLE tww_hydr.vw_fehler_knoten_gegengefaelle TO tww_viewer;
