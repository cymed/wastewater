# Definitions for tww datamodel with delta >= 1.7.0
# supposed usage: add TEKSI2AG64_96 into the plugin folder of TEKSI wastewater. 


from sqlalchemy.orm import Session
from sqlalchemy.sql import text

from .. import utils
import os
from .. import config
# This file is wastewater/plugin/TEKSI2AG64_96/assets/tww_initialize.py
# create_views.py is at wastewater/datamodel/app/view/create_views.py
from ....datamodel.app.view import create_views

def tww_initialize(pgservice=config.TWW_DEFAULT_PGSERVICE)
    """
    initializes the TWW database for usage of the AG64/96 models .

    Args:
        pgservice: used service.
    """

    init_session = Session(utils.sqlalchemy.create_engine(), autocommit=False, autoflush=False)
        
    directory = 'initialize'
    files = os.listdir(os.path.join(directory,os.pardir)) 
    files.sort()
    for file in files:
        filename = os.fsdecode(file)
        if filename.endswith(".sql"):
            sql = text(open(os.path.join(directory, filename)).read().format(ext_schema=config.EXT_SCHEMA))
            init_session.execute(sql)
            init_session.commit()
            init_session.flush()
        
    init_session.commit()
    init_session.close()

