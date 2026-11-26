# syntax=docker/dockerfile:1
FROM dart:3.14.0 AS build
WORKDIR /repo/workers/provider_connector
COPY workers/provider_connector/pubspec.yaml workers/provider_connector/pubspec.lock ./
RUN dart pub get --enforce-lockfile
COPY workers/provider_connector/lib/ lib/
COPY workers/provider_connector/bin/ bin/
# Each image has a fixed network entrypoint; runtime configuration cannot
# switch the parser or grant access to another network's key/origin.
ARG CONNECTOR_SOURCE
RUN test -f "bin/${CONNECTOR_SOURCE}.dart" && dart compile exe "bin/${CONNECTOR_SOURCE}.dart" -o connector
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /repo/workers/provider_connector/connector /app/connector
USER 65532:65532
ENTRYPOINT ["/app/connector"]
