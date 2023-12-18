------------------------------------------
/* GRANT on schemas - once per database */
------------------------------------------


/* User */
GRANT ALL ON SCHEMA dss2mike_2015_d TO qgep_user;
GRANT ALL ON ALL TABLES IN SCHEMA dss2mike_2015_d TO qgep_user;
GRANT ALL ON ALL SEQUENCES IN SCHEMA dss2mike_2015_d TO qgep_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA dss2mike_2015_d GRANT ALL ON TABLES TO qgep_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA dss2mike_2015_d GRANT ALL ON SEQUENCES TO qgep_user;
