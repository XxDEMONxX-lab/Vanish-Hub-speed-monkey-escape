FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN curl -sL https://github.com/luvit/luvi/releases/download/v2.14.0/luvi-v2.14.0-regular-linux-x86_64 -o /usr/local/bin/luvi \
    && chmod +x /usr/local/bin/luvi \
    && curl -sL https://github.com/luvit/lit/raw/master/get-lit.sh | sh \
    && mv lit /usr/local/bin/lit \
    && lit make luvit \
    && mv luvit /usr/local/bin/luvit

RUN cd /app && lit install SinisterRectus/discordia

COPY config.lua obfuscator.lua bot.lua app.lua ./

CMD ["luvit", "app.lua"]
