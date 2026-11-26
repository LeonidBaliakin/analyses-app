# syntax=docker/dockerfile:1
FROM dart:3.14.0 AS build
WORKDIR /repo/services/notifications
COPY services/notifications/pubspec.yaml services/notifications/pubspec.lock ./
RUN dart pub get --enforce-lockfile
COPY services/notifications/lib/ lib/
COPY services/notifications/bin/ bin/
RUN dart compile exe bin/server.dart -o notifications
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /repo/services/notifications/notifications /app/notifications
USER 65532:65532
ENTRYPOINT ["/app/notifications"]
