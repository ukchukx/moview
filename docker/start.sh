#!/bin/bash
docker run --restart unless-stopped --name moview --net host -d moview
