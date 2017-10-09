#!/bin/bash
source .env
mix deps.get
cd apps/web/assets
npm install
# Rebuild node-sass
npm rebuild node-sass
# After NPM has finished doing its own thing, kindly install the right version of Bootstrap
npm un bootstrap
npm i -S bootstrap@4.0.0-alpha.6
npm un jquery
cd ..
./patch_bootstrap.sh
cd assets
./node_modules/brunch/bin/brunch b -p
cd ..
MIX_ENV=prod mix phx.digest
cd ../..
MIX_ENV=prod mix release

