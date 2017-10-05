#!/bin/bash
source ~/.bashrc
source .env
mix deps.get
cd apps/web/assets
npm install
# After NPM has finished doing its own thing, kindly install the right version of Bootstrap
npm un bootstrap
npm i -S bootstrap@4.0.0-alpha.6
# Place our custom css in bootstrap's domain
echo '$purple: #683bb7; $brand-primary: $purple; $font-family-sans-serif: Lato, "Helvetica Neue", Helvetica, sans-serif; $font-family-base: $font-family-sans-serif;' >> node_modules/bootstrap/scss/_custom.scss
./node_modules/brunch/bin/brunch b -p
cd ..
MIX_ENV=prod mix phx.digest
cd ../..
MIX_ENV=prod mix release

