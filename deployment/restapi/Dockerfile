FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /opt/logisticotrain/RESTApi

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential default-libmysqlclient-dev pkg-config \
    && rm -rf /var/lib/apt/lists/*

COPY RESTApi/ ./
COPY deployment/restapi/run-restapi.sh /usr/local/bin/run-restapi.sh
COPY deployment/restapi/serve_restapi.py /usr/local/bin/serve_restapi.py

RUN pip install --no-cache-dir -r requirements.txt waitress \
    && python -m compileall -q /opt/logisticotrain/RESTApi \
    && useradd --create-home --uid 10001 appuser \
    && chown -R appuser:appuser /opt/logisticotrain /usr/local/bin/run-restapi.sh /usr/local/bin/serve_restapi.py \
    && chmod +x /usr/local/bin/run-restapi.sh /usr/local/bin/serve_restapi.py

USER appuser

EXPOSE 5001

ENTRYPOINT ["/usr/local/bin/run-restapi.sh"]
