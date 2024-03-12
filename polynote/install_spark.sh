#!/bin/bash
# This script is intended for use from the docker builds.

set -e

echo ${SCALA_VERSION:?}
echo ${SPARK_VERSION:?}
echo ${HADOOP_VERSION:?}
SPARK_VERSION_DIR="spark-${SPARK_VERSION}"
if [ "$SCALA_VERSION" == "2.13" ]; then SCALA_POSTFIX="-scala2.13"; fi
SPARK_NAME="spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}${SCALA_POSTFIX}"

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
