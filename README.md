# tensorflow-compiler
Script to setup and compile tensorflow from scratch

# Motivation
Compiling Tensorflow from source help accelerate training time. However, it's not an easy task. 
Users usually face 3 majors problems:
- Packages are not available on their current version of Ubuntu
- Messy, inflated storage after installing build tools
- Official Docker devel images do not support every version of Tensorflow
- The compilation procedure is lengthy and you have to it once for every hardware config 

# Usage

1. Generate `.env` file for `docker-compose`.
```bash
sh generate_env.sh
```

2. Launch the docker-compose
```bash

docker-compose build tensorflow-compiler-<gpu|cpu>
docker-compose run --rm tensorflow-compiler-<gpu|cpu> 

# When inside the docker container, run:
sh build.sh

# Or do whatever you want 
```

# Contribution
- While the Dockerfiles are stable, the environment variable generator needs constant synchronisation with newer version of Tensorflow. 