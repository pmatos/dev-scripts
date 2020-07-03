#! /bin/bash
set -euxo pipefail

# Installation directory is the only required argument, which should already exist
INSTALL_DIR=$1
if [ ! -d $INSTALL_DIR ]; then
    echo "installation directory $INSTALL_DIR does not exist"
    exit 1
fi

#
# This script assumes all relevant system dependencies are installed
#
# On debian you need:
# apt-get install -y git gcc cmake wget unzip g++ python libxml2-dev ninja-build python ruby python-pip
#
WORKDIR=$(mktemp -d)
LOGS=$WORKDIR/logs

mkdir $WORKDIR && cd $WORKDIR
mkdir $LOGS
wget https://github.com/Z3Prover/z3/releases/download/z3-4.8.7/z3-4.8.7-x64-ubuntu-16.04.zip 2>&1 | tee $LOGS/z3-download.log
unzip z3-4.8.7-x64-ubuntu-16.04.zip 2>&1 | tee $LOGS/z3-extract.log

mkdir -p $INSTALL_DIR/bin
mkdir -p $INSTALL_DIR/include
mv z3-4.8.7-x64-ubuntu-16.04/bin/* $INSTALL_DIR/bin
mv z3-4.8.7-x64-ubuntu-16.04/include/* $INSTALL_DIR/include

# Make sure z3 is in PATH
export PATH=$INSTALL_DIR/bin:$PATH

if [ -z "$LD_LIBRARY_PATH" ]; then
    LD_LIBRARY_PATH=
fi
export LD_LIBRARY_PATH=$INSTALL_DIR/bin:$LD_LIBRARY_PATH

cd $WORKDIR
git clone --depth=1 -b llvmorg-10.0.0 https://github.com/llvm/llvm-project.git 2>&1 | tee $LOGS/llvm-clone.log
cd llvm-project
wget -O bug41809.patch https://bugs.llvm.org/attachment.cgi?id=22160 | tee $LOGS/llvm-patch-download.log
patch -p1 < bug41809.patch 2>&1 | tee $LOGS/llvm-patching.log
mkdir build && cd build
cmake -G Ninja \
      -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR \
      -DLLVM_ENABLE_Z3_SOLVER=ON \
      -DLLVM_TARGETS_TO_BUILD=X86 \
      -DLLVM_ENABLE_PROJECTS="clang;compiler-rt" \
      -DZ3_INCLUDE_DIR=$INSTALL_DIR/include/ \
      -DCMAKE_BUILD_TYPE=Release \
      -DCOMPILER_RT_BUILD_SANITIZERS=OFF \
      ../llvm/ 2>&1 | tee $LOGS/llvm-configure.log

ninja -v 2>&1 | tee $LOGS/llvm-build.log
ninja install 2>&1 | tee $LOGS/llvm-install.log

# Cleanup
# All installed in $INSTALL_DIR, everything else can go
echo "Please cleanup after yourself by removing $WORKDIR"
