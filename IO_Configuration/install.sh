#!/bin/bash

if [ $(lsb_release -cs) == "noble" ]; then
    sudo cp ubuntu_24.04/config.txt /boot/firmware/ -f
else
    sudo cp ubuntu_22.04/syscfg.txt /boot/firmware/ -f
fi

