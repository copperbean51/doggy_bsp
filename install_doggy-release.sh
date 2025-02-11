#!/bin/bash

set -e

### Get directory where this script is installed
BASEDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

### Write release file
echo BUILD_DATE=\"$(date)\" > ~/doggy-release
echo HARDWARE=\"$(python3 $BASEDIR/Python_Module/DoggyFun/doggy/capabilities.py)\" >> ~/doggy-release
echo MACHINE=\"$(uname -m)\" >> ~/doggy-release

if [ -f /boot/firmware/user-data ]
then
    echo CLOUD_INIT_CLONE=\"$(grep clone /boot/firmware/user-data | awk -F'"' '{print $2}')\" >> ~/doggy-release
    echo CLOUD_INIT_SCRIPT=\"$(grep setup_out /boot/firmware/user-data | awk -F'"' '{print $2}')\" >> ~/doggy-release
else
    echo BUILD_SCRIPT=\"$(cd ~; ls *build.sh)\" >> ~/doggy-release
fi
echo BSP_VERSION=\"$(cd ~/doggy_bsp; ./get-version.sh)\" >> ~/doggy-release

cd ~/doggy_bsp

TAG_COMMIT=$(git rev-list --abbrev-commit --tags --max-count=1) # 3ae72e8

TAG=$(git describe --abbrev=0 --tags ${TAG_COMMIT} 2>/dev/null || true) # v1.0.2
BSP_VERSION=$(./get-version.sh)   # 1.0.2-next-8f77b6b-20241130-dirt
if [ "v$BSP_VERSION" == "$TAG" ]  # v1.0.2-next-8f77b6b-20241130-dirt = v1.0.2
then
    echo IS_RELEASE=YES >> ~/doggy-release
else
    echo IS_RELEASE=NO >> ~/doggy-release
fi

# source  ~/doggy-release
