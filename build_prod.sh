#!/bin/bash
cd apps/web
./node_modules/brunch/bin/brunch b -p
MIX_ENV=prod mix phoenix.digest
cd ../..
MIX_ENV=prod mix release --env=prod

