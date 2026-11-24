# syntax=docker/dockerfile:1
FROM dart:3.14.0 AS build
WORKDIR /repo/services/records
COPY packages/medical_domain/pubspec.yaml /repo/packages/medical_domain/pubspec.yaml
COPY packages/record_sync/pubspec.yaml /repo/packages/record_sync/pubspec.yaml
COPY services/records/pubspec.yaml services/records/pubspec.lock ./
RUN dart pub get --enforce-lockfile
COPY packages/medical_domain/lib/ /repo/packages/medical_domain/lib/
COPY packages/record_sync/lib/ /repo/packages/record_sync/lib/
COPY services/records/lib/ lib/
COPY services/records/bin/ bin/
RUN dart compile exe bin/server.dart -o records
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /repo/services/records/records /app/records
USER 65532:65532
ENTRYPOINT ["/app/records"]
