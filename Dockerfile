FROM ubuntu:22.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY build/ ./

ARG SERVER_BINARY=Server.x86_64
ENV SERVER_BINARY=${SERVER_BINARY}

RUN chmod +x "${SERVER_BINARY}"

EXPOSE 7777/udp
EXPOSE 7778/tcp

ENTRYPOINT ["sh", "-c", "./${SERVER_BINARY} -batchmode -nographics -logFile -"]
