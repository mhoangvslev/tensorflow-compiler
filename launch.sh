#!/bin/bash

syntax_error(){
    echo "sh launch sh build|start gpu|cpu"
}

if [ $# -ne 2 ]; then
    syntax_error;
fi

if [ "$1" = "build" ]; then
    docker-compose build tensorflow-compiler-$2;
elif [ "$1" = start ]; then
    mkdir -p tensorflow;
    if [ "$2" = "gpu" ];  then
        docker run -it --rm \
            --gpus all \
            --device /dev/nvidia0 --device /dev/nvidia-modeset \
            --device /dev/nvidia-uvm --device /dev/nvidia-uvm-tools \
            --device /dev/nvidiactl --network host \
            -v "$(realpath ./tensorflow):/tmp/tensorflow-pkg" \
            tensorflow-compiler_tensorflow-compiler-gpu;
    elif [ "$2" = "cpu" ]; then
        docker run -it --rm \
            -v "$(realpath ./tensorflow):/tmp/tensorflow-pkg" \
            tensorflow-compiler_tensorflow-compiler-cpu;
    else
        syntax_error;
    fi
else
    syntax_error;
fi