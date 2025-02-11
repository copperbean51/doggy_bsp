#!/bin/bash

set -e

### Get directory where this script is installed
BASEDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

sudo apt-get install -y dkms

cd $BASEDIR/PWMController
sudo mkdir -p /usr/src/pwm_pca9685-1.0
sudo cp Makefile /usr/src/pwm_pca9685-1.0
sudo cp pwm_pca9685.c /usr/src/pwm_pca9685-1.0/
sudo cp dkms.conf /usr/src/pwm_pca9685-1.0/

# sudo apt install linux-headers-6.8.0-1018-raspi
# apt search linux-headers | grep 6.8.0

sudo dkms add -m pwm_pca9685 -v 1.0
sudo dkms build -m pwm_pca9685 -v 1.0
# cat /var/lib/dkms/pwm_pca9685/1.0/build/make.log
sudo dkms install -m pwm_pca9685 -v 1.0
