FROM python:3.13-alpine
WORKDIR /app
COPY lobby.py /app/lobby.py
RUN addgroup -S ironveil && adduser -S -G ironveil ironveil && mkdir -p /data && chown -R ironveil:ironveil /data /app
USER ironveil
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/health', timeout=2).read()" || exit 1
CMD ["python", "/app/lobby.py"]
