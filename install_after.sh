#!/bin/bash


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

#  export BASEDIR="/home/wl/doggy_bsp"
sudo sed -i "s|BASEDIR|$BASEDIR|" /etc/rc.local


### Make pwm sysfs work for non-root users
getent group gpio || sudo groupadd gpio && sudo gpasswd -a $(whoami) gpio
getent group dialout || sudo groupadd dialout && sudo gpasswd -a $(whoami) dialout

sudo tee /etc/udev/rules.d/99-doggy-pwm.rules << EOF > /dev/null
KERNEL=="pwmchip0", SUBSYSTEM=="pwm", RUN+="/usr/lib/udev/pwm-doggy.sh"
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


# sudo tee /etc/udev/rules.d/99-doggy-nvmem.rules << EOF > /dev/null
# KERNEL=="3-00500", SUBSYSTEM=="nvmem", RUN+="/bin/chmod 666 /sys/bus/nvmem/devices/3-00500/nvmem"
# KERNEL=="3-00501", SUBSYSTEM=="nvmem", RUN+="/bin/chmod 666 /sys/bus/nvmem/devices/3-00501/nvmem"
# EOF


sudo udevadm control --reload-rules && sudo udevadm trigger

