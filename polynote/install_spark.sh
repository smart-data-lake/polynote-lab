#!/bin/bash
# This script is intended for use from the docker builds.

set -e

echo ScalaVersion=${SCALA_VERSION:?}
echo SparkVersion=${SPARK_VERSION:?}
SPARK_VERSION_DIR="spark-${SPARK_VERSION}"
if [ "$SCALA_VERSION" == "2.13" ]; then SCALA_POSTFIX="-scala2.13"; fi
SPARK_NAME="spark-${SPARK_VERSION}-bin-hadoop3${SCALA_POSTFIX}"

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

# install python dependencies
# see also https://github.com/apache/spark/blob/master/dev/infra/Dockerfile, https://github.com/polynote/polynote/blob/master/requirements.txt
pip3 install --no-cache-dir numpy pyarrow 'pandas<=1.5.3' scipy 'memory-profiler==0.60.0' 'scikit-learn==1.1.*' 'jep==4.1.1' virtualenv ipython nbconvert 'jedi>=0.18.1' matplotlib
