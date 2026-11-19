FROM ruby:3.3-slim-bookworm

COPY docker/test-sympa.conf /etc/sympa/sympa/sympa.conf

RUN apt-get update \
 && printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d \
 && chmod +x /usr/sbin/policy-rc.d \
 && printf 'sympa sympa/dbconfig-install boolean false\nsympa sympa/hostname string sympa.test\nsympa sympa/listmaster string postmaster@sympa.test\n' | debconf-set-selections \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      build-essential sympa dbconfig-no-thanks apache2 libapache2-mod-fcgid \
      libdbd-sqlite3-perl libsoap-lite-perl sqlite3 \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile mail-sympa.gemspec ./
RUN bundle install

COPY . .
COPY docker/test-sympa.conf /etc/sympa/sympa/sympa.conf
COPY docker/test-topics.conf /etc/sympa/topics.conf
COPY docker/run_specs.rb /usr/local/bin/run_specs

ENTRYPOINT ["bundle", "exec", "ruby", "/usr/local/bin/run_specs"]
