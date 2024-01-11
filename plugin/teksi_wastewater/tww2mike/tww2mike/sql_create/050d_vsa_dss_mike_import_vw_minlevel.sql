-- View: {ext_schema}.vw_rp_kote
-- Berechnet Kote von Haltungspunkt oder übernimmt Abwasserknoten_Sohlenkote,
-- wenn Haltungspunkt.Kote leer ist
-- Wird in vw_fehler_haltung_gefaelle verwendet

-- DROP VIEW {ext_schema}.vw_rp_kote;

CREATE OR REPLACE VIEW {ext_schema}.vw_rp_level
 AS
	SELECT rp.obj_id,
		   rp.level,
		   wn.bottom_level,
		   CASE 
		     WHEN ch_fh.vsacode in (5062, 5064, 5066, 5068, 5069, 5070, 5071, 5072, 5074) THEN 'primary'
		     ELSE 'secondary'
	       END as hierarchy,
			rp.fk_wastewater_networkelement,
			rp.situation_geometry
	FROM qgep_od.reach_point rp
	LEFT JOIN qgep_od.vw_wastewater_node wn ON wn.obj_id::text = rp.fk_wastewater_networkelement::text
	LEFT JOIN qgep_vl.channel_function_hierarchic ch_fh on ch_fh.code=wn._function_hierarchic
	WHERE (rp.level=0 OR rp.level is NULL) AND NOT (wn.bottom_level=0 OR wn.bottom_level is NULL)
	;
		 
ALTER TABLE {ext_schema}.vw_rp_level
    OWNER TO postgres;

GRANT ALL ON TABLE {ext_schema}.vw_rp_level TO qgep_user;
GRANT ALL ON TABLE {ext_schema}.vw_rp_level TO postgres;
GRANT SELECT, REFERENCES, TRIGGER ON TABLE {ext_schema}.vw_rp_level TO qgep_viewer;

