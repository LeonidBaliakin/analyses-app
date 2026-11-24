# syntax=docker/dockerfile:1
FROM dart:3.14.0 AS build
WORKDIR /app
COPY services/processing/pubspec.yaml services/processing/pubspec.lock ./
RUN dart pub get --enforce-lockfile
COPY services/processing/lib/ lib/
COPY services/processing/bin/ bin/
RUN dart compile exe bin/server.dart -o /app/processing

FROM dart:3.14.0
RUN apt-get update && apt-get install -y --no-install-recommends python3 tesseract-ocr poppler-utils && rm -rf /var/lib/apt/lists/*
COPY --from=build /app/processing /app/processing
COPY workers/document_processing/worker.py workers/document_processing/make_config.py /worker/
COPY services/processing/start.sh /app/start.sh
USER 65532:65532
ENTRYPOINT ["/bin/sh","/app/start.sh"]
