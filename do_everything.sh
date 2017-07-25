#!/bin/bash

# Abort script on any failures
set -e

# Define the number of simultaneous jobs to trigger for the different
# tasks that allow it. Use the number of available processors in the
# system.
export PARALLEL_JOBS=$(nproc)

if [[ -f /opt/ros/indigo/setup.bash ]] ; then
    source /opt/ros/indigo/setup.bash
else
    echo "ROS environment not found, please install it"
    exit 1
fi

my_loc="$(cd "$(dirname $0)" && pwd)"
source $my_loc/config.sh
source $my_loc/utils.sh
debugging=0
skip=0
portable=0
help=0

# verbose is a bool flag indicating if we want more verbose output in
# the build process. Useful for debugging build system or compiler errors.
verbose=0


if [[ $# -lt 1 ]] ; then
    help=1
fi

for var in "$@"
do
    if [[ ${var} == "--help" ]] ||  [[ ${var} == "-h" ]] ; then
        help=1
    fi
    if [[ ${var} == "--skip" ]] ; then
        skip=1
    fi

    if [[ ${var} == "--debug-symbols" ]] ; then
        debugging=1
    fi

    if [[ ${var} == "--portable" ]] ; then
        portable=1
    fi
done

if [[ $help -eq 1 ]] ; then
    echo "Usage: $0 prefix_path [-h | --help] [--skip] [--debug-symbols]"
    echo "  example: $0 /home/user/my_workspace"
    exit 1
fi

if [[ $skip -eq 1 ]]; then
   echo "-- Skiping projects update"
else
   echo "-- Will update projects"
fi

if [[ $debugging -eq 1 ]]; then
   echo "-- Building workspace WITH debugging symbols"
else
   echo "-- Building workspace without debugging symbols"
fi

if [ ! -d $1 ]; then
    mkdir -p $1
fi

prefix=$(cd $1 && pwd)

run_cmd() {
    cmd=$1.sh
    shift
    $my_loc/$cmd $@ || die "$cmd $@ died with error code $?"
}

if [ -z $ANDROID_NDK ] ; then
    die "ANDROID_NDK ENVIRONMENT NOT FOUND!"
fi

if [ -z $ROS_DISTRO ] ; then
    die "HOST ROS ENVIRONMENT NOT FOUND! Did you source /opt/ros/indigo/setup.bash"
fi

[ -d $standalone_toolchain_path ] || run_cmd setup_standalone_toolchain

echo
echo -e '\e[34mGetting library dependencies.\e[39m'
echo

mkdir -p $prefix/libs

# Start with catkin since we use it to build almost everything else
[ -d $prefix/target ] || mkdir -p $prefix/target
export CMAKE_PREFIX_PATH=$prefix/target

# Get the android ndk build helper script
# If file doesn't exist, then download and patch it
if ! [ -e $prefix/android.toolchain.cmake ]; then
    cd $prefix
    download 'https://raw.githubusercontent.com/taka-no-me/android-cmake/556cc14296c226f753a3778d99d8b60778b7df4f/android.toolchain.cmake'
    patch -p0 -N -d $prefix < /opt/roscpp_android/patches/android.toolchain.cmake.patch
    cat $my_loc/files/android.toolchain.cmake.addendum >> $prefix/android.toolchain.cmake
fi

export RBA_TOOLCHAIN=$prefix/android.toolchain.cmake

# Now get boost with a specialized build
[ -d $prefix/libs/boost ] || run_cmd get_library boost $prefix/libs
[ -d $prefix/libs/bzip2 ] || run_cmd get_library bzip2 $prefix/libs
[ -d $prefix/libs/uuid ] || run_cmd get_library uuid $prefix/libs
[ -d $prefix/libs/tinyxml ] || run_cmd get_library tinyxml $prefix/libs
[ -d $prefix/libs/catkin ] || run_cmd get_library catkin $prefix/libs
[ -d $prefix/libs/console_bridge ] || run_cmd get_library console_bridge $prefix/libs
[ -d $prefix/libs/lz4-r124 ] || run_cmd get_library lz4 $prefix/libs
[ -d $prefix/libs/libxml2-2.9.1 ] || run_cmd get_library libxml2 $prefix/libs
[ -d $prefix/libs/eigen ] || run_cmd get_library eigen $prefix/libs
[ -d $prefix/libs/assimp-3.1.1 ] || run_cmd get_library assimp $prefix/libs
[ -d $prefix/libs/yaml-cpp ] || run_cmd get_library yaml-cpp $prefix/libs
[ -d $prefix/libs/apache-log4cxx-0.10.0 ] || run_cmd get_library log4cxx $prefix/libs
# get rospkg dependency for pluginlib support at build time
[ -d $my_loc/files/rospkg ] || run_cmd get_library rospkg $my_loc/files

[ -f $prefix/target/bin/catkin_make ] || run_cmd build_library catkin $prefix/libs/catkin
. $prefix/target/setup.bash

echo
echo -e '\e[34mGetting ROS packages\e[39m'
echo

if [[ $skip -ne 1 ]] ; then
    run_cmd get_ros_stuff $prefix

    echo
    echo -e '\e[34mApplying patches.\e[39m'
    echo

    # patch CMakeLists.txt for lz4 library - Build as a library
    apply_patch /opt/roscpp_android/patches/lz4.patch

    # Patch qhull - Don't install shared libraries
    # TODO: Remove shared libraries to avoid hack in parse_libs.py
    #apply_patch /opt/roscpp_android/patches/qhull.patch

    # Patch eigen - Rename param as some constant already has the same name
    # TODO: Fork and push changes to creativa's repo
    apply_patch /opt/roscpp_android/patches/eigen.patch

    # Patch log4cxx - Add missing headers
    apply_patch /opt/roscpp_android/patches/log4cxx.patch

    ## Demo Application specific patches

fi

echo
echo -e '\e[34mBuilding library dependencies.\e[39m'
echo

# if the library doesn't exist, then build it
[ -f $prefix/target/lib/libbz2.a ] || run_cmd build_library bzip2 $prefix/libs/bzip2
[ -f $prefix/target/lib/libboost_system.a ] || run_cmd copy_boost $prefix/libs/boost
[ -f $prefix/target/lib/libtinyxml.a ] || run_cmd build_library tinyxml $prefix/libs/tinyxml
[ -f $prefix/target/lib/libconsole_bridge.a ] || run_cmd build_library console_bridge $prefix/libs/console_bridge
[ -f $prefix/target/lib/liblz4.a ] || run_cmd build_library lz4 $prefix/libs/lz4-r124/cmake_unofficial
[ -f $prefix/target/lib/libxml2.a ] || run_cmd build_library_with_toolchain libxml2 $prefix/libs/libxml2-2.9.1
[ -f $prefix/target/lib/libeigen.a ] || run_cmd build_eigen $prefix/libs/eigen
[ -f $prefix/target/lib/libyaml-cpp.a ] || run_cmd build_library yaml-cpp $prefix/libs/yaml-cpp
[ -f $prefix/target/lib/liblog4cxx.a ] || run_cmd build_library_with_toolchain log4cxx $prefix/libs/apache-log4cxx-0.10.0


echo
echo -e '\e[34mCross-compiling ROS.\e[39m'
echo

if [[ $debugging -eq 1 ]];then
    echo "Build type = DEBUG"
    run_cmd build_cpp -p $prefix -b Debug -v $verbose
else
    echo "Build type = RELEASE"
    run_cmd build_cpp -p $prefix -b Release -v $verbose
fi

echo
echo -e '\e[34mSetting up ndk project.\e[39m'
echo

run_cmd setup_ndk_project $prefix/roscpp_android_ndk $portable

echo
echo -e '\e[34mCreating Android.mk.\e[39m'
echo

# Library path is incorrect for urdf.
# TODO: Need to investigate the source of the issue
sed -i 's/set(libraries "urdf;/set(libraries "/g' $CMAKE_PREFIX_PATH/share/urdf/cmake/urdfConfig.cmake

run_cmd create_android_mk $prefix/catkin_ws/src $prefix/roscpp_android_ndk

if [[ $debugging -eq 1 ]];then
    sed -i "s/#LOCAL_EXPORT_CFLAGS/LOCAL_EXPORT_CFLAGS/g" $prefix/roscpp_android_ndk/Android.mk
fi

# copy Android makfile to use in building the apps with roscpp_android_ndk
cp $my_loc/files/Android.mk.move_base $prefix/roscpp_android_ndk/Android.mk

echo
echo -e '\e[34mCreating sample app.\e[39m'
echo

( cd $prefix && run_cmd sample_app sample_app $prefix/roscpp_android_ndk )

echo
echo -e '\e[34mBuilding apk.\e[39m'
echo

# Copy specific Android makefile to build the image_transport_sample_app
# This makefile includes the missing opencv 3rd party libraries.
( cp $my_loc/files/Android.mk.image_transport $prefix/roscpp_android_ndk/Android.mk)

( cd $prefix && run_cmd sample_app image_transport_sample_app $prefix/roscpp_android_ndk )



echo
echo 'done.'
echo 'summary of what just happened:'
echo '  target/      was used to build static libraries for ros software'
echo '    include/   contains headers'
echo '    lib/       contains static libraries'
echo '  roscpp_android_ndk/     is a NDK sub-project that can be imported into an NDK app'
echo '  sample_app/  is an example of such an app, a native activity'
echo '  sample_app/bin/sample_app-debug.apk  is the built apk, it implements a subscriber and a publisher'

