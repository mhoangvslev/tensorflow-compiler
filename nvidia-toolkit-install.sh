#!/bin/bash

distribution=$(. /etc/os-release;echo $ID$VERSION_ID) 

if curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | grep -o "Unsupported distribution!" ; then
    echo "$distribution is not currently supported by nvidia-docker. Please choose the closest platform from https://nvidia.github.io/nvidia-docker/"
    read distribution
fi

curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add - &&
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list &&
sudo apt update && sudo apt-get install -y nvidia-docker2 &&
sudo systemctl restart docker &&

echo "If any error occur, set 'no-cgroups = true' in '/etc/nvidia-container-runtime/config.toml' and re-run this script."

sudo docker run --rm \
    --gpus all \
    --device /dev/nvidia0 --device /dev/nvidia-modeset \
    --device /dev/nvidia-uvm --device /dev/nvidia-uvm-tools \
    --device /dev/nvidiactl --network host \
    nvidia/cuda:11.0-base nvidia-smi
