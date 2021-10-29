#!/bin/bash
./configure &&
bazel build --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=0" --jobs=$(($(nproc)*2)) //tensorflow/tools/pip_package:build_pip_package &&
./bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg 