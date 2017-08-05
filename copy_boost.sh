#!/bin/bash

# Abort script on any failures
set -e

my_loc="$(cd "$(dirname $0)" && pwd)"
source $my_loc/config.sh
source $my_loc/utils.sh

if [ $# != 1 ] || [ $1 == '-h' ] || [ $1 == '--help' ]; then
    echo "Usage: $0 prefix_path"
    echo "  example: $0 /home/user/my_workspace"
    exit 1
fi

prefix=$(cd $1 && pwd)

echo
echo -e '\e[34mCopying boost.\e[39m'
echo

[ "$CMAKE_PREFIX_PATH" = "" ] && die 'could not find target basedir. Have you run build_catkin.sh and sourced setup.bash?'
mkdir -p $CMAKE_PREFIX_PATH/lib
cd $prefix/build/lib
for i in *.a # Rename and move libraries (remove the gcc type, so on)
do
    #mv "$i" "`echo $i | sed 's/000//'`"
    #cp lib/lib*.a ./
    cp "$i" $CMAKE_PREFIX_PATH/lib/"`echo $i | sed 's/ *\-.*//'`.a"
done

cd ../include
mkdir -p $CMAKE_PREFIX_PATH/include
cp -R boost-1_64/boost $CMAKE_PREFIX_PATH/include/
