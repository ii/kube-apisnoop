FROM alpine:3.7

RUN apk add --no-cache iptables curl bash

COPY start.sh /start.sh

ENTRYPOINT ["/start.sh"]
