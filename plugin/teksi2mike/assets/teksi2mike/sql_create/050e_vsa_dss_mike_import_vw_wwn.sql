-- View: dss2mike_2015_d.vw_mike_wastewater_node

-- DROP VIEW dss2mike_2015_d.vw_mike_wastewater_node;

CREATE OR REPLACE VIEW dss2mike_2015_d.vw_mike_wastewater_node
 AS
 -- SELECT wastewater_node.obj_id,
    -- wastewater_node._function_hierarchic,
    -- wastewater_node._usage_current,
    -- wastewater_node.backflow_level,
        -- CASE
            -- WHEN wastewater_node.bottom_level < vw_reachpoint_minlevel.hp_minlevel THEN wastewater_node.bottom_level
            -- ELSE vw_reachpoint_minlevel.hp_minlevel
        -- END AS bottom_level,
    -- wastewater_node.fk_hydr_geometry,
    -- wastewater_node.situation_geometry,
    -- ne.fk_wastewater_structure,
    -- ne.identifier,
    -- ne.last_modification,
    -- ne.remark,
    -- co.co_minlevel AS co_level,
    -- status.value_de AS ws_status,

    -- ma.dimension1 AS mn_dim1,
        -- CASE
            -- WHEN ma.obj_id IS NOT NULL THEN 'Normschacht'::text
            -- WHEN ss.obj_id IS NOT NULL THEN 'Spezialbauwerk'::text
            -- WHEN dp.obj_id IS NOT NULL THEN 'Einleitstelle'::text
            -- WHEN ii.obj_id IS NOT NULL THEN 'Versickerungsanlage'::text
            -- ELSE 'unknown'::text
        -- END AS ws_type,
    -- manhole_function.value_de AS ma_function,--ma.function AS ma_function,
    -- ss_function.value_de AS ss_function
   -- FROM qgep_od.wastewater_node
     -- LEFT JOIN qgep_od.wastewater_networkelement ne ON ne.obj_id::text = wastewater_node.obj_id::text
     -- LEFT JOIN dss2mike_2015_d.vw_reachpoint_minlevel ON vw_reachpoint_minlevel.fk_wastewater_networkelement::text = wastewater_node.obj_id::text
     -- LEFT JOIN qgep_od.wastewater_structure ws ON ws.obj_id::text = ne.fk_wastewater_structure::text
     -- LEFT JOIN qgep_od.manhole ma ON ma.obj_id::text = ws.obj_id::text
     -- LEFT JOIN qgep_od.special_structure ss ON ss.obj_id::text = ws.obj_id::text
     -- LEFT JOIN qgep_od.discharge_point dp ON dp.obj_id::text = ws.obj_id::text
     -- LEFT JOIN qgep_od.infiltration_installation ii ON ii.obj_id::text = ws.obj_id::text
     -- LEFT JOIN qgep_vl.wastewater_structure_status status ON status.code = ws.status
     -- LEFT JOIN qgep_vl.manhole_function manhole_function ON manhole_function.code = ma.function
	 -- LEFT JOIN qgep_vl.special_structure_function ss_function ON ss_function.code = ss.function
	 -- LEFT JOIN dss2mike_2015_d.vw_cover_minlevel co ON co.fk_wastewater_structure::text = ws.obj_id::text;

 SELECT wastewater_node.obj_id,
    wastewater_node._function_hierarchic,
    wastewater_node._usage_current,
    wastewater_node.backflow_level,
    vw_reachpoint_minlevel.hp_minlevel AS bottom_level,
    wastewater_node.fk_hydr_geometry,
    wastewater_node.situation_geometry,
    ne.fk_wastewater_structure,
    ne.identifier,
    ne.last_modification,
    ne.remark,
    co.co_minlevel AS co_level,
    status.value_de AS ws_status,
    ma.dimension1 AS mn_dim1,
        CASE
            WHEN ma.obj_id IS NOT NULL THEN 'Normschacht'::text
            WHEN ss.obj_id IS NOT NULL THEN 'Spezialbauwerk'::text
            WHEN dp.obj_id IS NOT NULL THEN 'Einleitstelle'::text
            WHEN ii.obj_id IS NOT NULL THEN 'Versickerungsanlage'::text
            ELSE 'unknown'::text
        END AS ws_type,
    manhole_function.value_de AS ma_function,
    ss_function.value_de AS ss_function
   FROM qgep_od.wastewater_node
     LEFT JOIN qgep_od.wastewater_networkelement ne ON ne.obj_id::text = wastewater_node.obj_id::text
     LEFT JOIN dss2mike_2015_d.vw_reachpoint_minlevel ON vw_reachpoint_minlevel.wn_obj_id::text = wastewater_node.obj_id::text
     LEFT JOIN qgep_od.wastewater_structure ws ON ws.obj_id::text = ne.fk_wastewater_structure::text
     LEFT JOIN qgep_od.manhole ma ON ma.obj_id::text = ws.obj_id::text
     LEFT JOIN qgep_od.special_structure ss ON ss.obj_id::text = ws.obj_id::text
     LEFT JOIN qgep_od.discharge_point dp ON dp.obj_id::text = ws.obj_id::text
     LEFT JOIN qgep_od.infiltration_installation ii ON ii.obj_id::text = ws.obj_id::text
     LEFT JOIN qgep_vl.wastewater_structure_status status ON status.code = wastewater_node._status
     LEFT JOIN qgep_vl.manhole_function manhole_function ON manhole_function.code = ma.function
     LEFT JOIN qgep_vl.special_structure_function ss_function ON ss_function.code = ss.function
     LEFT JOIN dss2mike_2015_d.vw_cover_minlevel co ON co.fk_wastewater_structure::text = ws.obj_id::text;

     
ALTER TABLE dss2mike_2015_d.vw_mike_wastewater_node
    OWNER TO postgres;

GRANT ALL ON TABLE dss2mike_2015_d.vw_mike_wastewater_node TO qgep_user;
GRANT ALL ON TABLE dss2mike_2015_d.vw_mike_wastewater_node TO postgres;
GRANT SELECT, REFERENCES, TRIGGER ON TABLE dss2mike_2015_d.vw_mike_wastewater_node TO qgep_viewer;

