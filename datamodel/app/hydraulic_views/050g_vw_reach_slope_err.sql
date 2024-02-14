
-- View: tww_hydr.vw_fehler_haltung_gefaelle
-- Kontrolliert Gefaelle (Berechnung möglich oder Gefälle negativ)
-- Lichte Höhe und Funktion_Hydraulisch für entsprechende Kontrollen

-- DROP VIEW tww_hydr.vw_fehler_haltung_gefaelle;

CREATE OR REPLACE VIEW tww_hydr.vw_reach_slope_err
 AS
 WITH rp_minlevel as
  (
  	SELECT 
		rp.obj_id,
		rp.level,
		wn.bottom_level,
		CASE
			WHEN ch_f_hi._is_primary THEN 'primary'::text
			ELSE 'secondary'::text
		END AS hierarchy,
		rp.fk_wastewater_networkelement
	FROM tww_od.reach_point rp
	LEFT JOIN tww_od.vw_wastewater_node wn ON wn.obj_id::text = rp.fk_wastewater_networkelement::text
	LEFT JOIN tww_vl.channel_function_hierarchic ch_f_hi on ch_f_hi.code=wn._function_hierarchic
	WHERE (rp.level=0 OR rp.level is NULL) AND NOT (wn.bottom_level=0 OR wn.bottom_level is NULL)
  )
 SELECT re.obj_id AS haltung_obj_id,
    CASE
        WHEN ch_f_hi._is_primary THEN 'primary'::text
        ELSE 'secondary'::text
    END AS hierarchy,
    rpfrom.level AS level_from,
    rpto.level AS level_to,
    re.clear_height,
    ch_f_hy.value_de AS channel_function_hydraulic,
    CASE
        WHEN rpfrom.level IS NULL OR rpto.level IS NULL THEN 'missing level-> missing slope'::text
        WHEN rpfrom.level < rpto.level THEN 'negative slope'::text
        ELSE ''::text
    END AS fehler_gefaelle,
    re.progression_geometry
  FROM tww_od.reach re
     LEFT JOIN tww_od.wastewater_networkelement ne on ne.obj_id=re.obj_id
	 LEFT JOIN tww_od.channel che on ne.fk_wastewater_structure=ch.obj_id
     LEFT JOIN rp_minlevel rpto ON rpto.obj_id::text = re.rp_to_obj_id::text
     LEFT JOIN rp_minlevel rpfrom ON rpfrom.obj_id::text = re.rp_from_obj_id::text
     LEFT JOIN tww_vl.channel_function_hydraulic ch_f_hy ON ch_f_hy.code = ch.function_hydraulic
	 LEFT JOIN tww_vl.channel_function_hierarchic ch_f_hi on ch_f_hi.code = ch.function_hierarchic
	 WHERE TRUE=ANY(ARRAY[rpto.level IS NULL,rpfrom.level IS NULL,rpfrom.level < rpto.level AND ch.function_hydraulic<> ANY (ARRAY[23, 3610, 3655])]);

