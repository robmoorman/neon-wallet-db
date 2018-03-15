#!/bin/bash

export REDISTOGO_URL="http://localhost:6379"
export MONGOURL=127.0.0.1:27017
export MONGOAPP=neonwallet
export MONGOUSER=neon
export MONGOPASS=wallet
export NET=PrivNet
export NODEAPI="http://127.0.0.1:20333"

gunicorn api
