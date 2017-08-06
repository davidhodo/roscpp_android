system=$(uname -s | tr 'DL' 'dl')-$(uname -m)
gcc_version=4.9
toolchain=arm-linux-androideabi-$gcc_version
platform=android-19
ROS_DISTRO=kinetic
PYTHONPATH=/opt/ros/$ROS_DISTRO/lib/python2.7/dist-packages:$PYTHONPATH
# Enable this value for debug build
#CMAKE_BUILD_TYPE=Debug

