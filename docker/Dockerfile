FROM ubuntu:16.04
MAINTAINER David Hodo <david.hodo@gmail.com>

# Install ROS Indigo
RUN apt-get update && apt-get install -y wget git unzip
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu xenial main" > /etc/apt/sources.list.d/ros-latest.list'
RUN apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-key 421C365BD9FF1F717815A3895523BAEEB01FA116
RUN apt-get update && apt-get install --no-install-recommends -y ros-kinetic-ros-base python-wstool

RUN apt-get install -y wget git cmake autoconf automake libtool curl make g++ unzip python-lxml -y ccache

RUN dpkg --add-architecture i386 
RUN apt-get update -qq
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y openjdk-8-jdk libc6:i386 libstdc++6:i386 libgcc1:i386 libncurses5:i386 libz1:i386
RUN wget https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip 

# Update cmake to 3.8
RUN dpkg -P --force-all cmake
RUN wget https://cmake.org/files/v3.8/cmake-3.8.2.tar.gz && tar -xvf cmake-3.8.2.tar.gz && cd cmake-3.8.2/ && ./configure && make install && cd ../ && rm -Rf cmake-3.8.2*

# Install Android SDK & NDK
ENV ANDROID_HOME=/opt/android-sdk-linux 
RUN cd /opt && wget -q https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip -O android-sdk-tools.zip && unzip -q android-sdk-tools.zip -d ${ANDROID_HOME}  && rm -f android-sdk-tools.zip          
ENV PATH=/opt/android-sdk-linux/tools/bin:/opt/android-sdk-linux/tools:/opt/android-sdk-linux/platform-tools:$PATH

ENV ANDROID_NDK=/opt/android-sdk-linux/ndk-bundle 

RUN mkdir -p ${ANDROID_HOME}/licenses && echo 8933bad161af4178b1185d1a37fbf41ea5269c55 > ${ANDROID_HOME}/licenses/android-sdk-license 

RUN sdkmanager --update 
RUN sdkmanager  "platforms;android-25" "build-tools;25.0.2"  "ndk-bundle"

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/

# Install Compile Cache
ENV USE_CCACHE=1
ENV NDK_CCACHE=/usr/bin/ccache
ENV CCACHE_DIR=/opt/roscpp_output/ccache
ENV PATH /usr/lib/ccache:$PATH
