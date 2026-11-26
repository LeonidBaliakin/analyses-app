# syntax=docker/dockerfile:1
FROM dart:3.14.0 AS build
WORKDIR /repo/services/entitlements
COPY packages/cloud_access/pubspec.yaml /repo/packages/cloud_access/pubspec.yaml
COPY services/entitlements/pubspec.yaml services/entitlements/pubspec.lock ./
RUN dart pub get --enforce-lockfile
COPY packages/cloud_access/lib/ /repo/packages/cloud_access/lib/
COPY services/entitlements/lib/ lib/
COPY services/entitlements/bin/ bin/
RUN dart compile exe bin/server.dart -o entitlements
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /repo/services/entitlements/entitlements /app/entitlements
USER 65532:65532
ENTRYPOINT ["/app/entitlements"]
