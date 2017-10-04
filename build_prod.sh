#!/bin/bash
source .env
cd apps/web/assets
./node_modules/brunch/bin/brunch b -p
cd ..
MIX_ENV=prod mix phx.digest
cd ../..
MIX_ENV=prod mix release --env=prod

