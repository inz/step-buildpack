#!/bin/bash

detect_default_buildpacks() {
  buildpacks_path=$1

  case ${target_platform} in
    heroku)
      # Officially supported buildpacks from Heroku
      # (https://devcenter.heroku.com/articles/buildpacks#officially-supported-buildpacks)
      default_buildpacks=(
        "https://github.com/heroku/heroku-buildpack-ruby"
        "https://github.com/heroku/heroku-buildpack-nodejs"
        "https://github.com/heroku/heroku-buildpack-clojure"
        "https://github.com/heroku/heroku-buildpack-python"
        "https://github.com/heroku/heroku-buildpack-java"
        "https://github.com/heroku/heroku-buildpack-gradle"
        "https://github.com/heroku/heroku-buildpack-grails"
        "https://github.com/heroku/heroku-buildpack-scala"
        "https://github.com/heroku/heroku-buildpack-play"
        "https://github.com/heroku/heroku-buildpack-php"
        "https://github.com/heroku/heroku-buildpack-go"
      )
      ;;
    cloud-foundry)
      # Cloud Foundry System Buildpacks
      # (https://docs.cloudfoundry.org/buildpacks/#system-buildpacks)
      default_buildpacks=(
        "https://github.com/cloudfoundry/java-buildpack"
        "https://github.com/cloudfoundry/ruby-buildpack"
        "https://github.com/cloudfoundry/nodejs-buildpack"
        "https://github.com/cloudfoundry/go-buildpack"
        "https://github.com/cloudfoundry/php-buildpack"
        "https://github.com/cloudfoundry/python-buildpack"
        "https://github.com/cloudfoundry/staticfile-buildpack"
        "https://github.com/cloudfoundry/binary-buildpack"
      )
      ;;
  esac

  for buildpack in "${default_buildpacks[@]}"; do
    buildpack_path=${buildpacks_path}/${buildpack##*/}
    fetch_buildpack ${buildpacks_path} ${buildpack}
    
    if ${buildpack_path}/bin/detect . &>/dev/null; then
      echo ${buildpack}
      break
    else
      continue
    fi
  done
}

fetch_buildpack() {
  buildpacks_path=$1
  buildpack_url=$2

  buildpack_path=${buildpacks_path}/${buildpack##*/}
  if ! [ -d ${buildpack_path} ]; then
    git clone --depth 1 ${buildpack} ${buildpack_path} 1>&2
  else
    pushd ${buildpack_path} &>/dev/null
    git fetch origin master 1>&2
    git reset --hard FETCH_HEAD 1>&2
    git clean -fd 1>&2
    popd &>/dev/null
  fi
}

fix_buildpack_compile() {
  mkdir -p bin
  export PATH=$PWD/bin:$PATH
  
  # Work around timeout set for curl in buildpack compile calls
  echo '/usr/bin/curl $@ --max-time 300' >bin/curl
  chmod +x bin/curl
  
  # Work around tar permission issue
  echo '/bin/tar $@ --no-same-owner' >bin/tar
  chmod +x bin/tar
  
  # Silence bundler root warning
  export BUNDLE_SILENCE_ROOT_WARNING=true
}

main() {
  set -e

  fix_buildpack_compile

  [ "${WERCKER_BUILDPACK_BUILD_DEBUG}" = "true" ] && set -x
  buildpacks_path=${WERCKER_CACHE_DIR/buildpacks}
  target_platform=${WERCKER_BUILDPACK_BUILD_PLATFORM:-heroku}
  case ${target_platform} in
    heroku)
      stack="cedar-14"
      ;;
    cloudfoundry)
      stack="cflinuxfs2"
      ;;
  esac
  export STACK=${WERCKER_BUILDPACK_BUILD_STACK:-$stack}
  
  buildpacks=${WERCKER_BUILDPACK_BUILD_BUILDPACKS:-$(ruby -rjson -e 'puts JSON.parse(File.read("app.json"))["buildpacks"].map {|u| u["url"]}' || true)}

  # If app.json does not specify buildpacks, detect application type using
  # default buildpacks.
  if [ "${buildpacks}" = "" ]; then
    buildpacks=$(detect_default_buildpacks ${buildpacks_path})
  fi

  rm -f .slugignore
  
  for buildpack in ${buildpacks}; do
    fetch_buildpack ${buildpacks_path} ${buildpack}
    buildpack_path=${buildpacks_path}/${buildpack##*/}
    buildpack_cache_path=${buildpack_path}/buildpack-cache/${buildpack##*/}
    
    ${buildpack_path}/bin/detect .
    ${buildpack_path}/bin/compile . ${buildpack_cache_path}
  done  
}

main