FROM ubuntu:18.04

ARG PYTHON_VER
ENV PYTHON_VER=${PYTHON_VER}

# Miniconda
ENV PATH="/root/miniconda3/bin:${PATH}"
ARG PATH="/root/miniconda3/bin:${PATH}"

RUN apt-get update
RUN apt-get install -y wget curl git build-essential unzip autoconf automake gettext gperf autogen guile-2.2 flex libz-dev

# Miniconda
RUN wget \
    https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && mkdir /root/.conda \
    && bash Miniconda3-latest-Linux-x86_64.sh -b \
    && rm -f Miniconda3-latest-Linux-x86_64.sh 

RUN conda create -n xp
SHELL ["conda", "run", "--no-capture-output", "-n", "xp", "/bin/bash", "-c"]
RUN echo "Python ${PYTHON_VER}" && conda install "python=${PYTHON_VER}"
RUN pip install pip numpy wheel 
RUN pip install keras_preprocessing --no-deps

# GCC
ARG GCC_VER
ENV GCC_VER=${GCC_VER}

ARG GCC_VER_SHORT
ENV GCC_VER_SHORT=${GCC_VER_SHORT}

RUN wget "https://github.com/gcc-mirror/gcc/archive/refs/tags/releases/gcc-${GCC_VER}.tar.gz" \
     -O "gcc-${GCC_VER}.tar.gz" \
    || wget "https://github.com/gcc-mirror/gcc/archive/refs/tags/releases/gcc-${GCC_VER_SHORT}.tar.gz" \
     -O "gcc-${GCC_VER}.tar.gz" \
    && tar -xvf "gcc-${GCC_VER}.tar.gz" --strip-components=1 --one-top-level=/root/gcc-${GCC_VER}

WORKDIR /root/gcc-${GCC_VER}

ENV CC=gcc
ENV CXX=g++
ENV OPT_FLAGS="-O2"
ENV CC="$CC" 
ENV CXX="$CXX" 
ENV CFLAGS="$OPT_FLAGS" 

RUN apt install 

RUN sed -i "s|ftp://gcc.gnu.org/pub/gcc/infrastructure/|https://gcc.gnu.org/pub/gcc/infrastructure/|g" ./contrib/download_prerequisites \
    && ./contrib/download_prerequisites --force

RUN CXXFLAGS="${OPT_FLAGS} -Wall" ./configure \
    --enable-bootstrap \
    --enable-shared \
    --enable-threads=posix \
    --enable-checking=release \
    --with-system-zlib \
    --enable-__cxa_atexit \
    --disable-libunwind-exceptions \
    --enable-linker-build-id \
    --enable-languages=c,c++,lto \
    --disable-vtable-verify \
    --with-default-libstdcxx-abi=new \
    --enable-libstdcxx-debug  \
    --without-included-gettext  \
    --enable-plugin \
    --disable-initfini-array \
    --disable-libgcj \
    --enable-plugin  \
    --disable-multilib \
    --with-tune=generic

RUN make -j $(($(nproc)*2)) BOOT_CFLAGS="$OPT_FLAGS" bootstrap
RUN make install-strip

ENV PATH="$(realpath ./bin/):${PATH}"
ENV LD_LIBRARY_PATH="$(realpath lib):lib64:${LD_LIBRARY_PATH}"
ENV MANPATH="$(realpath share/man):${MANPATH}"
ENV INFOPATH="$(realpath share/info):${INFOPATH}"

RUN gcc --version

# CUDA
ARG CUDA_DL_HTTP
ENV CUDA_DL_HTTP=${CUDA_DL_HTTP}

ARG CUDA_VER
ENV CUDA_VER=${CUDA_VER}

WORKDIR /root/
ENV CUDA_HTTP="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64"
RUN wget ${CUDA_HTTP}/cuda-ubuntu1804.pin \
    && mv cuda-ubuntu1804.pin /etc/apt/preferences.d/cuda-repository-pin-600 \
    && wget ${CUDA_DL_HTTP} -O cuda.deb \
    && sudo dpkg -i cuda.deb \
    && sudo apt-key add /var/cuda-repo-ubuntu1804-11-2-local/7fa2af80.pub \
    && apt update && apt install -y cuda

# Tensorflow
ARG TF_VER
ENV TF_VER=${TF_VER}

ARG BRANCH_NAME
ENV BRANCH_NAME=${BRANCH_NAME}

ARG cuDNN_VER
ENV cuDNN_VER=${cuDNN_VER}

ARG cuDNN_VER_SHORT
ENV cuDNN_VER_SHORT=${cuDNN_VER_SHORT}

WORKDIR /root/
RUN git clone https://github.com/tensorflow/tensorflow.git -b "r${BRANCH_NAME}"

WORKDIR /root/tensorflow/
VOLUME ["/tmp/tensorflow_pkg"]

## Bazel
ARG BAZEL_VER
ENV BAZEL_VER=${BAZEL_VER}

# RUN echo "Installing Bazel for Linux" \
#     && wget "https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VER}/bazel-${BAZEL_VER}-installer-linux-x86_64.sh" \
#         -O "bazel-${BAZEL_VER}-installer-linux-x86_64.sh" \
#     && bash ./"bazel-${BAZEL_VER}-installer-linux-x86_64.sh" \
#     && rm "bazel-${BAZEL_VER}-installer-linux-x86_64.sh" \
#     && bazel version

# Bazel
RUN wget https://github.com/bazelbuild/bazelisk/releases/download/v1.10.1/bazelisk-linux-amd64 \
    -O /usr/local/bin/bazel \
    && chmod +x /usr/local/bin/bazel \
    && echo ${BAZEL_VER} > .bazelversion \
    && bazel version 

COPY build.sh .
RUN chmod +x build.sh