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
    GCC_VER_SHORT="$(echo $GCC_VER | egrep -o '^[0-9]+\.[0-9]+')"

    # https://www.tensorflow.org/install/source#gpu
    case $BRANCH_NAME in
        "1.0" | "1.1" | "1.2" )
            cuDNN_VER="5.1"
            CUDA_VER="8.0"
        ;;
        
        "1.3" | "1.4")
            cuDNN_VER="6"
            CUDA_VER="8.0"
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

}

#============================
# Main
#============================

echo "Please refer to the following document for information:"
echo "https://www.tensorflow.org/install/source#linux"

TF_VER="None"
until [ $(wget -q https://registry.hub.docker.com/v1/repositories/tensorflow/tensorflow/tags -O - \
    | sed -e 's/[][]//g' -e 's/"//g' -e 's/ //g' \
    | tr '}' '\n' \
    | awk -F: '{print $3}' \
    | grep -x ${TF_VER}) ]
do
    echo "Tensorflow version ?"
    read TF_VER
done

if [ "$TF_VER" = "latest" ]; then 
    BRANCH_NAME="master";
else
    BRANCH_NAME=$(echo "$TF_VER" | egrep -o '^[12]\.[0-9]{1,2}')
fi

setup_dependencies_version

# Check Python version
PYTHON_VER="None"
until [ $(conda search python | awk '{if (NR > 2) {print $2} }' | uniq | grep -x ${PYTHON_VER}) ]
do
    echo "Python version ?"
    read PYTHON_VER
done

# Check Numpy version
NUMPY_VER="None"
until [ $(pip index versions numpy \
        | grep 'Available versions:' \
        | sed 's/Available versions: //' \
        | awk 'gsub(/, /, "\n")' \
        | grep -x ${NUMPY_VER}) ]
do
    echo "Numpy version ?"
    read NUMPY_VER
done

# Check GCC version
if  wget -q https://registry.hub.docker.com/v1/repositories/gcc/tags -O - \
    | sed -e 's/[][]//g' -e 's/"//g' -e 's/ //g' \
    | tr '}' '\n' \
    | awk -F: '{print $3}' \
    | grep ${GCC_VER}
then
    echo "GCC version ${GCC_VER} is available..."
else
    echo "GCC version ${GCC_VER} is not available, setting GCC to ${GCC_VER_SHORT}"
    GCC_VER=$GCC_VER_SHORT
fi

SYSTEM_GCC_VER=$(gcc --version | egrep -o '[0-9]+(\.[0-9]+)+' | head -1)
echo "Override GCC version with system's version ($SYSTEM_GCC_VER)? (y/N)"
read response

if [ "$response" = "y" ]; then 
    GCC_VER=$SYSTEM_GCC_VER 
fi

GCC_VER_SHORT="$(echo $GCC_VER | egrep -o '^[0-9]+\.[0-9]+')"

# Check CUDA
if  wget -q https://registry.hub.docker.com/v1/repositories/nvidia/cuda/tags -O - \
    | sed -e 's/[][]//g' -e 's/"//g' -e 's/ //g' \
    | tr '}' '\n' \
    | awk -F: '{print $3}' \
    | grep "${CUDA_VER}-"
then
    echo "Docker CUDA version ${CUDA_VER} is available..."
else
    CUDA_VER="${CUDA_VER}.0"
    echo "Docker CUDA version ${CUDA_VER} is not available, setting CUDA to ${CUDA_VER}"
fi

if [ $(echo $CUDA_VER | egrep -o '^[0-9]+') -gt 10 ]; then
    CUDA_DOCKER_TAG="$CUDA_VER-cudnn${cuDNN_VER_SHORT}-devel-ubuntu18.04"
else
    CUDA_DOCKER_TAG="$CUDA_VER-cudnn${cuDNN_VER_SHORT}-devel-ubuntu16.04"
fi

# Summary
echo "cuDNN_VER = $cuDNN_VER; CUDA_VER = $CUDA_VER"
echo "GCC_VER = $GCC_VER; BAZEL_VER = $BAZEL_VER"

echo "#!/usr/bin/env bash" > .env
echo "TF_VER=$TF_VER" >> .env
echo "BRANCH_NAME=$BRANCH_NAME" >> .env
echo "PYTHON_VER=$PYTHON_VER" >> .env
echo "NUMPY_VER=$NUMPY_VER" >> .env
echo "GCC_VER=$GCC_VER" >> .env
echo "GCC_VER_SHORT=$GCC_VER_SHORT" >> .env
echo "BAZEL_VER=$BAZEL_VER" >> .env
echo "cuDNN_VER=$cuDNN_VER" >> .env
echo "cuDNN_VER_SHORT=$cuDNN_VER_SHORT" >> .env
echo "CUDA_VER=$CUDA_VER" >> .env
echo "CUDA_DOCKER_TAG=$CUDA_DOCKER_TAG" >> .env
