FROM debian:stretch

ENV NETDATA_PORT 19999
EXPOSE $NETDATA_PORT

VOLUME /override

ENTRYPOINT ["/src/run.sh"]

ADD . /src
RUN /src/build.sh
