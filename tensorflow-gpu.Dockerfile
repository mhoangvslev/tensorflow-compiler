ARG CUDA_DOCKER_TAG
FROM nvidia/cuda:${CUDA_DOCKER_TAG}

ENV http_proxy=${HTTP_PROXY}
ENV https_proxy=${HTTPS_PROXY}
ENV all_proxy=${HTTP_PROXY}

ARG PYTHON_VER
ENV PYTHON_VER=${PYTHON_VER}

ARG NUMPY_VER
ENV NUMPY_VER=${NUMPY_VER}

RUN apt-get update \
    && apt-get install -y wget curl git

# Miniconda
ENV PATH="/root/miniconda3/bin:${PATH}"
ARG PATH="/root/miniconda3/bin:${PATH}"

RUN wget \
    https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && mkdir /root/.conda \
    && bash Miniconda3-latest-Linux-x86_64.sh -b \
    && rm -f Miniconda3-latest-Linux-x86_64.sh 

RUN conda create -n xp
SHELL ["conda", "run", "--no-capture-output", "-n", "xp", "/bin/bash", "-c"]
RUN echo "Python ${PYTHON_VER}" && conda install "python=${PYTHON_VER}"
RUN pip install pip numpy==${NUMPY_VER} wheel \
    && pip install keras_applications --no-deps \
    && pip install keras_preprocessing --no-deps \
    && conda init bash \
    && echo "conda activate xp" >> ~/.bashrc

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
RUN wget https://github.com/tensorflow/tensorflow/archive/v${TF_VER}.tar.gz -O v${TF_VER}.tar.gz \
    && tar xvfz v${TF_VER}.tar.gz

WORKDIR /root/tensorflow-${TF_VER}/
VOLUME ["/tmp/tensorflow_pkg"]

## Bazel
ARG BAZEL_VER
ENV BAZEL_VER=${BAZEL_VER}

# Bazel
RUN wget https://github.com/bazelbuild/bazelisk/releases/download/v1.10.1/bazelisk-linux-amd64 \
    -O /usr/local/bin/bazel \
    && chmod +x /usr/local/bin/bazel \
    && echo ${BAZEL_VER} > .bazelversion \
    && bazel version 

COPY build.sh .
RUN chmod +x build.sh