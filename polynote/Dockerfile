# This image contains
# - polynote notebook
# - a spark distribution (because polynote needs more than spark java artifacts)
# - SDL libraries (to use SDL in notebooks)

ARG POLYNOTE_VERSION=0.5.1
# check available versions at https://spark.apache.org/downloads.html
# note that Polynote has a problem with Scala 2.12 version > 2.12.12 and Java 17 (NoClassDefFoundError: scala/tools/nsc/reporters/AbstractReporter)
ARG SCALA_VERSION="2.13"
ARG SPARK_VERSION="3.4"
ARG HADOOP_VERSION="3"
# derby version used by this spark version - we need to load additional derbyclient jar to connect to remote metastore
ARG DERBY_VERSION="10.14.2.0"


#
# Build sdl-lib stage
#
FROM maven:3.9.6-eclipse-temurin-17 AS build
ARG SCALA_VERSION

COPY sdl-lib-pom.xml /home/app/
RUN mvn -f /home/app/sdl-lib-pom.xml "-Dmaven.repo.local=/mnt/.mvnrepo" "-Pscala-$SCALA_VERSION" -Pcopy-libs-with-spark package


#
# Package stage
#
FROM eclipse-temurin:17
ARG POLYNOTE_VERSION
ARG SCALA_VERSION
ARG SPARK_VERSION
ARG HADOOP_VERSION
ARG DERBY_VERSION
ARG DIST_TAR="polynote-dist.tar.gz"

USER root

#install python
RUN apt-get update -y && apt-get install -y procps wget python3 python3-dev python3-pip build-essential wget

WORKDIR /opt


# install polynote
RUN wget -q -O - https://github.com/polynote/polynote/releases/download/$POLYNOTE_VERSION/$DIST_TAR | tar xvz && rm -rf /opt/polynote/deps/2.11
RUN sed -i s/1.2.5/1.5.3/ ./polynote/requirements.txt && pip3 install -r ./polynote/requirements.txt

# get latest Spark version for selected minor version
RUN wget -q -O - https://dlcdn.apache.org/spark/ | grep -o 'href=".*">' | sed 's/href="//;s/\/">//' | grep "spark-"$SPARK_VERSION | sed 's/spark-//' > /opt/spark.version
RUN bash -l -c 'echo export SCALA_VERSION="$(cat /opt/spark.version)" >> /etc/bash.bashrc'


# install spark distribution (polynote needs spark-submit command)
COPY install_spark.sh .
# convert line-endings to unix format and start script to install spark
RUN sed -i 's/\r$//' install_spark.sh && chmod +x install_spark.sh && SPARK_VERSION=$(cat /opt/spark.version) ./install_spark.sh
ENV SPARK_HOME="/opt/spark"
ENV PATH="$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin"

# copy sdl libraries with spark.
# Copying with spark allows us to control all dependency versions through sdl-lib-pom.xml
RUN mv $SPARK_HOME/jars/ $SPARK_HOME/jarsOrg/
COPY --from=build /home/app/target/lib/*.jar $SPARK_HOME/jars/


# to wrap up, we create (safe)user
ENV UID 1000
ENV NB_USER polly

RUN adduser --disabled-password \
    --gecos "Default user" \
    --uid ${UID} \
    ${NB_USER}

# allow user access to the WORKDIR
RUN chown -R ${NB_USER}:${NB_USER} /opt/

#RUN chmod 777 $SPARK_HOME/jars/

# switch to non-root user
USER ${NB_USER}

# expose the (internal) port that polynote runs on
EXPOSE 8192

# use the same scala version for server
ENV POLYNOTE_SCALA_VERSION ${SCALA_VERSION}

# start polynote on container run
ENTRYPOINT ["/opt/polynote/polynote.py"]
