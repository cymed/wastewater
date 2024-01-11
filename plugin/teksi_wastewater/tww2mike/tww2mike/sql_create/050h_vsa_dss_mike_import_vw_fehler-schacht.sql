-- View: dss2mike_2015_d.vw_fehler_schacht_tiefe
-- Kontrolliert Deckel_Kote und Abwasserknoten_Sohlenkote,
-- Fehlerhinweis wenn Schachttiefen auffällig oder Koten fehlen
-- Anzahl Knoten und Deckel
-- Gegengefälle im Schacht in separater View, da pro Abwasserknoten 

-- DROP VIEW dss2mike_2015_d.vw_fehler_schacht_tiefe;

CREATE OR REPLACE VIEW dss2mike_2015_d.vw_fehler_schacht_tiefe
 AS
  
 SELECT wws.obj_id AS wws_obj_id,
 	wws.identifier AS Schacht_Bezeichnung,
    CASE
		WHEN (wws._channel_function_hierarchic in (5066,5068,5069,5070,5064,5071,5062,5072,5074)) THEN
			'PAA'::text
		ELSE 'SAA'::text
	END as PAASAA,
	wws.co_level As Deckel_Kote,
	--wws.wn_bottom_level As Sohlenkote,
	rpmin.hp_minlevel as Sohlenkote,
    wws._depth AS Tiefe,
 	
    CASE
		WHEN (rpmin.hp_minlevel = 0 or rpmin.hp_minlevel is NULL) and (wws.co_level = 0 or wws.co_level is NULL) THEN 'Deckel- und Sohlenkote 0 oder fehlt -> Tiefe nicht bestimmt!'::text
    	WHEN wws.co_level = 0 or wws.co_level is NULL THEN 'Deckelkote 0 oder fehlt -> Tiefe nicht bestimmt!'::text
		WHEN rpmin.hp_minlevel = 0 or rpmin.hp_minlevel is NULL THEN 'Sohlenkote 0 oder fehlt -> Tiefe nicht bestimmt!'::text
        WHEN wws.co_level - rpmin.hp_minlevel < 0.2  THEN 'Schachttiefe falsch (zu klein) !'::text
	    WHEN wws.co_level - rpmin.hp_minlevel > 6  THEN 'Schachttiefe pruefen (gross / zu gross) !'::text
	    ELSE ''::text
    END AS fehler_schacht,
	(SELECT COUNT(*)
	 FROM qgep_od.vw_wastewater_node wn
	WHERE wn.fk_wastewater_structure::text = wws.obj_id::text) AS Anz_Knoten,
	(SELECT COUNT(*)
	 FROM qgep_od.vw_cover co
	WHERE co.fk_wastewater_structure::text = wws.obj_id::text) AS Anz_Deckel,

    wws.situation_geometry,
    wws._channel_usage_current
   FROM qgep_od.vw_qgep_wastewater_structure wws
     LEFT JOIN dss2mike_2015_d.vw_reachpoint_minlevel rpmin ON rpmin.wn_obj_id::text = wws.wn_obj_id::text
 ;
 
 
ALTER TABLE dss2mike_2015_d.vw_fehler_schacht_tiefe
    OWNER TO postgres;

GRANT ALL ON TABLE dss2mike_2015_d.vw_fehler_schacht_tiefe TO qgep_user;
GRANT ALL ON TABLE dss2mike_2015_d.vw_fehler_schacht_tiefe TO postgres;
GRANT SELECT, REFERENCES, TRIGGER ON TABLE dss2mike_2015_d.vw_fehler_schacht_tiefe TO qgep_viewer;


-- View: dss2mike_2015_d.vw_fehler_knoten_gegengefaelle
-- Kontrolliert Differenz Einlauf- / Auslauf.Koten
-- Fehlermeldung bei Gegengefälle oder bei Absturz grösser 1m
-- Enthält auch die PAA/SAA Info der Einläufe, da Abstürze wohl nur bei PAA interessieren
-- Anzahl_Auslaeufe: beachten wenn nicht 1

-- View: dss2mike_2015_d.vw_fehler_knoten_gegengefaelle

-- DROP VIEW dss2mike_2015_d.vw_fehler_knoten_gegengefaelle;

CREATE OR REPLACE VIEW dss2mike_2015_d.vw_fehler_knoten_gegengefaelle
 AS
 WITH cnt AS (
         SELECT wn.obj_id AS obj_id,
            count(re.obj_id) AS no_out,
			min(rp.level) AS min_lvl
           FROM qgep_od.wastewater_node wn
		   LEFT JOIN qgep_od.reach_point rp ON rp.fk_wastewater_networkelement=wn.obj_id
		   LEFT JOIN qgep_od.reach re on re.fk_reach_point_to=rp.obj_id
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
   FROM qgep_od.reach_point rp
     LEFT JOIN qgep_od.reach re ON rp.obj_id::text = re.fk_reach_point_to::text
	 LEFT JOIN qgep_od.wastewater_networkelement ne_re ON ne_re.obj_id::text = re.obj_id::text
	 LEFT JOIN qgep_od.channel ch ON ch.obj_id::text =ne_re.fk_wastewater_structure
     LEFT JOIN qgep_od.wastewater_node wn ON rp.fk_wastewater_networkelement::text = wn.obj_id::text
     LEFT JOIN qgep_od.wastewater_networkelement ne_wn on ne_wn.obj_id=wn.obj_id
     LEFT JOIN qgep_od.special_structure ss ON ss.obj_id::text = ne_wn.fk_wastewater_structure::text
     LEFT JOIN qgep_vl.special_structure_function ssf ON ssf.code = ss.function
     LEFT JOIN qgep_od.manhole mn ON mn.obj_id::text = ne_wn.fk_wastewater_structure::text
     LEFT JOIN qgep_vl.manhole_function mnf ON mnf.code = mn.function
     LEFT JOIN qgep_od.discharge_point dp ON dp.obj_id::text = ne_wn.fk_wastewater_structure::text
     LEFT JOIN cnt ON cnt.obj_id::text = wn.obj_id::text
  WHERE re.obj_id IS NOT NULL and ((rp.level<cnt.min_lvl AND rp.level>0) OR rp.level-cnt.min_lvl >1);

ALTER TABLE dss2mike_2015_d.vw_fehler_knoten_gegengefaelle
    OWNER TO postgres;

GRANT ALL ON TABLE dss2mike_2015_d.vw_fehler_knoten_gegengefaelle TO qgep_user;
GRANT ALL ON TABLE dss2mike_2015_d.vw_fehler_knoten_gegengefaelle TO postgres;
GRANT SELECT, REFERENCES, TRIGGER ON TABLE dss2mike_2015_d.vw_fehler_knoten_gegengefaelle TO qgep_viewer;
