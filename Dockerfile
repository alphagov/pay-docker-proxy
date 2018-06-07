FROM govukpay/alpine:latest-master

EXPOSE 8443

USER root
RUN set -ex \
    && apk add --no-cache ca-certificates nginx openssl python py-pip gettext \
    && pip install --upgrade pip awscli==1.15.31 \
    && apk -v --purge del py-pip \
    && mkdir /app \
    && chown -R user /app \
    && mkdir -p /var/tmp/nginx \
    && chown -R user /var/tmp/nginx

RUN ln -sf /dev/stdout /var/lib/nginx/logs/error.log && \
    ln -sf /dev/stderr /var/lib/nginx/logs/access.log && \
    chown -R user /var/lib/nginx

USER user
COPY src/docker-entrypoint.sh /app/docker-entrypoint.sh
COPY src/do_auth.sh /app/do_auth.sh
COPY src/nginx.conf /app/nginx.conf.tpl

ENTRYPOINT ["ash", "/app/docker-entrypoint.sh"]
