# Definitions for tww datamodel with delta >= 1.7.0
# supposed usage: add TEKSI2AG64_96 into the plugin folder of TEKSI wastewater. 

from functools import lru_cache

from geoalchemy2.functions import ST_Force3D
from sqlalchemy.orm import Session
from sqlalchemy.orm.attributes import flag_dirty
from sqlalchemy.sql import text

from .. import utils
from ..utils.various import logger
from .model_ili import get_ili_model
from .model_tww import get_tww_model
import os
from .. import config
# This file is wastewater/plugin/TEKSI2AG64_96/assets/tww_initialize.py
# create_views.py is at wastewater/datamodel/app/view/create_views.py
from ....datamodel.app.view import create_views

def tww_import(args)
    """
    exports the reduced dataset to a filegdb for usage in MIKE.

    Args:
        pgservice: used service.
        xtfpath: Path to the xtf file
    """

    init_session = Session(utils.sqlalchemy.create_engine(), autocommit=False, autoflush=False)

    # First we check if the extension schema already exists
    schema_exists = init_session.execute(
        "SELECT schema_name FROM information_schema.schemata WHERE schema_name = %;".format(config.TWW_SCHEMA)
    )
    if schema_exists is None:
        directory = 'sql_create'
        files = os.listdir(os.path.join(directory,os.pardir)) 
        files.sort()
        for file in files:
            filename = os.fsdecode(file)
            if filename.endswith(".sql"):
                sql = text(open(os.path.join(directory, filename)).read().format(ext_schema=config.TWW_SCHEMA,
                                                                                 ilischema=config.AG96_SCHEMA))
                init_session.execute(sql)
                init_session.commit()
                init_session.flush()
    del schema_exists
    
    # We also drop symbology triggers as they badly affect performance. This must be done in a separate session as it
    # would deadlock other sessions.
    init_session.execute("SELECT tww_sys.drop_symbology_triggers();")
    init_session.commit()
    init_session.close()

    # ------------------------------------------ re-create all views --------------------------------------------------------------------
    

def import_to_extschema(args,log_path)
    """
    """
    utils.ili2db.create_ili_schema(
            config.EXT_SCHEMA, config.ILISHAPER_MODEL_NAME, make_log_path(log_path, "ilicreate"), recreate_schema=args.recreate_schema
        )