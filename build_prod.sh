#!/bin/bash
source .env
mix deps.get
cd apps/web/assets
sudo npm install
npm run compile
cd ..
MIX_ENV=prod mix phx.digest
cd ../..
MIX_ENV=prod mix release

