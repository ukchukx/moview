#!/bin/bash
source ~/.bashrc
source .env
mix deps.get
cd apps/web/assets
npm install
./node_modules/brunch/bin/brunch b -p
cd ..
MIX_ENV=prod mix phx.digest
cd ../..
MIX_ENV=prod mix release

