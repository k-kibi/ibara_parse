FROM perl:5.30.1-stretch

RUN apt-get update -q && \
  apt-get upgrade -y && \
  apt-get install -y wget unzip

RUN useradd --create-home --user-group --uid 1000 kibi && \
  mkdir -p /app/ibara_parse && \
  cd /app/ibara_parse && \
  chown -R kibi:kibi /app
