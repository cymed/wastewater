-- vw_qgep_wastewater_structure (=Hauptknoten als Abwasserbauwerke)
-- Anzahl Knoten und Deckel pro Bauwerk

SELECT 
	ws.identifier as Bezeichnung,
	ws.ws_type as Bauwerksklasse,
	manhole_function.value_de AS Normschacht_Funktion,
    ss_function.value_de AS Spezialbw_Funktion,
	(SELECT COUNT(*)
	 FROM qgep_od.vw_wastewater_node wn
	WHERE wn.fk_wastewater_structure::text = ws.obj_id::text) AS Anz_Knoten,
	(SELECT COUNT(*)
	 FROM qgep_od.vw_cover co
	WHERE co.fk_wastewater_structure::text = ws.obj_id::text) AS Anz_Deckel
FROM qgep_od.vw_qgep_wastewater_structure ws
	LEFT JOIN qgep_vl.manhole_function manhole_function ON manhole_function.code = ws.ma_function
    LEFT JOIN qgep_vl.special_structure_function ss_function ON ss_function.code = WS.ss_function

Order by Anz_Knoten desc
;