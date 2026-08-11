FROM luvit/luvit:latest

WORKDIR /app

# Install lit package manager and Discordia
RUN curl -sL https://github.com/luvit/lit/raw/master/get-lit.sh | sh \
    && ./lit install SinisterRectus/discordia \
    && rm -f get-lit.sh

# Copy bot files
COPY config.lua obfuscator.lua bot.lua app.lua ./

CMD ["./luvit", "app.lua"]
