#!/bin/bash
if test "$#" -lt 1; then
  echo "Usage: $0 <applicaiton name> <environment name>"
  echo
  echo "e.g.  $0 footprints-tiles dev"
  exit 1
fi

APP_NAME=$1
ENV_NAME=$2
. scripts/common.sh

proxy_dir=$proxy_base_dir/bsg/$APP_NAME
echo "proxy_dir: $proxy_dir"

DOCKER_VERSION=`docker --version | cut -f3 | cut -d '.' -f2`
[ ${DOCKER_VERSION} -lt 12 ] && TAG_FLAG='-f' || TAG_FLAG=''

./scripts/build_deps.sh
./scripts/build_proxy_base_image.sh
echo "sha1: $dockerfile_sha1"
dockerfile_sha1=$(cat $proxy_base_dir/Dockerfile | openssl sha1 | sed 's/^.* //')

docker tag ${TAG_FLAG} proxy-base-image:$dockerfile_sha1 proxy-base-image:latest

echo -e "${blue}Deploying Lua scripts and depedencies${no_color}"
rm -rf $proxy_dir/nginx/lua
mkdir -p $proxy_dir/nginx/lua
cp $root_dir/nginx-jwt.lua $proxy_dir/nginx/lua
cp -r lib/* $proxy_dir/nginx/lua

echo -e "${blue}Building the new image nginx-jwt-$APP_NAME ${no_color}"
docker build -t="nginx-jwt-$APP_NAME" --force-rm $proxy_base_dir/bsg/$APP_NAME
docker tag ${TAG_FLAG} nginx-jwt-$APP_NAME openwhere/nginx-jwt-$APP_NAME:$ENV_NAME
docker push openwhere/nginx-jwt-$APP_NAME:$ENV_NAME
