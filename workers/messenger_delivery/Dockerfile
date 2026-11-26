# syntax=docker/dockerfile:1
FROM dart:3.14.0 AS build
WORKDIR /repo/workers/messenger_delivery
COPY workers/messenger_delivery/pubspec.yaml workers/messenger_delivery/pubspec.lock ./
RUN dart pub get --enforce-lockfile
COPY workers/messenger_delivery/lib/ lib/
COPY workers/messenger_delivery/bin/ bin/
RUN dart compile exe bin/worker.dart -o delivery
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /repo/workers/messenger_delivery/delivery /app/delivery
USER 65532:65532
ENTRYPOINT ["/app/delivery"]
