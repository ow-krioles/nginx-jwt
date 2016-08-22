#!/bin/bash
if test "$#" -lt 1; then
  echo "Usage: $0 <applicaiton name> <environment name>"
  echo
  echo "e.g.  $0 footprints-tiles dev"
  exit 1
fi

APP_NAME=$1
ENV_NAME=$2

./scripts/build_deps.sh

script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
. scripts/common.sh
. scripts/build_proxy_base_image.sh
echo "sha1: $dockerfile_sha1"
dockerfile_sha1=$(cat $proxy_base_dir/Dockerfile | openssl sha1 | sed 's/^.* //')

docker tag -f proxy-base-image:$dockerfile_sha1 proxy-base-image:latest

proxy_image_exists=$(docker images | grep "nginx-jwt-$APP_NAME\s*") || true

docker build -t="nginx-jwt-$APP_NAME" --force-rm $proxy_base_dir/bsg/$APP_NAME
docker tag -f nginx-jwt-$APP_NAME openwhere/nginx-jwt-$APP_NAME:$ENV_NAME
docker push openwhere/nginx-jwt-$APP_NAME:$ENV_NAME