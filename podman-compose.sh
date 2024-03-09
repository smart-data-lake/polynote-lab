#!/bin/bash

# This script executes the commands that podman-compose should have been able to execute.
# Unfortunately, due to the issue https://github.com/containers/podman-compose/issues/379#issuecomment-1000328181
# the different containers that are set up by the newer versions of podman-compose cannot communicate with each other,
# at least not without complicating the setup considerably, so we decided to not use podman-compose anymore.

# Run this script from the base directory of the repository

#podman build -f metastore/Dockerfile -t metastore
podman build -v ~/.m2/repository:/mnt/.mvnrepo -f polynote/Dockerfile -t polynote-lab

# creating a network (default network is missing dns support)
podman network ls | grep polynote-lab
if [ $? -ne 0 ]; then
  echo "creating network polynote-lab"
  podman network create polynote-lab
  if [ $? -ne 0 ]; then exit -1; fi
else
  echo "network polynote-lab already exists"
fi

#metastore
podman ps | grep metastore
if [ $? -ne 0 ]; then
  echo "starting metastore in background"
  mkdir -p data/_metastore
  podman run --rm --replace -dt -p 1527:1527 --net polynote-lab --name=metastore -e DB_DIR=/mnt/database -v ${PWD}/data/_metastore:/mnt/database metastore 
  if [ $? -ne 0 ]; then exit -1; fi
else
  echo "metastore already running"
fi
echo .

#s3
podman ps | grep s3
if [ $? -ne 0 ]; then
  echo "starting storage service in background"
  # latest minio is not used here, as files on disk have a proprietary layout now. S3proxy just serves a directory, which is more transparent and easier put files.
  #podman run --rm -dt -p 9000:9000 -p 9001:9001 --name=part2_s3 -v ${PWD}/data:/mnt/data quay.io/minio/minio server /mnt/data --console-address ":9001"
  podman run --rm --replace -dt -p 9000:9000 --net polynote-lab --name=s3 -v ${PWD}/data:/mnt/data -e S3PROXY_ENDPOINT="http://0.0.0.0:9000" -e JCLOUDS_FILESYSTEM_BASEDIR="/mnt" -e S3PROXY_AUTHORIZATION=none andrewgaul/s3proxy
  if [ $? -ne 0 ]; then exit -1; fi
else
  echo "storage service already running"
fi
echo .

#polynote
echo "starting polynote"
podman run --rm --replace -p 8192:8192 -p "4140-4199:4140-4199" --net polynote-lab --name=polynote -v ${PWD}/polynote/config.yml:/opt/polynote/config.yml -v ${PWD}/polynote/notebooks:/mnt/notebooks -v ${PWD}/data:/mnt/data -v ${PWD}/lib:/mnt/lib -v ${PWD}/config:/mnt/config polynote-lab --config /opt/polynote/config.yml
if [ $? -ne 0 ]; then exit -1; fi


#cleanup if polynote is stopped
#podman stop s3
#podman stop metastore

