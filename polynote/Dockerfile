# This image contains
# - polynote notebook
# - a spark distribution (because polynote needs more than spark java artifacts)
# - SDL libraries (to use SDL in notebooks)

ARG POLYNOTE_VERSION=0.6.0
# check available versions at https://spark.apache.org/downloads.html
ARG SCALA_VERSION="2.12"
ARG SPARK_VERSION="3.5"
# derby version used by this spark version - we need to load additional derbyclient jar to connect to remote metastore
ARG DERBY_VERSION="10.14.2.0"
# SDL Version -> check sdl-lib-pom.xml

#
# Build sdl-lib stage
#
FROM maven:3-eclipse-temurin-17 AS build
ARG SCALA_VERSION
COPY sdl-lib-pom.xml /opt/app/
RUN mvn --quiet -f /opt/app/sdl-lib-pom.xml -Pcopy-libs -Pscala-$SCALA_VERSION -Dmaven.repo.local=/mnt/.mvnrepo dependency:copy-dependencies@copy-libs-exec


#
# Package stage
#
FROM eclipse-temurin:17
ARG POLYNOTE_VERSION
ARG SCALA_VERSION
ARG SPARK_VERSION
ARG DERBY_VERSION
ARG DIST_TAR="polynote-dist.tar.gz"

USER root

#install python
RUN apt-get update -y && apt-get install -y procps wget python3 python3-dev python3-pip build-essential

WORKDIR /opt

# create (safe)user
ENV UID 1000
ENV NB_USER polly
RUN adduser --disabled-password --gecos "Default user" --uid ${UID} ${NB_USER} \
    && chown $NB_USER:$NB_USER /opt/

# install polynote
RUN wget -q -O - https://github.com/polynote/polynote/releases/download/$POLYNOTE_VERSION/$DIST_TAR | tar xvz && rm -rf /opt/polynote/deps/2.11
# polynote needs jep 4.1.1, which needs an older version of setuptools avoid error "ModuleNotFoundError: No module named 'setuptools.dep_util'"
RUN pip3 install --upgrade pip setuptools==69.5.1 wheel
RUN sed -i s/1.2.5/1.5.3/ ./polynote/requirements.txt && pip3 install -r ./polynote/requirements.txt
RUN chown -R $NB_USER:$NB_USER ./polynote
# fix polynote.py bug in version 0.6.0
RUN sed -i s/dir\(sys\)/dir\(sys.path\)/ ./polynote/polynote.py

# get latest Spark version for selected minor version
RUN wget -q -O - https://dlcdn.apache.org/spark/ | grep -o 'href=".*">' | sed 's/href="//;s/\/">//' | grep "spark-"$SPARK_VERSION | sed 's/spark-//' > /opt/spark.version
RUN bash -l -c 'echo export SCALA_VERSION="$(cat /opt/spark.version)" >> /etc/bash.bashrc'

# install spark distribution (polynote needs spark-submit command)
COPY install_spark.sh .
RUN chmod +x install_spark.sh && SPARK_VERSION=$(cat /opt/spark.version) ./install_spark.sh && chown -R $NB_USER:$NB_USER /opt/spark
ENV SPARK_HOME="/opt/spark"
ENV PATH="$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin"

# jackson-mapper-asl is vulnerable without alternatives, but not needed in most cases for Spark
RUN rm -f /opt/spark/jars/jackson-mapper-asl-1.9.13.jar

# copy sdl libraries
COPY --from=build --chown=$NB_USER:$NB_USER /opt/app/target/lib/*.jar $SPARK_HOME/jars/

# switch to non-root user
USER $NB_USER

# expose the (internal) port that polynote runs on
EXPOSE 8192

# use the same scala version for server
ENV POLYNOTE_SCALA_VERSION $SCALA_VERSION

# start polynote on container run
ENTRYPOINT ["/opt/polynote/polynote.py"]
