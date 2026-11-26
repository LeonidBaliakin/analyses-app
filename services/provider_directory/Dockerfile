# syntax=docker/dockerfile:1
FROM dart:3.14.0 AS build
WORKDIR /repo/services/provider_directory
COPY packages/medical_domain/pubspec.yaml /repo/packages/medical_domain/pubspec.yaml
COPY packages/medical_terminology/pubspec.yaml /repo/packages/medical_terminology/pubspec.yaml
COPY packages/provider_directory/pubspec.yaml /repo/packages/provider_directory/pubspec.yaml
COPY services/provider_directory/pubspec.yaml services/provider_directory/pubspec.lock ./
RUN dart pub get --enforce-lockfile
COPY packages/medical_domain/lib/ /repo/packages/medical_domain/lib/
COPY packages/medical_terminology/lib/ /repo/packages/medical_terminology/lib/
COPY packages/provider_directory/lib/ /repo/packages/provider_directory/lib/
COPY services/provider_directory/lib/ lib/
COPY services/provider_directory/bin/ bin/
RUN dart compile exe bin/server.dart -o directory
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /repo/services/provider_directory/directory /app/directory
COPY services/provider_directory/config/sources.json /app/config/sources.json
COPY packages/provider_directory/data/catalog.json /app/config/catalog.json
WORKDIR /app
USER 65532:65532
ENTRYPOINT ["/app/directory"]
