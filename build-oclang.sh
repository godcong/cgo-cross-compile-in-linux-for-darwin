#!/bin/bash

# Setting the download osx_sdk output directory
DOWNLOAD_PATH="downloads"

# Configure the container for OSX cross compilation
WORK_TEMP="tmp"
# Absolute address must be entered
TARGET_PATH="$(pwd)/../build"

OSXCROSS_PATH="$TARGET_PATH/osxcross"
OSXCROSS_MIRROR="https://github.com/tpoechtrager/osxcross.git"
LD_LIBRARY_PATH="$OSXCROSS_PATH/target/lib:$LD_LIBRARY_PATH"

OSX_SDK=MacOSX11.3.sdk
OSX_SDK_PATH="$DOWNLOAD_PATH/$OSX_SDK.tar.xz"
OSX_DOWNLOAD_URL="https://github.com/phracker/MacOSX-SDKs/releases/download/11.3/${OSX_SDK}.tar.xz"
OSX_SDK_TEMP="$WORK_TEMP/$OSX_SDK"

function check_build_environment() {
  if [ ! -f "updated" ]; then
    echo "warning: install required packages,something very old packages may be not found!"
    apt update
    apt install -y automake autogen build-essential ca-certificates
    apt install -y gcc-5-arm-linux-gnueabi g++-5-arm-linux-gnueabi libc6-dev-armel-cross \
      gcc-5-arm-linux-gnueabihf g++-5-arm-linux-gnueabihf libc6-dev-armhf-cross \
      gcc-5-aarch64-linux-gnu g++-5-aarch64-linux-gnu libc6-dev-arm64-cross \
      gcc-5-mips-linux-gnu g++-5-mips-linux-gnu libc6-dev-mips-cross \
      gcc-5-mipsel-linux-gnu g++-5-mipsel-linux-gnu libc6-dev-mipsel-cross \
      gcc-5-mips64-linux-gnuabi64 g++-5-mips64-linux-gnuabi64 libc6-dev-mips64-cross \
      gcc-5-mips64el-linux-gnuabi64 g++-5-mips64el-linux-gnuabi64 libc6-dev-mips64el-cross \
      gcc-5-multilib g++-5-multilib gcc-mingw-w64 g++-mingw-w64 clang llvm-dev
    apt install -y gcc-6-arm-linux-gnueabi g++-6-arm-linux-gnueabi libc6-dev-armel-cross \
      gcc-6-arm-linux-gnueabihf g++-6-arm-linux-gnueabihf libc6-dev-armhf-cross \
      gcc-6-aarch64-linux-gnu g++-6-aarch64-linux-gnu libc6-dev-arm64-cross \
      gcc-6-mips-linux-gnu g++-6-mips-linux-gnu libc6-dev-mips-cross \
      gcc-6-mipsel-linux-gnu g++-6-mipsel-linux-gnu libc6-dev-mipsel-cross \
      gcc-6-mips64-linux-gnuabi64 g++-6-mips64-linux-gnuabi64 libc6-dev-mips64-cross \
      gcc-6-mips64el-linux-gnuabi64 g++-6-mips64el-linux-gnuabi64 libc6-dev-mips64el-cross \
      gcc-6-s390x-linux-gnu g++-6-s390x-linux-gnu libc6-dev-s390x-cross \
      gcc-6-powerpc64le-linux-gnu g++-6-powerpc64le-linux-gnu libc6-dev-powerpc-ppc64-cross \
      gcc-8-riscv64-linux-gnu g++-8-riscv64-linux-gnu libc6-dev-riscv64-cross \
      gcc-6-multilib g++-6-multilib gcc-7-multilib g++-7-multilib gcc-mingw-w64 g++-mingw-w64
    apt install -y clang llvm-dev libtool libxml2-dev uuid-dev libssl-dev swig openjdk-8-jdk pkg-config patch \
      make xz-utils cpio wget zip unzip p7zip git mercurial bzr texinfo help2man cmake curl mercurial
    apt install -y libstdc++-10* libstdc++6-10*
    apt install -y libssl1.1 openssl ca-certificates
    update-ca-certificates
    apt clean
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
    find /var/log -type f | while read f; do echo -ne '' >$f; done
    echo >>updated
  fi
}

