#!/bin/bash

python configure.py \
&& bazel build \
    --local_ram_resources=HOST_RAM*0.5 \
    --local_cpu_resources=HOST_CPUS-1 \
    --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=0" \
    //tensorflow/tools/pip_package:build_pip_package \
&& ./bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg 