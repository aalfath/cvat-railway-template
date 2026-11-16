# CVAT for Railway: one container runs the CVAT server, its RQ workers,
# the OPA policy engine and the web UI behind the server's nginx.
# Upstream images are pinned by version and digest. Bump all three together.
FROM openpolicyagent/opa:1.12.2-static@sha256:a4a8a67173fd7c8673c20c67c2a8d3611f705518afba932538e911ba7aa72451 AS opa
FROM cvat/ui:v2.83.0@sha256:5129eaa98b23cf023d2b23af8e12d8e2a2f85b87e771360cc9ceaab56ff57011 AS ui
FROM cvat/server:v2.83.0@sha256:eb86a2f59786c7887b6b1f529852d0af125f536ed3891cc19a7b57bd532b8522

USER root
COPY --from=opa /opa /usr/local/bin/opa
COPY --from=ui /usr/share/nginx/html /opt/cvat-ui
COPY nginx.conf /etc/nginx/nginx.conf
COPY supervisord-railway.conf /opt/cvat/supervisord/railway.conf
COPY railway-start.sh railway-run.sh /usr/local/bin/
RUN chmod 0755 /usr/local/bin/railway-start.sh /usr/local/bin/railway-run.sh \
 && sed -i "s/^loglevel = debug/loglevel = info/" /opt/cvat/supervisord/reusable/supervisord.conf

# The start script runs as root only to fix volume ownership, then drops to the
# image's own "django" user (uid 1000) for everything else.
ENTRYPOINT ["/usr/local/bin/railway-start.sh"]
