ARG BASE_IMAGE=adoptopenjdk:8-jre-hotspot-bionic
FROM ${BASE_IMAGE}

# system update & package install
RUN apt-get clean && \
    apt-get -y update && \
    apt-get install -y --no-install-recommends \
    unzip bzip2 \
    openssl libssl-dev \
    curl wget \
    ca-certificates \
    fontconfig \
    locales \
    bash \
    sudo \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
    # build-essential \
# todo: selection package


# SPARK
# https://qiita.com/hrkt/items/fe9b1162f7a08a07e812
ARG SPARK_VERSION=3.0.0
ARG HADOOP_VERSION=3.2
RUN curl -O http://apache.mirror.iphh.net/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz \
    && tar xzf spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz \
    && mv spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} /usr/local/spark \
    && rm spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz


# TINI
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
RUN chmod +x /usr/bin/tini


# user
# ref:
# https://zukucode.com/2019/06/docker-user.html
# https://qiita.com/Riliumph/items/3b09e0804d7a04dff85b
ARG USER_NAME=user
ARG USER_UID=1000
ARG PASSWD=password

RUN useradd -m -s /bin/bash -u ${USER_UID} ${USER_NAME} && \
    gpasswd -a ${USER_NAME} sudo && \
    echo "${USER_NAME}:${PASSWD}" | chpasswd && \
    echo "${USER_NAME} ALL=(ALL) ALL" >> /etc/sudoers && \
    chmod g+w /etc/passwd

# conda
ENV CONDA_DIR=/opt/conda \
    CONDA_BASE_DIR=/opt/conda_base \
    HOME=/home/$USER_NAME \
    SHELL=/bin/bash
RUN mkdir -p $CONDA_DIR && \
    mkdir -p $CONDA_BASE_DIR && \
    chown $USER_NAME:$USER_UID $CONDA_DIR && \
    chown $USER_NAME:$USER_UID $CONDA_BASE_DIR
# conda package-info
COPY ./conda_packages.yml /tmp/conda_packages.yml


# ubuntu color-prompt
RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc


USER ${USER_UID}

WORKDIR $HOME
ARG PYTHON_VERSION=default
# miniconda
# ARG MINICONDA_VERSION=py38_4.8.3-Linux-x86_64
# ARG MINICONDA_MD5=d63adf39f2c220950a063e0529d4ff74
ARG MINICONDA_VERSION=py37_4.8.3-Linux-x86_64
ARG MINICONDA_MD5=751786b92c00b1aeae3f017b781018df
ENV PATH=${CONDA_DIR}/bin:$PATH

RUN cd /tmp && \
    wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-${MINICONDA_VERSION}.sh && \
    echo "${MINICONDA_MD5} *Miniconda3-${MINICONDA_VERSION}.sh" | md5sum -c - && \
    /bin/bash Miniconda3-${MINICONDA_VERSION}.sh -f -b -p $CONDA_BASE_DIR && \
    rm Miniconda3-${MINICONDA_VERSION}.sh && \
    $CONDA_BASE_DIR/bin/conda env create -f /tmp/conda_packages.yml --prefix $CONDA_DIR && \
    rm -rf $HOME/.cache/* && \
    rm -rf $CONDA_BASE_DIR/*


# Configration

# java
ENV JAVA_HOME=/opt/java/openjdk \
    PATH="/opt/java/openjdk/bin:$PATH"

# pyspark
ARG PY4J_VER=0.10.9
ENV SPARK_HOME=/usr/local/spark
ENV PYTHONPATH=${SPARK_HOME}/python:${SPARK_HOME}/python/lib/py4j-${PY4J_VER}-src.zip \
    SPARK_OPTS="--driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info" \
    PATH=$PATH:${SPARK_HOME}/bin \
    PYSPARK_PYTHON=${CONDA_DIR}/bin/python \
    PYSPARK_DRIVER=${CONDA_DIR}/bin/python

# add jar
RUN $SPARK_HOME/bin/spark-shell --packages graphframes:graphframes:0.8.0-spark3.0-s_2.12

# FONT
RUN mkdir ~/.fonts \
    && chown ${USER_NAME} ~/.fonts \
    && chmod 755 ~/.fonts \
    && wget https://ipafont.ipa.go.jp/IPAexfont/ipaexg00401.zip \
    && unzip ipaexg00401.zip \
    && mv ipaexg00401 -t ~/.fonts/ \
    && rm ipaexg00401.zip \
    && rm -rf ~/.cache/* \
    && fc-cache -fv

RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager && \
    jupyter labextension install jupyter-matplotlib && \
    jupyter labextension install @lckr/jupyterlab_variableinspector && \
    jupyter labextension install @jupyterlab/toc && \
    jupyter labextension install jupyterlab_vim && \
    jupyter labextension install @krassowski/jupyterlab-lsp@0.8.0 && \
    rm -rf ~/.cache/yarn/*
# RUN jupyter labextension install @krassowski/jupyterlab-lsp     # for JupyterLab 2.x

EXPOSE 8888


ENTRYPOINT [ "/usr/bin/tini", "--" ]

CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--NotebookApp.token=''"]
