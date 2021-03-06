#! /bin/bash

set -e

# Installation directory is the only required argument, which should already exist
INSTALL_DIR=$1
VERSION=$2
CPUS=$(nproc)

if [ ! -d $INSTALL_DIR ]; then
    echo "installation directory $INSTALL_DIR does not exist"
    exit 1
fi

#
# This script assumes all relevant system dependencies are installed
#
# On debian you need:
# apt-get install -y gcc cmake wget unzip g++ python libxml2-dev ninja-build python ruby python-pip
#
WORKDIR=/tmp/gccsa
LOGS=$WORKDIR/log
BUILD=$WORKDIR/build

mkdir $WORKDIR && cd $WORKDIR
mkdir $LOGS

if [ "$VERSION" = "HEAD" ]; then
    git clone --depth=1 git://gcc.gnu.org/git/gcc.git 2>&1 | tee $LOGS/gcc-clone.log
else
    git clone --depth=1 --branch releases/gcc-$VERSION git://gcc.gnu.org/git/gcc.git 2>&1 | tee $LOGS/gcc-clone.log
fi

mkdir $BUILD && cd $BUILD
../gcc/configure --prefix=$INSTALL_DIR \
		 --enable-languages=c,c++,lto \
		 --disable-docs \
		 --disable-multilib \
		 --disable-nls \
		 --disable-bootstrap 2>&1 | tee $LOGS/gcc-configure.log
make -j$CPUS 2>&1 | tee $LOGS/gcc-build.log
make -j$CPUS install 2>&1 | tee $LOGS/gcc-install.log

# Cleanup
# All installed in $INSTALL_DIR, everything else can go
echo "Please cleanup after yourself by removing $WORKDIR"
