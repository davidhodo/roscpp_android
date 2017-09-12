#!/bin/bash

export ANDROID_HOME=/opt/android-sdk-linux
export ANDROID_STANDALONE_TOOLCHAIN=/opt/android-toolchain

export ANDROID_NDK=$ANDROID_HOME/ndk-bundle
export PATH=$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/ndk-bundle/build/tools:$PATH
#export RBA_TOOLCHAIN=ANDROID_STANDALONE_TOOLCHAIN/build/cmake/android.toolchain.cmake
RBA_TOOLCHAIN=/opt/android-sdk-linux/ndk-bundle/build/cmake/android.toolchain.cmake
