#!/bin/bash
# Abort script on any failures
set -e

my_loc="$(cd "$(dirname $0)" && pwd)"
source $my_loc/utils.sh

del_image=0
del_tmp=0
portable=0
standard=0

#image_name="bgromov/rosndk:r14b"
image_name="is4s/rosndk:r15b_standalone"

if [[ $# -lt 1 ]] ; then
    standard=1
    output_path=$my_loc"/output"
fi

for var in "$@"
do
    if [[ ${var} == "--help" ]] ||  [[ ${var} == "-h" ]] ; then
        help=1
    fi
    if [[ ${var} == "--delete-image" ]] ; then
        del_image=1
    fi

    if [[ ${var} == "--delete-tmp" ]] ; then
        del_tmp=1
    fi

    if [[ ${var} == "--portable" ]] ; then
        output_path=$my_loc"/output"
        portable=1
    fi

    if [[ ${var} == "--bash" ]] ; then
        output_path=$my_loc"/output"
        standard=1
        bash=1
    fi

    if [[ ${var} == "--raw" ]] ; then
        standard=1
        output_path=$my_loc"/output"
        if [[ $# -eq 2 ]]; then
          output_path=$2
        fi
    fi
done

if [[ $help -eq 1 ]] ; then
    echo "Usage: $0 [-h | --help] [--delete-image] [--delete-tmp] [--portable] [--standard] [output_dir]"
    echo "  example: $0 --raw /path/to/output/dir, will create a raw output in the desired path (only useful from Docker)"
    echo "  example: $0 --portable, will create a portable tar.gz output in the current directory."
    echo "  example: $0 --delete-image, will delete the Docker image created for the build."
    echo "  example: $0 --delete-tmp, will delete the Docker temp files created during build and rebuilds."
    echo "  Only one action can be executed per invocation."
    exit 1
fi

if [[ $del_image -eq 1 ]]; then
  echo
  echo -e '\e[34mDeleting docker image.\e[39m'
  echo
  docker rmi -f $image_name
  exit $?
fi

if [[ $del_tmp -eq 1 ]]; then
  echo
  echo -e '\e[34mDeleting docker temporary directory.\e[39m'
  echo
  rm -rf /var/lib/docker/tmp
  exit $?
fi

echo
echo -e '\e[34mRunning build. This will take a LONG time.\e[39m'
echo

# Requires docker 1.3+
cmd_exists docker || die 'docker was not found'

echo -e '\e[34mPulling base docker image.\e[39m'
docker pull $image_name


if [[ $standard -eq 1 ]]; then
  echo -e '\e[34mSetting output_path to: '$output_path'.\e[39m'
  echo
  if [[ $bash -eq 1 ]]; then
      docker run --rm=true -it -v $my_loc:/opt/roscpp_android -v $output_path:/opt/roscpp_output -i $image_name /bin/bash
  else
      docker run --rm=true -t -v $my_loc:/opt/roscpp_android -v $output_path:/opt/roscpp_output -i $image_name /opt/roscpp_android/do_everything.sh /opt/roscpp_output 
  fi
  exit $?
fi

if [[ $portable -eq 1 ]]; then
  echo -e '\e[34mBuilding in portable mode.\e[39m'
  echo
  docker run --rm=true -t -v $my_loc:/opt/roscpp_android -v $output_path:/opt/roscpp_output -i $image_name /opt/roscpp_android/do_everything.sh /opt/roscpp_output --portable
  echo
  echo -e '\e[34mCreating output/roscpp_android_ndk.tar.gz.\e[39m'
  echo
  cd output
  tar czf roscpp_android_ndk.tar.gz roscpp_android_ndk
  chown $UID roscpp_android_ndk.tar.gz
  exit $?
fi