# Fix any stock package issues
ln -s /usr/include/asm-generic /usr/include/asm

# Fix git safe.directory
# RUN git config --global --add safe.directory '*'

# Add patches directory for patching later
#cp -r ./patches /patches

##########################
# Darwin Toolchain build #
##########################
# Download the osx sdk and build the osx toolchain
# We download the osx sdk, patch it and pack it again to be able to throw the patched version at osxcross
function download_osx_sdk() {
  wd=$(pwd)
  if [ ! -d $DOWNLOAD_PATH ]; then
    mkdir -p $DOWNLOAD_PATH
  fi
  if [ ! -f $OSX_SDK_PATH ]; then
    cd "$DOWNLOAD_PATH" || exit
    echo "Downloading $OSX_SDK from $OSX_DOWNLOAD_URL..."
    wget -O "$OSX_SDK.tar.xz" -p "$OSX_DOWNLOAD_URL"
    cd "$wd" || exit
  fi
}

function tar_unpack_osx_sdk() {
  if [ ! -d "$WORK_TEMP" ]; then
    mkdir -p "$WORK_TEMP"
  fi
  if [ ! -f $OSX_SDK_PATH ]; then
    echo "Error: OSX_SDK not found in $DOWNLOAD_PATH"
    exit 0
  fi
  echo "Tar unpacking..."
  if [ -d "$OSX_SDK_TEMP" ]; then
    echo "removing previous temporary"
    rm -rf "$OSX_SDK_TEMP"
  fi
  tar -xf "$OSX_SDK_PATH" -C "$WORK_TEMP"
}

function tar_pack_osx_sdk() {
  if [ ! -d "$OSX_SDK_TEMP" ]; then
    echo "Error: OSX_SDK was not tar in $OSX_SDK_TEMP"
    exit 0
  fi
  echo "Tar packing..."
  cd "$WORK_TEMP" || exit
  tar -cf - "$OSX_SDK" | xz -c - >"$WORK_TEMP/$OSX_SDK.tar.xz" && rm -rf "$OSX_SDK"
}

function push_patch_to_osx_sdk() {
  if [ ! -d "$OSX_SDK_TEMP" ]; then
    echo "Error: OSX_SDK was not tar in $OSX_SDK_TEMP"
    exit 0
  fi
  cp ./patch/patch.tar.xz "$OSX_SDK_TEMP/usr/include/c++"
}

function clone_repo() {
  if [ ! -d "$OSXCROSS_PATH" ]; then
    cd "$TARGET_PATH" || exit
    echo "Cloning toolchain from $OSXCROSS_MIRROR..."
    git clone $OSXCROSS_MIRROR
    cd "$OSXCROSS_PATH" || exit
    git checkout master

  fi
}

function build_toolchain() {
  wd=$(pwd)
  if [ ! -d "$TARGET_PATH" ]; then
    mkdir -p "$TARGET_PATH"
  fi

  clone_repo
  cd "$wd" || exit
  check_build_environment
  cd "$OSXCROSS_PATH" || exit
  OSX_VERSION_MIN=10.13 UNATTENDED=1 LD_LIBRARY_PATH=$LD_LIBRARY_PATH "./build.sh"
  cd "$wd" || exit

}

function check_build_environment() {
  if [ ! -f "$OSXCROSS_PATH/tarballs/$OSX_SDK.tar.xz" ]; then
    download_osx_sdk
    tar_unpack_osx_sdk
    push_patch_to_osx_sdk
    tar_pack_osx_sdk
  fi

  if [ ! -f "$WORK_TEMP/$OSX_SDK.tar.xz" ]; then
    return
  fi

  if [ ! -f "$OSXCROSS_PATH/tarballs/$OSX_SDK.tar.xz" ]; then
    echo "Moving $WORK_TEMP/$OSX_SDK.tar.xz to $OSXCROSS_PATH/tarballs/"
    mv "$WORK_TEMP/$OSX_SDK.tar.xz" "$OSXCROSS_PATH/tarballs/"
  fi
}

function setting_global() {
  echo "export PATH=$OSXCROSS_PATH/target/bin/:$PATH" >>/etc/profile
  echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH" >>/etc/profile
}

build_toolchain
setting_global

echo "Building successfully"
