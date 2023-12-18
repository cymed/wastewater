import argparse
import sys
from logging import INFO, FileHandler, Formatter

from . import config, utils #TODO


from .teksi2mike.export import tww_export as export
from .teksi2mike._import import tww_import as _import
from .teksi2mike.initialize import tww_initialize as initialize

from .utils.various import make_log_path


def main(args):

    parser = argparse.ArgumentParser(
        description="TEKSI2Mike entry point", formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    parser.add_argument(
        "--direction"
        ,"-d"
        ,choices=["import", "export"]
    )
    parser.add_argument(
        "--recreate_schema"
        ,"-r"
        , action="store_true"
        , help="drops schema and reruns ili2pg importschema"
    )
    parser.add_argument(
        "--skip_validation"
        , "-v"
        , action="store_true"
        , help="skips running ilivalidator on input/output xtf (required to import invalid files, invalid outputs are still generated)"
    )
    parser.add_argument(
        "--path"
        , "-p"
        ,help="path to the input/output .xtf file"
    )
    parser.add_argument(
        "--log"
        , "-l"
        , action="store_true"
        , help="saves the log files next to the input/output file",
    )
     parser.add_argument(
        "--initialize"
        , "-i"
        , action="store_true"
        , help="saves the log files next to the input/output file",
    )
    parser.add_argument(
        "--pgservice"
        , "-s"
        , help="name of the pgservice to use to connect to the database"
        , default=config.TWW_DEFAULT_PGSERVICE
    )
    parser.add_argument(
        "--substitute_elevations"
        , "-e"
        , action="store_true"
        , help="use substitute elevations of missing parameters."
    )
    
     if not args.parser:
        parser.print_help(sys.stderr)
        exit(1)
   
    args = parser.parse_args(args)
     # Set log path
    log_path = args.path if args.log else None
    # Write root logger to file
    filename = make_log_path(log_path, "tww2mike")
    file_handler = FileHandler(filename, mode="w", encoding="utf-8")
    file_handler.setLevel(INFO)
    file_handler.setFormatter(Formatter("%(levelname)-8s %(message)s"))
    utils.various.logger.addHandler(file_handler)
    
    config.PGSERVICE = args.pgservice
    
    if args.initialize:
        # Create ili of shaped model
        exec_(
        f'"{config.JAVA}" -jar {config.ILISHAPER} --createModel --config {config.ILISHAPER_CONFFILE}--out {config.ILIPATH}/{config.ILISHAPER_MODEL_NAME}.ili --log {log_path} --trace {config.DSS_MODEL_NAME}'
        )
        utils.ili2db.create_ili_schema(
            config.EXT_SCHEMA, config.ILISHAPER_MODEL_NAME, make_log_path(log_path, "ilicreate"), recreate_schema=args.recreate_schema
        )
        initialize(pgservice=args.pgservice)
    
    if args.direction =='export':
        exec_(
        f'"{config.JAVA}" -jar {config.ILISHAPER} --deriveData --config {config.ILISHAPER_CONFFILE}--out {args.path} --log {log_path} --trace {args.path}'
        )
        utils.ili2db.create_ili_schema(
            config.EXT_SCHEMA, config.ILISHAPER_MODEL_NAME, make_log_path(log_path, "ilicreate"), recreate_schema=args.recreate_schema
        )
        export(args)
    elif args.direction =='import':
        pass
    else:
        exit(1)


    # else:
            # # to do maybe read message from orientation_list
            # print("No valid value for labels_orientation: [0.0, 90.0, -90.0]")
            # exit(1)
    print("Operation completed sucessfully !")
