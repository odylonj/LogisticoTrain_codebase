#!/usr/bin/env python3
import os
import sys
from pathlib import Path

from waitress import serve

APP_DIR = Path("/opt/logisticotrain/RESTApi")
sys.path.insert(0, str(APP_DIR))

from MyRamesServer import create_server_apps
from utils.loggingUtils import configure_logging


def main() -> None:
    os.chdir(APP_DIR)

    config_path = os.environ["RESTAPI_CONFIG_PATH"]
    static_folder = os.environ.get("RESTAPI_STATIC_FOLDER", str(APP_DIR / "static"))
    log_level = os.environ.get("RESTAPI_LOG_LEVEL", "INFO")
    host = os.environ.get("RESTAPI_HOST", "0.0.0.0")
    port = int(os.environ.get("RESTAPI_PORT", "5001"))
    threads = int(os.environ.get("RESTAPI_THREADS", "8"))

    configure_logging(log_level)
    app = create_server_apps(config_path, static_folder, log_level)

    serve(app, host=host, port=port, threads=threads)


if __name__ == "__main__":
    main()
