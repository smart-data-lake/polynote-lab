#!/bin/bash

# This scripts build the docker image for metastore and polynote-lab.
# Note that polynote-lab includes SDLB libraries according to polynote/sdl-lib-pom.xml.

# Run this script from the base directory of the repository

set -e
podman build -f metastore/Dockerfile -t metastore
podman build -v ~/.m2/repository:/mnt/.mvnrepo -f polynote/Dockerfile -t polynote-lab
set +e
