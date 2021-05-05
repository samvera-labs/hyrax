ARG RUBY_VERSION=2.7.3
# lock at alpine3.12 because 3.13 has dns resolver problems
FROM ruby:$RUBY_VERSION-alpine3.12 as hyrax-base

ARG DATABASE_APK_PACKAGE="postgresql-dev"
ARG EXTRA_APK_PACKAGES="git"

RUN apk --no-cache upgrade && \
  apk --no-cache add build-base \
  curl \
  imagemagick \
  tzdata \
  nodejs \
  yarn \
  zip \
  $DATABASE_APK_PACKAGE \
  $EXTRA_APK_PACKAGES

RUN addgroup -S --gid 101 app && \
  adduser -S -G app -u 1001 -s /bin/sh -h /app app
USER app

RUN gem update bundler

RUN mkdir -p /app/samvera/hyrax-webapp
WORKDIR /app/samvera/hyrax-webapp

COPY --chown=1001:101 ./bin /app/samvera
ENV PATH="/app/samvera:$PATH"
ENV RAILS_ROOT="/app/samvera/hyrax-webapp"
ENV RAILS_SERVE_STATIC_FILES="1"

ENTRYPOINT ["hyrax-entrypoint.sh"]
CMD ["bundle", "exec", "puma", "-v", "-b", "tcp://0.0.0.0:3000"]


FROM hyrax-base as hyrax

ARG APP_PATH=.
ARG BUNDLE_WITHOUT="development test"

ONBUILD COPY --chown=1001:101 $APP_PATH /app/samvera/hyrax-webapp
ONBUILD RUN bundle install --jobs "$(nproc)"
ONBUILD RUN RAILS_ENV=production SECRET_KEY_BASE=`bin/rake secret` DB_ADAPTER=nulldb DATABASE_URL='postgresql://fake' bundle exec rake assets:precompile


FROM hyrax-base as hyrax-worker

ENV MALLOC_ARENA_MAX=2

USER root
RUN apk --no-cache add bash \
  ffmpeg \
  mediainfo \
  openjdk11-jre \
  perl
USER app

RUN mkdir -p /app/fits && \
    cd /app/fits && \
    wget https://github.com/harvard-lts/fits/releases/download/1.5.0/fits-1.5.0.zip -O fits.zip && \
    unzip fits.zip && \
    rm fits.zip && \
    chmod a+x /app/fits/fits.sh
ENV PATH="${PATH}:/app/fits"

ARG APP_PATH=.
ARG BUNDLE_WITHOUT="development test"

ONBUILD COPY --chown=1001:101 $APP_PATH /app/samvera/hyrax-webapp
ONBUILD RUN bundle install --jobs "$(nproc)"

CMD bundle exec sidekiq


FROM hyrax-base as hyrax-engine-dev

ARG APP_PATH=.dassie
ARG BUNDLE_WITHOUT=

ENV HYRAX_ENGINE_PATH /app/samvera/hyrax-engine

COPY --chown=1001:101 $APP_PATH /app/samvera/hyrax-webapp
COPY --chown=1001:101 . /app/samvera/hyrax-engine

RUN cd /app/samvera/hyrax-engine && bundle install --jobs "$(nproc)"
RUN RAILS_ENV=production SECRET_KEY_BASE='fakesecret1234' DB_ADAPTER=nulldb DATABASE_URL='postgresql://fake' bundle exec rake assets:precompile


FROM hyrax-worker as hyrax-engine-dev-worker

ARG APP_PATH=.dassie
ARG BUNDLE_WITHOUT=

ENV HYRAX_ENGINE_PATH /app/samvera/hyrax-engine

COPY --chown=1001:101 $APP_PATH /app/samvera/hyrax-webapp
COPY --chown=1001:101 . /app/samvera/hyrax-engine

RUN cd /app/samvera/hyrax-engine && bundle install --jobs "$(nproc)"
