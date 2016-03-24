FROM ubuntu:14.04

MAINTAINER Cesar Redondo <cesar.redondo@edify.cr>


ENV POSTGRES_VERSION 9.4
ENV RAILS_ENV development

RUN apt-get install --yes wget apt-utils

# enable https repos and add in nodesource repo
RUN apt-get -y install apt-transport-https
COPY assets/nodesource.list /etc/apt/sources.list.d/nodesource.list
ADD https://deb.nodesource.com/gpgkey/nodesource.gpg.key /tmp/nodesource.gpg.key
RUN apt-key add /tmp/nodesource.gpg.key

RUN     apt-add-repository --yes ppa:brightbox/ruby-ng
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" | tee /etc/apt/sources.list.d/pgdg.list
RUN wget --quiet -O - http://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN     apt-get update -y

# add nodejs and recommended ruby repos
RUN apt-get update \
    && apt-get -y install software-properties-common python-software-properties \
    && add-apt-repository ppa:brightbox/ppa \
    && add-apt-repository ppa:brightbox/ruby-ng \
    && apt-get update

# install deps for building/running canvas
RUN apt-get install -y \
    ruby2.1 ruby2.1-dev zlib1g-dev libxml2-dev libxslt1-dev \
    imagemagick libpq-dev libxmlsec1-dev libcurl4-gnutls-dev \
    libxmlsec1 build-essential openjdk-7-jre unzip curl \
    python g++ make git-core nodejs supervisor redis-server \
    libpq5 libsqlite3-dev \
    postgresql-$POSTGRES_VERSION \
    && apt-get clean \
    && rm -Rf /var/cache/apt



RUN gem install bundler --version 1.10.6

# Set the locale to avoid active_model_serializers bundler install failure
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# install canvas
RUN cd /opt \
    && git clone https://github.com/credondocr/canvas-lms.git \
    && cd /opt/canvas-lms \
    && bundle config build.nokogiri --use-system-libraries \
    && bundle install --path vendor/bundle --without="mysql"

# config setup
RUN cd /opt/canvas-lms \
    && for config in amazon_s3 delayed_jobs domain file_store outgoing_mail security external_migration \
       ; do cp config/$config.yml.example config/$config.yml \
       ; done

RUN cd /opt/canvas-lms \
    && npm install --unsafe-perm \
    && bundle exec rake canvas:compile_assets

COPY assets/database.yml /opt/canvas-lms/config/database.yml
COPY assets/redis.yml /opt/canvas-lms/config/redis.yml
COPY assets/cache_store.yml /opt/canvas-lms/config/cache_store.yml
COPY assets/development-local.rb /opt/canvas-lms/config/environments/development-local.rb
COPY assets/outgoing_mail.yml /opt/canvas-lms/config/outgoing_mail.yml
COPY assets/supervisord.conf /etc/supervisor/supervisord.conf
COPY assets/dbinit.sh /dbinit.sh
RUN chmod 755 /dbinit.sh

RUN /dbinit.sh

# redis
EXPOSE 6379
# canvas
EXPOSE 3000

COPY assets/start.sh /start.sh

CMD ["/start.sh"]
