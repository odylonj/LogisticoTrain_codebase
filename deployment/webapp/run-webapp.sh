#!/bin/sh
set -eu

npm ci
rm -rf build/* buildInfos/*
npm run build
