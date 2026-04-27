#!/bin/sh
set -e

cd /app
npm run build-full
echo 'exports.BattlePokemonSprites = {};' > play.pokemonshowdown.com/data/pokedex-mini.js
echo 'exports.BattlePokemonSpritesGens = {};' > play.pokemonshowdown.com/data/pokedex-mini-bw.js

php-fpm &
exec nginx -g 'daemon off;'
