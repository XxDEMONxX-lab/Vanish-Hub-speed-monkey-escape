FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    curl git make gcc libssl-dev pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Build luvi (Luvit's runtime)
RUN git clone --depth 1 https://github.com/luvit/luvi.git /tmp/luvi \
    && cd /tmp/luvi \
    && make regular-asm \
    && cp build/luvi /usr/local/bin/luvi \
    && rm -rf /tmp/luvi

# Install lit and luvit
RUN curl -sL https://github.com/luvit/lit/raw/master/get-lit.sh | sh \
    && mv lit /usr/local/bin/lit \
    && lit make luvit \
    && mv luvit /usr/local/bin/luvit

# Install Discordia
RUN lit install SinisterRectus/discordia

# Copy bot files
COPY config.lua obfuscator.lua bot.lua app.lua ./

CMD ["luvit", "app.lua"]
