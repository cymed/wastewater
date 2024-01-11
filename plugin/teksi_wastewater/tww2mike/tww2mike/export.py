# Definitions for tww datamodel with delta >= 1.7.0
# supposed usage: Export VSA DSS xtf into the plugin folder of TEKSI wastewater. 

from functools import lru_cache

from geoalchemy2.functions import ST_Force3D
from sqlalchemy.orm import Session
from sqlalchemy.orm.attributes import flag_dirty
from sqlalchemy.sql import text
from sqlalchemy import func, update

from .. import utils
from ..utils.various import logger
from .import_ import import_to_extschema
from .model_tww import get_tww_model
import os
from .. import config


def tww_export(args=None, log_path=None)
    """
    exports the reduced dataset to a filegdb for usage in MIKE.

    Args:
        pgservice: used service.
        xtfpath: Path to the xtf file
        substitute_elevations: bool whether or not to use substitute elevations for cover, wastewater node and reach point heights where NULL or zero
    """
    ili = get_ili_model()
    import_to_extschema(args,log_path)
    # Filtering
    filtered = selection is not None
    subset_ids = selection if selection is not None else []
    import_session = Session(utils.sqlalchemy.create_engine(), autocommit=False, autoflush=False)
    if args.substitute_elevations:
        substitute_elevations()
        
    def create_or_update(cls, **kwargs):
        """
        Updates an existing instance (if obj_id is found) or creates an instance of the provided class
        with given kwargs, and returns it.
        """
        instance = None

        # We try to get the instance from the session/database
        obj_id = kwargs.get("obj_id", None)
        if obj_id:
            instance = qgep_session.query(cls).get(kwargs.get("obj_id", None))

        if instance:
            # We found it -> update
            instance.__dict__.update(kwargs)
            flag_dirty(instance)  # we flag it as dirty so it stays in the session
        else:
            # We didn't find it -> create
            instance = cls(**kwargs)

        return instance

    def create_metaattributes(row):
        metaattribute = ili.metaattribute(
            # FIELDS TO MAP TO ABWASSER.metaattribute
            # --- metaattribute ---

            # 31.3.2023 obj_id instead of name
            # datenherr=getattr(row.fk_dataowner__REL, "name", "unknown"),  # TODO : is unknown ok ?
            # datenlieferant=getattr(row.fk_provider__REL, "name", "unknown"),  # TODO : is unknown ok ?


            datenherr=getattr(row.fk_dataowner__REL, "obj_id", "unknown"),  # TODO : is unknown ok ?
            datenlieferant=getattr(row.fk_provider__REL, "obj_id", "unknown"),  # TODO : is unknown ok ?

            letzte_aenderung=row.last_modification,
            sia405_baseclass_metaattribute=get_tid(row),
            # OD : is this OK ? Don't we need a different t_id from what inserted above in organisation ? if so, consider adding a "for_class" arg to tid_for_row
            t_id=get_tid(row),
            t_seq=0,
        )
        ili_session.add(metaattribute)

    def substitute_elevations()
        # set wastewater node height to minimal reach point height
        subquery = import_session.query(
            ili.haltungspunkt,
            func.min().over(
                partition_by=ili.haltungspunkt.abwassernetzelementref
            ).label('_min')
        ).subquery()
        update_stmt =(
            update(ili.abwasserknoten)
            .where(
                or_(
                    ili.abwasserknoten.sohlenkote=0,
                    ili.abwasserknoten.sohlenkote=None
                )
            )
            .where(subquery.abwassernetzelementref == ili.abwasserknoten.t_id)
            .values(ili.abwasserknoten.sohlenkote =subquery._min)
        )
        import_session.execute(update_stmt)
        import_session.commit()
        import_session.flush()
        
        # set reach point height to wastewater node height
        update_stmt =(
            update(ili.haltungspunkt)
            .where(
                or_(
                    ili.haltungspunkt.kote=0,
                    ili.haltungspunkt.kote=None
                )
            )
            .where(ili.haltungspunkt.abwassernetzelementref == ili.abwasserknoten.t_id)
            .values(ili.abwasserknoten.sohlenkote)
        )
        import_session.execute(update_stmt)
        import_session.commit()
        import_session.flush()
        
        # set cover height 2 m above node height
        query = import_session.query(ili.abwasserknoten)
            .join(ili.abwasserbauwerk)
            .join(ili.deckel)
            .filter(
                    ili.deckel.kote=None
                )

        for row in query:
            deckel=create_or_update(
                ili.deckel,
                **base_common(row),
                **metaattribute_common(metaattribute),
                bezeichnung=row.bezeichnung,
                kote=row.abwasserknoten.sohlenkote+2,
                abwasserbauwerkref=row.abwasserknoten.t_id
            )
            abwasserbauwerk=create_or_update(
                ili.abwasserbauwerk,
                **base_common(row),
                **metaattribute_common(metaattribute),
                #  --- param_ca_general ---
                kote=row.abwasserknoten.sohlenkote+2,
            )
            import_session.add(deckel)
            create_metaattributes(row)
            import_session.add(abwasserbauwerk)
            create_metaattributes(row)
        import_session.commit()
        import_session.flush()
        
    
