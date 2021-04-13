#!/bin/bash
# Requirements:
# GCC + Bazel: https://www.tensorflow.org/install/source#cpu
# GCC options: https://gcc.gnu.org/onlinedocs/gcc-4.8.5/gcc/i386-and-x86-64-Options.html#i386-and-x86-64-Options

syntax_error(){
    echo "USAGE: sh unix/setup-tensorflow.sh <TF_VER> <PY_VER>"
    echo "TF_VER: Tensorflow version. See https://hub.docker.com/r/tensorflow/tensorflow/tags?page=1&ordering=last_updated&name=devel-gpu-py"
    echo "PY_VER: Python version: 2 or 3"
    exit 1
}

# Config
if [ $# -lt 2 ]; then
    syntax_error
fi

TF_VER="$1"; shift
if [ "$TF_VER" = "latest" ]; then 
    BRANCH_NAME="master";
else
    BRANCH_NAME=$(echo "$TF_VER" | egrep -o '^[12]\.[0-9]{1,2}')
fi

PY_VER="$1"; shift
( echo "$PY_VER" | grep -Eq '^[23]\.[0-9]$' ) && echo "Python version check: OK" || syntax_error

PYTHON_VERSION_INT=$(echo "$PY_VER" | egrep -o '^[23]')

DOCKER_OPTIONS="$1"
if [ -z "$DOCKER_OPTIONS" ]; then
    DOCKER_OPTIONS="-devel-gpu-py$PYTHON_VERSION_INT"
else
    DOCKER_OPTIONS="-gpu"
fi

DOCKER_IMG_NAME="tensorflow/tensorflow:$TF_VER$DOCKER_OPTIONS"
echo "Tensorflow branch name $BRANCH_NAME"

setup_dependencies_version(){
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

        "2.2" | "2.3" | "2.4" | "master" )
            GCC_VER="7.3.1"
            BAZEL_VER="3.1.0"
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

        "2.4" | "master" )
            cuDNN_VER="8.0"
            CUDA_VER="11.0"
        ;;
    esac

    cuDNN_VER_SHORT=$(echo "$cuDNN_VER" | egrep -o '^[0-9]{1,2}')
    echo "cuDNN_VER = $cuDNN_VER; CUDA_VER = $CUDA_VER"
    echo "GCC_VER = $GCC_VER; BAZEL_VER = $BAZEL_VER"
}

