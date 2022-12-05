FROM ubuntu:22.04

ARG TARGETARCH

COPY install-runner.sh /usr/src/installer/install-runner.sh
RUN bash /usr/src/installer/install-runner.sh ${TARGETARCH}


COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER runner
WORKDIR /runner
ENTRYPOINT ["bash", "/entrypoint.sh"]
