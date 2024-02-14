-- View: tww_hydr.vw_rp_kote
-- Berechnet Kote von Haltungspunkt oder übernimmt Abwasserknoten_Sohlenkote,
-- wenn Haltungspunkt.Kote leer ist
-- Wird in vw_fehler_haltung_gefaelle verwendet

-- DROP VIEW tww_hydr.vw_rp_kote;


CREATE OR REPLACE VIEW tww_hydr.vw_reachpoint_minlevel
 AS
  WITH rp_minlevel as
  (
  	SELECT rp.obj_id,
		   rp.level,
		   wn.bottom_level,
		   CASE 
		     WHEN ch_fh.vsacode in (5062, 5064, 5066, 5068, 5069, 5070, 5071, 5072, 5074) THEN 'primary'
		     ELSE 'secondary'
	       END as hierarchy,
			rp.fk_wastewater_networkelement,
			rp.situation3d_geometry
	FROM tww_od.reach_point rp
	LEFT JOIN tww_od.vw_wastewater_node wn ON wn.obj_id::text = rp.fk_wastewater_networkelement::text
	LEFT JOIN tww_vl.channel_function_hierarchic ch_fh on ch_fh.code=wn._function_hierarchic
	WHERE (rp.level=0 OR rp.level is NULL) AND NOT (wn.bottom_level=0 OR wn.bottom_level is NULL)
  )
  SELECT 
    wn.obj_id AS wn_obj_id,
	case 
	     WHEN wn.bottom_level = 0 THEN min(rp.kote)::numeric
		 WHEN min(rp.kote) > 0::numeric AND wn.bottom_level < min(rp.kote) THEN wn.bottom_level::numeric
         ELSE min(rp.kote)::numeric
        END AS hp_minlevel,
	wn.situation3d_geometry
  FROM tww_od.wastewater_node wn
    LEFT JOIN rp_minlevel rp ON rp.fk_wastewater_networkelement::text = wn.obj_id::text
  GROUP BY wn.obj_id;

ALTER TABLE tww_hydr.vw_reachpoint_minlevel
    OWNER TO postgres;

GRANT ALL ON TABLE tww_hydr.vw_reachpoint_minlevel TO tww_user;
GRANT ALL ON TABLE tww_hydr.vw_reachpoint_minlevel TO postgres;
GRANT SELECT, REFERENCES, TRIGGER ON TABLE tww_hydr.vw_reachpoint_minlevel TO tww_viewer;


-- View: tww_hydr.vw_cover_minlevel
-- Berechnet minimale Deckelhöhe pro Abwasserbauwerk

-- DROP VIEW tww_hydr.vw_cover_minlevel;

CREATE OR REPLACE VIEW tww_hydr.vw_cover_minlevel
 AS
 SELECT co.fk_wastewater_structure,
    min(co.level) AS co_minlevel
   FROM tww_od.vw_cover co
  WHERE co.level > 0::numeric AND co.fk_wastewater_structure IS NOT NULL
  GROUP BY co.fk_wastewater_structure;

ALTER TABLE tww_hydr.vw_cover_minlevel
    OWNER TO postgres;

GRANT ALL ON TABLE tww_hydr.vw_cover_minlevel TO tww_user;
GRANT ALL ON TABLE tww_hydr.vw_cover_minlevel TO postgres;
GRANT SELECT, REFERENCES, TRIGGER ON TABLE tww_hydr.vw_cover_minlevel TO tww_viewer;

