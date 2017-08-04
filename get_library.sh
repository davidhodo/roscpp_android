#!/bin/bash

# Abort script on any failures
set -e

my_loc="$(cd "$(dirname $0)" && pwd)"
source $my_loc/config.sh
source $my_loc/utils.sh

if [ $# != 2 ] || [ $1 == '-h' ] || [ $1 == '--help' ]; then
    echo "Usage: $0 library_name library_prefix_path"
    echo "  example: $0 tinyxml /home/user/my_workspace/tinyxml"
    exit 1
fi

echo
echo -e '\e[34mGetting '$1'.\e[39m'
echo

prefix=$(cd $2 && pwd)

if [ $1 == 'boost' ]; then
    URL=https://github.com/bgromov/Boost-for-Android.git
    COMP='git'
elif [ $1 == 'bzip2' ]; then
    URL=https://github.com/osrf/bzip2_cmake.git
    COMP='git'
elif [ $1 == 'catkin' ]; then
    URL='-b 0.6.5 https://github.com/ros/catkin.git'
    COMP='git'
elif [ $1 == 'console_bridge' ]; then
    URL=https://github.com/ros/console_bridge.git
    COMP='git'
    HASH='964a9a70e0fc607476e439b8947a36b07322c304'
elif [ $1 == 'eigen' ]; then
    URL=https://github.com/tulku/eigen.git
    COMP='git'
elif [ $1 == 'log4cxx' ]; then
    URL=http://mirrors.sonic.net/apache/logging/log4cxx/0.10.0/apache-log4cxx-0.10.0.tar.gz
    COMP='gz'
elif [ $1 == 'libxml2' ]; then
    URL=ftp://xmlsoft.org/libxml2/libxml2-2.9.1.tar.gz
    COMP='gz'
elif [ $1 == 'lz4' ]; then
    URL=https://github.com/Cyan4973/lz4/archive/r124.tar.gz
    COMP='gz'
elif [ $1 == 'tinyxml' ]; then
    URL=https://github.com/chadrockey/tinyxml_cmake
    COMP='git'
elif [ $1 == 'yaml-cpp' ]; then
    URL=https://github.com/ekumenlabs/yaml-cpp.git
    COMP='git'
elif [ $1 == 'rospkg' ]; then
    URL=https://github.com/ros-infrastructure/rospkg.git
    COMP='git'
    HASH='93b1b72f256badf22ccc926b22646f2e83b720fd'
elif [ $1 == 'protobuf' ]; then
    URL=https://github.com/google/protobuf/archive/v3.3.0.tar.gz
    COMP='gz'
fi

if [ $COMP == 'gz' ]; then
    download_gz $URL $prefix
elif [ $COMP == 'bz2' ]; then
    download_bz2 $URL $prefix
elif [ $COMP == 'git' ];then
    git clone $URL $prefix/$1
fi

if [ $1 == 'boost' ]; then
 cd $prefix/boost
 NDK_RN=14b ANDROID_NDK_TOOLCHAIN=$ANDROID_STANDALONE_TOOLCHAIN ./build-android.sh $ANDROID_NDK --boost=1.64.0
elif [ -v HASH ]; then
    cd $prefix/$1
    git checkout $HASH
fi
