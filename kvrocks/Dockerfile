# Kvrocks: CVAT's on-disk Redis-compatible cache for media chunks.
FROM apache/kvrocks:2.15.0@sha256:0192707bd335ad546d8ec7826b1553b674fff27d6cea4195e22c0f1adbdbea40

USER root
RUN mkdir -p /etc/kvrocks && cp /var/lib/kvrocks/kvrocks.conf /etc/kvrocks/kvrocks.conf
COPY start.sh /usr/local/bin/kvrocks-start.sh
RUN chmod 0755 /usr/local/bin/kvrocks-start.sh
ENTRYPOINT ["/usr/local/bin/kvrocks-start.sh"]
