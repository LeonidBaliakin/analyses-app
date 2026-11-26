# syntax=docker/dockerfile:1
FROM dart:3.14.0 AS build
WORKDIR /repo/services/documents
COPY packages/cloud_access/pubspec.yaml /repo/packages/cloud_access/pubspec.yaml
COPY services/documents/pubspec.yaml services/documents/pubspec.lock ./
RUN dart pub get --enforce-lockfile
COPY packages/cloud_access/lib/ /repo/packages/cloud_access/lib/
COPY services/documents/lib/ lib/
COPY services/documents/bin/ bin/
RUN dart compile exe bin/server.dart -o documents
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /repo/services/documents/documents /app/documents
USER 65532:65532
ENTRYPOINT ["/app/documents"]
