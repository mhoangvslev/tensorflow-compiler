#!/bin/bash
python configure.py \
&& bazel build --config=opt //tensorflow/tools/pip_package:build_pip_package \
&& ./bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg 