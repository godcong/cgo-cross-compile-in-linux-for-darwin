#!/bin/bash
readonly TOOLCHAIN="$(pwd)/../build/osxcross/target/bin"

declare -A BUILD_ENVS
BUILD_ENVS["cc"]="$TOOLCHAIN/o64-clang"
BUILD_ENVS["cxx"]="$TOOLCHAIN/o64-clang++"
BUILD_ENVS["arm64_ar"]="$TOOLCHAIN/arm64-apple-darwin20.4-ar"
BUILD_ENVS["amd64_ar"]="$TOOLCHAIN/x86_64-apple-darwin20.4-ar"
BUILD_ENVS["arm64_ld"]="$TOOLCHAIN/arm64-apple-darwin20.4-ld"
BUILD_ENVS["amd64_ld"]="$TOOLCHAIN/x86_64-apple-darwin20.4-ld"

function export_environment() {
  export CXX=${BUILD_ENVS["cxx"]}
  export CC=${BUILD_ENVS["cc"]}
  export PREFIX=/usr/local
  export CGO_ENABLED="1"
  GOARCH=$(go env $GOARCH)
  GOOS=$(go env $GOOS)
  if [ "$GOARCH" == "arm64" ] && [ "$GOOS" == "darwin" ]; then
    export HOST=arm64-apple-darwin15
    export AR=${BUILD_ENVS["arm64_ar"]}
    export LD=${BUILD_ENVS["arm64_ld"]}
  fi
  if [ "$GOARCH" == "amd64" ] && [ "$GOOS" == "darwin" ]; then
    export HOST=amd64-apple-darwin15
    export AR=${BUILD_ENVS["amd64_ar"]}
    export LD=${BUILD_ENVS["amd64_ld"]}
  fi
}

export_environment
go "$@"