docker_make_build_script() {
    mkdir -p ./docker-tf
    echo "
    GCC_VER=\"$GCC_VER\"
    CUDDNN_VER_SHORT=\"$cuDNN_VER_SHORT\"
    BRANCH_NAME=\"$BRANCH_NAME\"
    BAZEL_VER=\"$BAZEL_VER\"
    " > ./docker-tf/build.sh
        
    echo '
    if [ $BRANCH_NAME != "master" ]; then
        BRANCH_NAME="r$BRANCH_NAME";
    fi

    if [ ! -z "$(apt list | grep "^gcc-$GCC_VER/")" ]; then
        apt install -y "gcc-$GCC_VER"
    else
        GCC_VER_SHORT=$(echo $GCC_VER | sed -r "s/^([0-9]+).*/\\1/g")
        if [ ! -z "$(apt list | grep "$GCC_VER_SHORT")" ]; then
            apt install -y "gcc-$GCC_VER_SHORT"
        else
            echo "GCC is not $GCC_VER, you may encounter some problems"
        fi
    fi

    # Install Bazel
    echo "Installing Bazel for Linux"
    wget -O "bazel-$BAZEL_VER-installer-linux-x86_64.sh" "https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VER/bazel-$BAZEL_VER-installer-linux-x86_64.sh" &&
    bash ./"bazel-$BAZEL_VER-installer-linux-x86_64.sh" &&
    rm "bazel-$BAZEL_VER-installer-linux-x86_64.sh"

    echo "Find and copy libraries files into /usr/local/cuda/lib64"
    find / | grep -m1 "libcudnn.so.$CUDDNN_VER_SHORT" | xargs cp -t /usr/local/cuda/lib64/
    
    # Configure 
    ( (cd /tensorflow/ && git pull) || (cd / && git clone https://github.com/tensorflow/tensorflow.git -b "$BRANCH_NAME" && cd tensorflow/ )) &&
    echo "The following step allow you to customise Tensorflow, please review carefully the configuration process below."
    cd /tensorflow/
    ./configure &&

    echo "Compiling Tensorflow..." && rm -rf ~/.cache/bazel/
    ' >> ./docker-tf/build.sh
    
    echo '
    echo "Building for GPU + CPU"
    bazel build --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=0" --config=opt --config=cuda //tensorflow/tools/pip_package:build_pip_package --verbose_failures
    ' >> ./docker-tf/build.sh
    
    echo './bazel-bin/tensorflow/tools/pip_package/build_pip_package /mnt &&
    py_whl="$(find /mnt -type f \( -iname tensorflow\*.whl \) -print -quit)" &&
    echo "$py_whl" &&
    chown $HOST_PERMS "$py_whl"' >> ./docker-tf/build.sh && chmod +x ./docker-tf/build.sh
}

docker_make_docker_file() {   
    echo "FROM $DOCKER_IMG_NAME" > ./docker-tf/Dockerfile &&
    echo 'WORKDIR /tensorflow_src
    ENV PATH="/root/miniconda3/bin:${PATH}"
    ARG PATH="/root/miniconda3/bin:${PATH}"
    COPY "$PWD/build.sh" .
    VOLUME [ "/mnt" ]

    RUN apt-get update && apt-get install --yes mlocate wget && updatedb
    RUN wget \
    https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && mkdir /root/.conda \
    && bash Miniconda3-latest-Linux-x86_64.sh -b \
    && rm -f Miniconda3-latest-Linux-x86_64.sh 

    SHELL ["conda", "run", "-n", "base", "/bin/bash", "-c"]       
    RUN echo "source activate base" > ~/.bashrc' >> ./docker-tf/Dockerfile &&
    echo "RUN conda install -y python=$PY_VER" >> ./docker-tf/Dockerfile &&

    echo 'RUN pip install --upgrade pip
    RUN pip install six numpy wheel setuptools mock "future>=0.17.1" python-dev-tools
    RUN pip install keras_applications --no-deps  
    RUN pip install keras_preprocessing --no-deps
    
    ENV PATH /opt/conda/envs/base/bin:$PATH' >> ./docker-tf/Dockerfile
}

docker_compile_tensorflow() {
    mkdir -p ~/.tensorflow
    TF_OUT_DIR=$(realpath ~/.tensorflow)
    docker_make_build_script &&
    docker_make_docker_file &&
    echo "Pulling tensorflow image from Docker..." && (docker pull "$DOCKER_IMG_NAME" || exit 1) &&
    echo "Build child image..." && docker image build --network=host -t tensorflow-compiler ./docker-tf &&
    echo "Run image..." && docker run --rm --name tensorflow-compiler -it \
        -w /tensorflow_src \
        -v $TF_OUT_DIR:/mnt \
        -e HOST_PERMS="$(id -u):$(id -g)" \
        -e GCC_VER=$GCC_VER \
        -e CUDDNN_VER_SHORT=$cuDNN_VER_SHORT \
        -e BRANCH_NAME=$BRANCH_NAME \
        -e BAZEL_VER=$BAZEL_VER \
        tensorflow-compiler sh build.sh &&
    
    if [ -z "$(python -c 'import platform; print(platform.python_version())' | grep 3)" ]; then
        py_whl="$(find $TF_OUT_DIR -type f \( -iname tensorflow-$TF_VER\*2\*.whl \) -exec realpath {} \;)" &&
        echo "$py_whl"
    else
        py_whl="$(find $TF_OUT_DIR -type f \( -iname tensorflow-$TF_VER\*3\*.whl \) -exec realpath {} \;)" &&
        echo "$py_whl"
    fi
}

if [ ! -z "$(command -v docker)" ]; then
    echo "Docker detected on your system, it will be used to build tensorflow..." &&
    setup_dependencies_version &&
    ( docker_compile_tensorflow && exit 0 ) ||
    ( echo "[ERROR] Failed to compile tensorflow using Docker." && exit 1 )
else
    syntax_error
fi
