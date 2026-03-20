# Stage 1: Build Showdex standalone
FROM node:18 AS showdex-builder

WORKDIR /showdex

# Install git (yarn is pre-installed in node:18)
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*


# Build standalone bundle (skip bundle analysis to speed up build)
ENV PROD_ANALYZE_BUNDLES=false
RUN npm run build:standalone

# Stage 2: Build pokemon-showdown-client
FROM node:18 AS builder

WORKDIR /app

# Install git (required by build-indexes to clone pokemon-showdown and showdex)
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# Copy everything
COPY . .

# Create caches directory (build-indexes uses it as cwd for git clone; it's gitignored so won't exist)
RUN mkdir -p caches

# Install dependencies and run full build
RUN npm install && npm run build-full && \
    echo 'exports.BattlePokemonSprites = {};' > play.pokemonshowdown.com/data/pokedex-mini.js && \
    echo 'exports.BattlePokemonSpritesGens = {};' > play.pokemonshowdown.com/data/pokedex-mini-bw.js

# Resolve the config.js symlink into a real file so it survives the multi-stage copy.
# play.pokemonshowdown.com/config/config.js is a symlink -> ../../config/config.js (gitignored),
# which becomes a dangling symlink in the nginx stage if not resolved here.
RUN cp --dereference play.pokemonshowdown.com/config/config.js /tmp/psc-config.js \
    && mv /tmp/psc-config.js play.pokemonshowdown.com/config/config.js

# Stage 3: Serve with nginx + PHP-FPM
FROM php:8.2-fpm-alpine

# Install nginx
RUN apk add --no-cache nginx

# Copy built client files to web root
COPY --from=builder /app/play.pokemonshowdown.com /var/www/html

# Copy config directory (PHP files reference ../../config/config.inc.php)
COPY --from=builder /app/config /var/www/config

# Create PHP config files from examples (gitignored originals don't exist in build)
RUN cp /var/www/config/config-example.inc.php /var/www/config/config.inc.php && \
    cp /var/www/config/servers-example.inc.php /var/www/config/servers.inc.php

# Copy nginx config
RUN rm -f /etc/nginx/http.d/default.conf
COPY nginx.conf /etc/nginx/http.d/default.conf

# Startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 80

CMD ["/start.sh"]
