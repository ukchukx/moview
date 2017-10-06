 #!/bin/bash
 cat Dockerfile | envsubst > DockerfileWithEnv
 docker build -t moview -f DockerfileWithEnv .
 rm DockerfileWithEnv

