# syntax=docker/dockerfile:1
FROM dart:3.14.0 AS build
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN dart pub get --enforce-lockfile
COPY lib/ lib/
COPY bin/ bin/
RUN dart compile exe bin/server.dart -o /app/documents

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/documents /app/documents
USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["/app/documents"]
