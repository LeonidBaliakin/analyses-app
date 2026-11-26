# syntax=docker/dockerfile:1
FROM dart:3.14.0 AS build
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN dart pub get --enforce-lockfile
COPY lib/ lib/
COPY bin/ bin/
RUN dart compile exe bin/server.dart -o identity
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/identity /app/identity
USER 65532:65532
ENTRYPOINT ["/app/identity"]
