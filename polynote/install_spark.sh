#!/bin/bash
# This script is intended for use from the docker builds.

set -e -x

SPARK_VERSION=${SPARK_VERSION:-"3.3.2"}
SPARK_VERSION_DIR="spark-${SPARK_VERSION}"

SPARK_NAME="spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}"

pushd /opt
rm -rf spark
wget -q -O - "https://dlcdn.apache.org/spark/${SPARK_VERSION_DIR}/${SPARK_NAME}.tgz" | tar xvz --no-same-owner
mv "${SPARK_NAME}" spark
popd

if test -z "${SPARK_DIST_CLASSPATH}"; then
  echo "Skipping spark env"
else
  echo "export SPARK_DIST_CLASSPATH=\"${SPARK_DIST_CLASSPATH}\"" > /opt/spark/conf/spark-env.sh
fi
