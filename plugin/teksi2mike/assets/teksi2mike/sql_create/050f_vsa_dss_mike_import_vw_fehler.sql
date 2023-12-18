CREATE OR REPLACE VIEW {ext_schema}.vw_err_rp_level
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
		 
ALTER TABLE {ext_schema}.vw_err_rp_level
    OWNER TO postgres;

GRANT ALL ON TABLE {ext_schema}.vw_err_rp_level TO qgep_user;
GRANT ALL ON TABLE {ext_schema}.vw_err_rp_level TO postgres;

-- View: dss2mike_2015_d.vw_err_primary2secondary
--  Visualisiert Haltungspunkte, deren Haltung PAA ist, die aber auf einen SAA-Knoten verknüpft sind
--  weil der Auslauf aus dem Knoten SAA ist
--  Wechsel PAA > SAA in Fliessrichtung nicht erlaubt!

-- DROP VIEW dss2mike_2015_d.vw_err_primary2secondary;

-- View: dss2mike_2015_d.vw_err_primary2secondary

-- DROP VIEW dss2mike_2015_d.vw_err_primary2secondary;

CREATE OR REPLACE VIEW dss2mike_2015_d.vw_err_primary2secondary
 AS
 SELECT rp.obj_id,
    ch.function_hierarchic AS ch_hierarchic,
    wn._function_hierarchic AS wn_hierarchic,
    rp.situation_geometry
   FROM qgep_od.reach_point rp
     LEFT JOIN qgep_od.reach re ON re.fk_reach_point_from::text = rp.obj_id::text OR re.fk_reach_point_to::text = rp.obj_id::text
	 LEFT JOIN qgep_od.wastewater_networkelement ne_re ON ne_re.obj_id::text = re.obj_id::text
	 LEFT JOIN qgep_od.channel ch ON ch.obj_id=ne_re.obj_id
     LEFT JOIN qgep_od.wastewater_node wn ON wn.obj_id::text = rp.fk_wastewater_networkelement::text
  WHERE (ch.function_hierarchic = ANY (ARRAY[5066, 5068, 5069, 5070, 5064, 5071, 5062, 5072, 5074])) 
  AND (wn._function_hierarchic <> ALL (ARRAY[5066, 5068, 5069, 5070, 5064, 5071, 5062, 5072, 5074]));

ALTER TABLE dss2mike_2015_d.vw_err_primary2secondary
    OWNER TO postgres;

GRANT ALL ON TABLE dss2mike_2015_d.vw_err_primary2secondary TO postgres;
GRANT ALL ON TABLE dss2mike_2015_d.vw_err_primary2secondary TO qgep_user;
GRANT SELECT, REFERENCES, TRIGGER ON TABLE dss2mike_2015_d.vw_err_primary2secondary TO qgep_viewer;




-- View: dss2mike_2015_d.vw_err_reach
--  Visualisiert PAA-Haltungen ohne Knoten unten oder Knoten oben
--  oder wo Knoten unten nicht PAA, weil der Auslauf aus dem Knoten SAA ist
--  Wechsel PAA > SAA in Fliessrichtung nicht erlaubt!

-- DROP VIEW dss2mike_2015_d.vw_err_reach;

CREATE OR REPLACE VIEW dss2mike_2015_d.vw_err_reach
 AS

SELECT 
   re.obj_id as obj_id,
   ch.function_hierarchic as ch_function_hierarchic, 
   wn_to._function_hierarchic as wn_to_hierarchic,
   wn_from._function_hierarchic as wn_from_hierarchic,
   re.progression_geometry
from qgep_od.reach re
	LEFT JOIN qgep_od.wastewater_networkelement ne ON ne.obj_id::text = re.obj_id::text
    LEFT JOIN qgep_od.reach_point rp_from ON rp_from.obj_id::text = re.fk_reach_point_from::text
    LEFT JOIN qgep_od.reach_point rp_to ON rp_to.obj_id::text = re.fk_reach_point_to::text
    LEFT JOIN qgep_od.wastewater_structure ws ON ne.fk_wastewater_structure::text = ws.obj_id::text
    LEFT JOIN qgep_od.channel ch ON ch.obj_id::text = ws.obj_id::text
    LEFT JOIN qgep_od.wastewater_node wn_to ON wn_to.obj_id = rp_to.fk_wastewater_networkelement
    LEFT JOIN qgep_od.wastewater_node wn_from ON wn_from.obj_id = rp_from.fk_wastewater_networkelement
	LEFT JOIN qgep_vl.channel_function_hierarchic ch_fhi ON ch.function_hierarchic=ch_fhi.code
	LEFT JOIN qgep_vl.channel_function_hierarchic wn_to_fhi ON wn_to._function_hierarchic=wn_to_fhi.code
	LEFT JOIN qgep_vl.channel_function_hierarchic wn_from_fhi ON wn_from._function_hierarchic=wn_from_fhi.code
	LEFT JOIN qgep_vl.wastewater_structure_status ws_st ON ws.status=ws_st.code	
