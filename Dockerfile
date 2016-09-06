FROM alpine

RUN apk add --update \
  alpine-sdk \
  ruby \
  ruby-dev \
  ruby-json \
  ca-certificates
RUN gem install io-console bundler --no-document

COPY .   /opt/resource

RUN     bundle install --without=development --gemfile=/opt/resource/Gemfile
