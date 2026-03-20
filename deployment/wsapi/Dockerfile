FROM maven:3.9.9-eclipse-temurin-21 AS build

WORKDIR /workspace/RealtimeAPI

COPY RealtimeAPI/pom.xml ./
RUN mvn -B -DskipTests dependency:go-offline

COPY RealtimeAPI/src ./src
RUN mvn -B -DskipTests package \
    && set -eu; \
    JAR_PATH="$(find target -maxdepth 1 -type f -name '*.jar' ! -name '*original*' | head -n 1)"; \
    cp "$JAR_PATH" /tmp/app.jar

FROM eclipse-temurin:21-jre-jammy

ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75 -Djava.security.egd=file:/dev/./urandom -Dio.netty.native.workdir=/var/tmp/netty"

WORKDIR /opt/logisticotrain/wsapi

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --uid 10002 appuser

COPY --from=build /tmp/app.jar /opt/logisticotrain/wsapi/app.jar
COPY deployment/wsapi/run-wsapi.sh /usr/local/bin/run-wsapi.sh

RUN chown -R appuser:appuser /opt/logisticotrain /usr/local/bin/run-wsapi.sh \
    && chmod +x /usr/local/bin/run-wsapi.sh

USER appuser

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/run-wsapi.sh"]
