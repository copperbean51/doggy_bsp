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

source  ~/doggy-release

############################################
# wait until unattended-upgrade has finished
############################################
tmp=$(ps aux | grep unattended-upgrade | grep -v unattended-upgrade-shutdown | grep python | wc -l)
[ $tmp == "0" ] || echo "waiting for unattended-upgrade to finish"
while [ $tmp != "0" ];do
sleep 10;
echo -n "."
tmp=$(ps aux | grep unattended-upgrade | grep -v unattended-upgrade-shutdown | grep python | wc -l)
done

### Give a meaningfull hostname
grep -q "doggy" /etc/hostname || echo "doggy" | sudo tee /etc/hostname
grep -q "doggy" /etc/hosts || echo "127.0.0.1	doggy" | sudo tee -a /etc/hosts

### Install system components
$BASEDIR/prepare_dkms.sh
COMPONENTS=(IO_Configuration System PWMController)

for dir in ${COMPONENTS[@]}; do
    cd $BASEDIR/$dir
    ./install.sh
done


### Install Python module
PYTHONMODLE=Python_Module

if [ "$IS_RELEASE" == "YES" ]
then
    sudo PBR_VERSION=$(cd $BASEDIR; ./get-version.sh) pip install $BASEDIR/$PYTHONMODLE
else
    sudo pip install $BASEDIR/$PYTHONMODLE
fi

sudo sed -i "s|BASEDIR|$BASEDIR|" /etc/rc.local

### Make pwm sysfs work for non-root users
getent group gpio || sudo groupadd gpio && sudo gpasswd -a $(whoami) gpio
getent group dialout || sudo groupadd dialout && sudo gpasswd -a $(whoami) dialout

sudo tee /etc/udev/rules.d/99-doggy-pwm.rules << EOF > /dev/null
KERNEL=="pwmchip0", SUBSYSTEM=="pwm", RUN+="/usr/lib/udev/pwm-doggy.sh"
EOF


sudo tee /etc/udev/rules.d/99-doggy-nvmem.rules << EOF > /dev/null
KERNEL=="3-00500", SUBSYSTEM=="nvmem", RUN+="/bin/chmod 666 /sys/bus/nvmem/devices/3-00500/nvmem"
KERNEL=="3-00501", SUBSYSTEM=="nvmem", RUN+="/bin/chmod 666 /sys/bus/nvmem/devices/3-00501/nvmem"
EOF

sudo tee /usr/lib/udev/pwm-doggy.sh << "EOF" > /dev/null
#!/bin/bash
for i in $(seq 0 15); do
    echo $i > /sys/class/pwm/pwmchip0/export
    echo 4000000 > /sys/class/pwm/pwmchip0/pwm$i/period
    chmod 666 /sys/class/pwm/pwmchip0/pwm$i/duty_cycle
    chmod 666 /sys/class/pwm/pwmchip0/pwm$i/enable
done
EOF

sudo chmod +x /usr/lib/udev/pwm-doggy.sh


sudo udevadm control --reload-rules && sudo udevadm trigger

