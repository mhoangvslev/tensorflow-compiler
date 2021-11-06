# tensorflow-compiler
Script to setup and compile tensorflow from scratch

# Motivation
Compiling Tensorflow from source help accelerate training time. However, it's not an easy task. 
Users usually face 4 majors problems:
- Packages are not available on their current version of Ubuntu
- Messy, inflated storage after installing build tools
- Official Docker devel images do not support every version of Tensorflow
- The compilation procedure is lengthy and you have to it once for every hardware config 

# Usage

0. Install and setup NVIDIA Container Toolkit

If you intend to compile Tensorflow with NVIDIA GPU, you will need [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#installing-on-ubuntu-and-debian) to pass your GPUs to Docker container.

If you encounter error `cgroup subsystem devices not found: unknown.`, refer to the workaround [here](https://github.com/NVIDIA/nvidia-docker/issues/1447#issuecomment-757034464).

1. Generate `.env` file for `docker-compose`.
```bash
sh generate_env.sh
```

2. Launch the docker-compose
```bash
docker-compose build [--no-cache] tensorflow-compiler-<gpu|cpu>
docker-compose run -it --rm [--gpus all] \
    --device /dev/nvidia0 --device /dev/nvidia-modeset  --device /dev/nvidia-uvm --device /dev/nvidia-uvm-tools --device /dev/nvidiactl \
    --network host \
    -v "$(realpath ./tensorflow):/tmp/tensorflow_pkg" \
    tensorflow-compiler-<gpu|cpu> 

# When inside the docker container, run:
sh build.sh

# Or do whatever you want 
```

A convenient script `launch.sh` is also available at your disposal:
```bash
sh launch sh build|start gpu|cpu
```

3. Retrieve compiled `.whl` file at host's `tensorflow` directory:
```bash
# In a new terminal
cd  tensorflow-compiler/
cp tensorflow/tensorflow_<tf_ver>.py<py_ver>.whl path/to/permanant/storage/
pip install path/to/permanant/storage/tensorflow_<tf_ver>.py<py_ver>.whl
```

# Contribution
- While the Dockerfiles are stable, the environment variable generator needs constant synchronisation with [Tensorflow's official tested build configuration](https://www.tensorflow.org/install/source?hl=lt#tested_build_configurations). 
- Report issues and suggestions to Issue section.