where
   ch_fhi.vsacode in (5066,5068,5069,5070,5064,5071,5062,5072,5074) and  -- nur PAA
   (wn_to_fhi.vsacode is NULL or  --Knoten unten fehlt
    wn_from_fhi.vsacode is NULL or  -- Knoten oben fehlt
    wn_to_fhi.vsacode not in (5066,5068,5069,5070,5064,5071,5062,5072,5074)) -- Knoten unten =SAA
	AND ws_st.vsacode NOT in (3633,6523,6524,6532)
;

ALTER TABLE dss2mike_2015_d.vw_err_reach
    OWNER TO postgres;

GRANT ALL ON TABLE dss2mike_2015_d.vw_err_reach TO qgep_user;
GRANT ALL ON TABLE dss2mike_2015_d.vw_err_reach TO postgres;
GRANT SELECT, REFERENCES, TRIGGER ON TABLE dss2mike_2015_d.vw_err_reach TO qgep_viewer;



-- View: dss2mike_2015_d.vw_err_catchment
--  Visualisiert Einzugsgebiete, der Anschlussknoten nicht PAA sind

-- DROP VIEW dss2mike_2015_d.vw_err_catchment;

CREATE OR REPLACE VIEW dss2mike_2015_d.vw_err_catchment
 AS

 SELECT ca.obj_id,
    ca.identifier,
        CASE
            WHEN wn_swc._function_hierarchic <> ALL (ARRAY[5066, 5068, 5069, 5070, 5064, 5071, 5062, 5072, 5074]) THEN 'nicht PAA'::text
            ELSE ''::text
        END AS sw_ist,
        CASE
            WHEN wn_rwc._function_hierarchic <> ALL (ARRAY[5066, 5068, 5069, 5070, 5064, 5071, 5062, 5072, 5074]) THEN 'nicht PAA'::text
            ELSE ''::text
        END AS rw_ist,
        CASE
            WHEN wn_swp._function_hierarchic <> ALL (ARRAY[5066, 5068, 5069, 5070, 5064, 5071, 5062, 5072, 5074]) THEN 'nicht PAA'::text
            ELSE ''::text
        END AS sw_plan,
        CASE
            WHEN wn_rwp._function_hierarchic <> ALL (ARRAY[5066, 5068, 5069, 5070, 5064, 5071, 5062, 5072, 5074]) THEN 'nicht PAA'::text
            ELSE ''::text
        END AS rw_plan,
		case
			when ca.discharge_coefficient_rw_current + ca.discharge_coefficient_ww_current > 100 then 'Sum discharge_coefficient_current über 100'::text
			Else ''::text
		END AS abflussbeiw_ist,
		case
			when ca.discharge_coefficient_rw_planned + ca.discharge_coefficient_ww_planned > 100 then 'Summe Abflussbeiwert_gepl über 100'::text
			Else ''::text
		END AS abflussbeiw_geplant,
    ca.perimeter_geometry
   FROM qgep_od.catchment_area ca
     LEFT JOIN qgep_od.vw_wastewater_node wn_swc ON wn_swc.obj_id::text = ca.fk_wastewater_networkelement_ww_current::text
     LEFT JOIN qgep_od.vw_wastewater_node wn_rwc ON wn_rwc.obj_id::text = ca.fk_wastewater_networkelement_rw_current::text
     LEFT JOIN qgep_od.vw_wastewater_node wn_swp ON wn_swp.obj_id::text = ca.fk_wastewater_networkelement_ww_planned::text
     LEFT JOIN qgep_od.vw_wastewater_node wn_rwp ON wn_rwp.obj_id::text = ca.fk_wastewater_networkelement_rw_planned::text
  WHERE (wn_swc._function_hierarchic <> ALL (ARRAY[5066, 5068, 5069, 5070, 5064, 5071, 5062, 5072, 5074])) OR
  (wn_rwc._function_hierarchic <> ALL (ARRAY[5066, 5068, 5069, 5070, 5064, 5071, 5062, 5072, 5074])) OR
  (wn_swp._function_hierarchic <> ALL (ARRAY[5066, 5068, 5069, 5070, 5064, 5071, 5062, 5072, 5074])) OR
  (wn_rwp._function_hierarchic <> ALL (ARRAY[5066, 5068, 5069, 5070, 5064, 5071, 5062, 5072, 5074])or
  (ca.discharge_coefficient_rw_current + ca.discharge_coefficient_ww_current > 100)or
  (ca.discharge_coefficient_rw_planned + ca.discharge_coefficient_ww_planned > 100) )
  ;


ALTER TABLE dss2mike_2015_d.vw_err_catchment
    OWNER TO postgres;

GRANT ALL ON TABLE dss2mike_2015_d.vw_err_catchment TO qgep_user;
GRANT ALL ON TABLE dss2mike_2015_d.vw_err_catchment TO postgres;
GRANT SELECT, REFERENCES, TRIGGER ON TABLE dss2mike_2015_d.vw_err_catchment TO qgep_viewer;
