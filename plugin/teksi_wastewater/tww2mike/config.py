import os

BASE = os.path.dirname(__file__)

PGSERVICE = None  # overriden by PG* settings below
PGHOST = os.getenv("PGHOST", None)
PGPORT = os.getenv("PGPORT", None)
PGDATABASE = os.getenv("PGDATABASE", None)
PGUSER = os.getenv("PGUSER", None)
PGPASS = os.getenv("PGPASS", None)
JAVA = r"java"
ILI2PG = os.path.join(BASE, "bin", "ili2pg-4.5.0-bindist", "ili2pg-4.5.0.jar")
ILIVALIDATOR = os.path.join(BASE, "bin", "ilivalidator-1.11.9", "ilivalidator-1.11.9.jar")
ILISHAPER = os.path.join(BASE, "bin", "ilishaper-0.1.0", "ilishaper-0.1.0.jar")
ILI_FOLDER = os.path.join(BASE, "ili")
DATA_FOLDER = os.path.join(BASE, "data")

ILISHAPER_CONFFILE = os.path.join(ILI_FOLDER, "DSS2Mike.ini")
ILISHAPER_MODEL_NAME = "DSS2Mike"  
DSS_MODEL_NAME="DSS_2020_1_LV95"

TWW_DEFAULT_PGSERVICE='pg_tww'
EXT_SCHEMA='tww2mike'