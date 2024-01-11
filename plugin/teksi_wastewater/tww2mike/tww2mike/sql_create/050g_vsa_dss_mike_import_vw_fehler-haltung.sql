
-- View: dss2mike_2015_d.vw_fehler_haltung_gefaelle
-- Kontrolliert Gefaelle (Berechnung möglich oder Gefälle negativ)
-- Lichte Höhe und Funktion_Hydraulisch für entsprechende Kontrollen

-- DROP VIEW dss2mike_2015_d.vw_fehler_haltung_gefaelle;

CREATE OR REPLACE VIEW dss2mike_2015_d.vw_fehler_haltung_gefaelle
 AS
 SELECT re.obj_id AS haltung_obj_id,
    CASE
        WHEN re.ch_function_hierarchic = ANY (ARRAY[5066,5068,5069,5070,5064,5071,5062,5072,5074]) THEN 'PAA'::text
        ELSE 'SAA'::text
    END AS paa_saa,
    rpfrom.kote AS kote_oben,
    rpto.kote AS kote_unten,
    re.clear_height,
    ch_f_hy.value_de AS channel_function_hydraulic,
    CASE
        WHEN rpfrom.kote IS NULL OR rpto.kote IS NULL THEN 'Kote fehlt -> Gefaelle fehlt!'::text
        WHEN rpfrom.kote < rpto.kote THEN 'Gefaelle negativ!'::text
        ELSE ''::text
    END AS fehler_gefaelle,
    re.progression_geometry
  FROM qgep_od.vw_qgep_reach re
     LEFT JOIN dss2mike_2015_d.vw_rp_kote rpto ON rpto.obj_id::text = re.rp_to_obj_id::text
     LEFT JOIN dss2mike_2015_d.vw_rp_kote rpfrom ON rpfrom.obj_id::text = re.rp_from_obj_id::text
     LEFT JOIN qgep_vl.channel_function_hydraulic ch_f_hy ON ch_f_hy.code = re.ch_function_hydraulic
	 WHERE TRUE=ANY(ARRAY[rpto.kote IS NULL,rpfrom.kote IS NULL,rpfrom.kote < rpto.kote AND re.ch_function_hydraulic<> ANY (ARRAY[23, 3610, 3655])]);

ALTER TABLE dss2mike_2015_d.vw_fehler_haltung_gefaelle
    OWNER TO postgres;

GRANT ALL ON TABLE dss2mike_2015_d.vw_fehler_haltung_gefaelle TO qgep_user;
GRANT ALL ON TABLE dss2mike_2015_d.vw_fehler_haltung_gefaelle TO postgres;
GRANT SELECT, REFERENCES, TRIGGER ON TABLE dss2mike_2015_d.vw_fehler_haltung_gefaelle TO qgep_viewer;
