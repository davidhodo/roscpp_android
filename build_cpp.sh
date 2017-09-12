#!/bin/bash

# print a help screen
function print_help {
    echo "Usage: $0 [options] -p prefix_path"
    echo "Options:"
    echo "  -p --path <path> target path to build (required)"
    echo "  -b --build-type <cmake_build_type> build binaries with the corresponding cmake build flag"
    echo "                                     Release (default) / Debug / RelWithDebInfo"
    echo "  -v --verbose <val> output more verbose error messages"
    echo "                     0: normal (default) / 1: verbose"
    echo "  -h --help display this help screen."
    echo
    echo "Example:"
    echo "    $0 -p /home/user/my_workspace"
    echo
}

# if no arguments are given print the help screen and exit with error
if [ $# == 0 ]; then
    print_help
    exit 1
fi

# default values
CMAKE_BUILD_TYPE=Release
VERBOSE=""

# get the base folder
my_loc="$(cd "$(dirname $0)" && pwd)"

# source utilities to our environment
source $my_loc/config.sh
source $my_loc/utils.sh


# process options
while [[ $# > 1 ]]
do
    key="$1"
    case $key in
        -b|--build-type)
            CMAKE_BUILD_TYPE=$2
            shift # past argument
        ;;
        -v|--verbose)
            if [ $2 -ne 0 ]; then
                VERBOSE="--debug=v"
            else
                VERBOSE=""
            fi
            shift # past argument
        ;;
        -h|--help)
            print_help
            exit 0
            shift # past argument
        ;;
        -p|--path)
            TARGET_PATH=$2
            shift # past argument
        ;;
        *)
            # unknown option
            echo "Unknown option!"
            exit 1
        ;;
    esac
    shift # past argument or value
done


# Abort script on any failures
set -e

cmd_exists catkin_make || die 'catkin_make was not found'
[ "$CMAKE_PREFIX_PATH" = "" ] && die 'could not find target basedir. Have you run build_catkin.sh and sourced setup.bash?'
[ "$RBA_TOOLCHAIN" = "" ] && die 'could not find android.toolchain.cmake, you should set RBA_TOOLCHAIN variable.'

# check if system is 64 bits
if echo $system | grep _64 >/dev/null; then
    host64='-DANDROID_NDK_HOST_X64=YES'
fi

# get the prefix path
prefix=$(cd $TARGET_PATH && pwd)

python=$(which python)
python_lib=/usr/lib/x86_64-linux-gnu/libpython2.7.so
python_inc=/usr/include/python2.7
python2_inc=/usr/include/x86_64-linux-gnu/python2.7

cd $prefix/catkin_ws

echo
echo -e '\e[34mRunning catkin_make.\e[39m'
echo

# Use ROS_PARALLEL_JOBS=-j1 to compile with only one core (Useful to point errors in catkin_make)
export ROS_PARALLEL_JOBS="-j$PARALLEL_JOBS -l$PARALLEL_JOBS"
#export ROS_PARALLEL_JOBS=-j1 

./src/catkin/bin/catkin_make --cmake-args -DCMAKE_TOOLCHAIN_FILE=$RBA_TOOLCHAIN \
    -DCMAKE_SYSTEM_NAME=Android \
    -DANDROID_TOOLCHAIN_NAME=arm-linux-androideabi-clang -DANDROID_ABI=armeabi-v7a \
    -DANDROID_NATIVE_API_LEVEL=23 \
    -DANDROID_STL=c++_static \
    -DANDROID=TRUE  \
    -DBUILD_SHARED_LIBS=0 \
    -DCATKIN_ENABLE_TESTING=0 \
    -DCMAKE_VERBOSE_MAKEFILE=$VERBOSE \
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}  \
    -DBoost_NO_BOOST_CMAKE=ON  \
    -DBOOST_ROOT=$CMAKE_PREFIX_PATH  \
    -DBOOST_INCLUDEDIR=$CMAKE_PREFIX_PATH/include/boost  \
    -DBOOST_LIBRARYDIR=$CMAKE_PREFIX_PATH/lib  \
    -DROSCONSOLE_BACKEND=print  \
    -DEIGEN3_INCLUDE_DIR=$ANDROID_INSTALL_PATH/include


#catkin_make $VERBOSE --cmake-args -DCMAKE_TOOLCHAIN_FILE=$RBA_TOOLCHAIN -DANDROID_TOOLCHAIN_NAME=$toolchain -DANDROID_NATIVE_API_LEVEL=$platform $host64 -DPYTHON_EXECUTABLE=$python -DPYTHON_LIBRARY=$python_lib -DPYTHON_INCLUDE_DIR=$python_inc -DPYTHON_INCLUDE_DIR2=$python2_inc -DBUILD_SHARED_LIBS=0 -DCMAKE_INSTALL_PREFIX=$CMAKE_PREFIX_PATH -DBoost_NO_BOOST_CMAKE=ON -DBOOST_ROOT=$CMAKE_PREFIX_PATH -DANDROID=TRUE -DBOOST_INCLUDEDIR=$CMAKE_PREFIX_PATH/include/boost -DBOOST_LIBRARYDIR=$CMAKE_PREFIX_PATH/lib -DROSCONSOLE_BACKEND=print -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DEIGEN3_INCLUDE_DIR=$CMAKE_PREFIX_PATH/lib/eigen
    #-DBoost_NO_BOOST_CMAKE=TRUE -DBoost_NO_SYSTEM_PATHS=TRUE -DBOOST_ROOT:PATHNAME=$CMAKE_PREFIX_PATH/include/boost \
    #-DBOOST_INCLUDEDIR:PATH=$CMAKE_PREFIX_PATH/include/boost -DBOOST_LIBRARYDIR:PATH=$CMAKE_PREFIX_PATH/lib \
    #-DBoost_USE_STATIC_LIBS=ON -DBoost_NO_BOOST_CMAKE=ON

   # -DBOOST_INCLUDEDIR:PATH=$CMAKE_PREFIX_PATH/include -DBOOST_LIBRARYDIR:PATH=$CMAKE_PREFIX_PATH/lib
   # -DBOOST_ROOT:PATHNAME=$CMAKE_PREFIX_PATH/include

echo
echo -e '\e[34mInstalling.\e[39m'
echo

cd build && make --silent install
