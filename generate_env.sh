#!/bin/bash

setup_dependencies_version(){
    # Update this script using 
    # https://www.tensorflow.org/install/source#cpu
    case $BRANCH_NAME in
        "1.0" | "1.1")
            GCC_VER="4.8"
            BAZEL_VER="0.4.2"
        ;;
        
        "1.2" | "1.3")
            GCC_VER="4.8"
            BAZEL_VER="0.4.5"
        ;;
        
        "1.4")
            GCC_VER="4.8"
            BAZEL_VER="0.5.4"
        ;;
        
        "1.5")
            GCC_VER="4.8"
            BAZEL_VER="0.8.0"
        ;;
        
        "1.6" | "1.7")
            GCC_VER="4.8"
            BAZEL_VER="0.9.0"
        ;;
        
        "1.8")
            GCC_VER="4.8"
            BAZEL_VER="0.10.0"
        ;;
        
        "1.9")
            GCC_VER="4.8"
            BAZEL_VER="0.11.0"
        ;;
        
        "1.10" | "1.11" | "1.12")
            GCC_VER="4.8"
            BAZEL_VER="0.15.0"
        ;;
        
        "1.13")
            GCC_VER="4.8"
            BAZEL_VER="0.19.2"
        ;;
        
        "1.14")
            GCC_VER="4.8"
            BAZEL_VER="0.24.1"
        ;;
        
        "2.0")
            GCC_VER="7.3.1"
            BAZEL_VER="0.26.1"
        ;;
        
        "2.1")
            GCC_VER="7.3.1"
            BAZEL_VER="0.27.1"
        ;;

        "2.2" | "2.3" | "2.4" )
            GCC_VER="7.3.1"
            BAZEL_VER="3.1.0"
        ;;

        "2.5" | "2.6" )
            GCC_VER="7.3.1"
            BAZEL_VER="3.7.2"
        ;;

        "master" )
            GCC_VER="7.3.1"
            BAZEL_VER="3.7.2"
        ;;

    esac

    # https://www.tensorflow.org/install/source#gpu
    case $BRANCH_NAME in
        "1.0" | "1.1" | "1.2" )
            cuDNN_VER="5.1"
            CUDA_VER="8.0"
        ;;
        
        "1.3" | "1.4")
            cuDNN_VER="6"
            CUDA_VER="8"
        ;;
        
        "1.5"| "1.6"| "1.7"| "1.8"| "1.9"| "1.10"| "1.11"| "1.12" )
            cuDNN_VER="7"
            CUDA_VER="9.1"
        ;;
        
        "1.13"| "1.14"| "2.0" )
            cuDNN_VER="7.4"
            CUDA_VER="10.0"
        ;;
        
        "2.1" )
            cuDNN_VER="7.6"
            CUDA_VER="10.1"
        ;;

        "2.2" | "2.3" )
            cuDNN_VER="7.6"
            CUDA_VER="10.1"
        ;;

        "2.4" )
            cuDNN_VER="7.6"
            CUDA_VER="10.1"
        ;;

        "2.5" | "2.6" )
            cuDNN_VER="8.1"
            CUDA_VER="11.2"
        ;;

        "master" )
            cuDNN_VER="8.1"
            CUDA_VER="11.2"
        ;;
    esac

    cuDNN_VER_SHORT=$(echo "$cuDNN_VER" | egrep -o '^[0-9]{1,2}')
    echo "cuDNN_VER = $cuDNN_VER; CUDA_VER = $CUDA_VER"
    echo "GCC_VER = $GCC_VER; BAZEL_VER = $BAZEL_VER"
    GCC_VER_SHORT="$(echo $GCC_VER | egrep -o '^[0-9]+\.[0-9]+').0"
}

#============================
# Main
#============================

echo "Please refer to the following document for information:"
echo "https://www.tensorflow.org/install/source#linux"

echo "Tensorflow version ?"
read TF_VER

if [ "$TF_VER" = "latest" ]; then 
    BRANCH_NAME="master";
else
    BRANCH_NAME=$(echo "$TF_VER" | egrep -o '^[12]\.[0-9]{1,2}')
fi

setup_dependencies_version

echo $(($(nproc)*2))

echo "Python version ?"
read PYTHON_VER

echo "#!/usr/bin/env bash" > .env
echo "TF_VER=$TF_VER" >> .env
echo "BRANCH_NAME=$BRANCH_NAME" >> .env
echo "PYTHON_VER=$PYTHON_VER" >> .env
echo "GCC_VER=$GCC_VER" >> .env
echo "GCC_VER_SHORT=$GCC_VER_SHORT" >> .env
echo "BAZEL_VER=$BAZEL_VER" >> .env
echo "cuDNN_VER=$cuDNN_VER" >> .env
echo "cuDNN_VER_SHORT=$cuDNN_VER_SHORT" >> .env

