FROM alpine

RUN apk add --update \
  ruby \
  ruby-json \
  ca-certificates

COPY .   /opt/resource
RUN  rm -rf /usr/libexec
