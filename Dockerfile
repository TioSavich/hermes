# UMEDCTA / Hermes distribution image.
#
# The image carries the runtime manifest, not the repository: the file list in
# scripts/bundle/app_manifest.txt names exactly what the running app needs —
# the Hermes console (stdlib-only Python), the Prolog knowledge base the
# worker loads, and the public web surfaces. Test suites, research documents,
# manuscript material, and HPC packaging stay out. Regenerate the manifest
# with `make app-manifest`; `app_manifest.py --verify` proves it covers the
# worker's real load closure.
#
# Gallery figure images (~190 MB) are not baked in; the gallery names the
# absence, the same way a checkout without local research data does. To serve
# them, bind-mount the repo's docs tree:
#   docker run --rm -p 8765:8765 \
#     -v "$PWD/docs/research_assets:/app/docs/research_assets:ro" umedcta
#
# Build:    docker build -t umedcta .
# Run:      docker run --rm -p 8765:8765 umedcta
# Console:  http://127.0.0.1:8765

FROM swipl:9.2.9 AS staging
WORKDIR /src
COPY . .
RUN mkdir /staged \
    && tar -cf /tmp/app-manifest.tar -T scripts/bundle/app_manifest.txt \
    && tar -xf /tmp/app-manifest.tar -C /staged \
    && rm /tmp/app-manifest.tar

FROM swipl:9.2.9

# python3 runs the Hermes server (standard library only — no pip layer).
# poppler-utils provides pdftotext/pdftoppm for the PDF homework surface.
RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 poppler-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=staging /staged /app

# The gallery's asset manifest points at figure images the image does not
# carry; prune it to what is present (and fail the build on any bad JSON),
# so the gallery names the exclusion instead of rendering broken cards.
RUN python3 scripts/bundle/prebake.py --bundle /app --prune-only

# UMEDCTA_ROOT anchors hermes_worker.pl and lesson monitoring when loaded
# outside the repo root; PYTHONPATH lets `python3 -m hermes.app.server`
# resolve from /app.
ENV UMEDCTA_ROOT=/app \
    PYTHONPATH=/app

EXPOSE 8765

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s \
    CMD ["python3", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8765/api/mode', timeout=4)"]

# Bind 0.0.0.0 so the published port reaches the host. The FERPA gate posture
# is the repo default: server.py reads HERMES_GATE itself (off unless
# HERMES_GATE=on); nothing here changes gate semantics.
CMD ["python3", "-m", "hermes.app.server", "--host", "0.0.0.0", "--port", "8765"]
