#!/bin/bash
source .env
cd apps/web/assets
npm install
npm run compile
cd ..
MIX_ENV=prod mix phx.digest
cd ../..
MIX_ENV=prod mix release

