ARG BASE_IMAGE=adoptopenjdk:8u262-b10-jre-openj9-0.21.0-bionic
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
    graphviz \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
    # build-essential \
# todo: selection package


# TINI
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
RUN chmod +x /usr/bin/tini


# user
# ref:
# https://zukucode.com/2019/06/docker-user.html
# https://qiita.com/Riliumph/items/3b09e0804d7a04dff85b
ENV USER_NAME=user \
    USER_UID=1000 \
    PASSWD=password
# If you need, use 'usermod' at last to change them.

RUN useradd -m -s /bin/bash -u ${USER_UID} ${USER_NAME} && \
    gpasswd -a ${USER_NAME} sudo && \
    echo "${USER_NAME}:${PASSWD}" | chpasswd && \
    echo "${USER_NAME} ALL=(ALL) ALL" >> /etc/sudoers && \
    chmod g+w /etc/passwd

# conda
ENV CONDA_DIR=/opt/conda \
    CONDA_TMP_DIR=/tmp/conda \
    HOME=/home/$USER_NAME \
    SHELL=/bin/bash
RUN mkdir -p $CONDA_DIR && \
    mkdir -p $CONDA_TMP_DIR && \
    chown $USER_NAME:$USER_UID $CONDA_DIR && \
    chown $USER_NAME:$USER_UID $CONDA_TMP_DIR
# conda package-info
COPY ./conda_packages.yml /tmp/conda_packages.yml


# ubuntu color-prompt
RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc


USER ${USER_NAME}

WORKDIR $HOME
# miniconda
# ARG MINICONDA_VERSION=py38_4.8.3-Linux-x86_64
# ARG MINICONDA_MD5=d63adf39f2c220950a063e0529d4ff74
ARG MINICONDA_VERSION=py37_4.8.3-Linux-x86_64
ARG MINICONDA_MD5=751786b92c00b1aeae3f017b781018df
ENV PATH=${CONDA_DIR}/bin:$PATH

RUN cd /tmp && \
    wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-${MINICONDA_VERSION}.sh && \
    echo "${MINICONDA_MD5} *Miniconda3-${MINICONDA_VERSION}.sh" | md5sum -c - && \
    /bin/bash Miniconda3-${MINICONDA_VERSION}.sh -f -b -p $CONDA_TMP_DIR && \
    rm Miniconda3-${MINICONDA_VERSION}.sh && \
    $CONDA_TMP_DIR/bin/conda env create -f /tmp/conda_packages.yml --prefix $CONDA_DIR && \
    rm -rf $HOME/.cache/* && \
    rm -rf $CONDA_TMP_DIR/*


RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager && \
    jupyter labextension install jupyter-matplotlib && \
    jupyter labextension install @lckr/jupyterlab_variableinspector && \
    jupyter labextension install @jupyterlab/toc && \
    jupyter labextension install jupyterlab_vim && \
    jupyter labextension install @krassowski/jupyterlab-lsp@0.8.0 && \
    rm -rf ~/.cache/yarn/*
# RUN jupyter labextension install @krassowski/jupyterlab-lsp     # for JupyterLab 2.x

# MATPLOTLIB JAPANESE FONT
ENV MATPLOTLIBRC=$CONDA_DIR/lib/python3.7/site-packages/matplotlib/mpl-data/matplotlibrc
RUN mkdir ~/.fonts \
    && chown ${USER_NAME} ~/.fonts \
    && chmod 755 ~/.fonts \
    && wget https://ipafont.ipa.go.jp/IPAexfont/ipaexg00401.zip \
    && unzip ipaexg00401.zip \
    && mv ipaexg00401 -t ~/.fonts/ \
    && rm ipaexg00401.zip \
    && rm -rf ~/.cache/* \
    && fc-cache -fv \
    && echo "font.sans-serif : IPAexGothic" >> $MATPLOTLIBRC


# APACHE SPARK
USER root
ARG SPARK_VERSION=3.0.0
ARG HADOOP_VERSION=2.7
ENV SPARK_HOME=/usr/local/spark
RUN curl -O http://apache.mirror.iphh.net/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz \
    && tar xzf spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz \
    && mv spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} $SPARK_HOME \
    && rm spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz

# add jar
# RUN echo "spark.jars.packages graphframes:graphframes:0.8.0-spark2.4-s_2.11,org.datasyslab:geospark:1.3.1,org.datasyslab:geospark-sql_2.3:1.3.1,org.datasyslab:geospark-viz_2.3:1.3.1" >> $SPARK_HOME/conf/spark-defaults.conf && \
#     chmod +r $SPARK_HOME/conf/spark-defaults.conf

# add jupyter-lsp config
COPY ./pycodestyle /home/$USER_NAME/.config/pycodestyle

# Configration
USER ${USER_NAME}
WORKDIR $HOME

# pyspark
ARG PY4J_VER=0.10.9
# ENV SPARK_HOME=/usr/local/spark
ENV SPARK_OPTS="--driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info" \
    JAVA_HOME=/opt/java/openjdk \
    PATH=${SPARK_HOME}/bin:/opt/java/openjdk/bin:$PATH \
    PYTHONPATH=${SPARK_HOME}/python:${SPARK_HOME}/python/lib/py4j-${PY4J_VER}-src.zip \
    PYSPARK_PYTHON=${CONDA_DIR}/bin/python \
    PYSPARK_DRIVER=${CONDA_DIR}/bin/python

# pip for additional pyspark-packages
# RUN pip install \
#         graphframes \
#         geospark && \
#         rm -rf $HOME/.cache/pip/*

# RUN $SPARK_HOME/bin/spark-shell --packages graphframes:graphframes:0.8.0-spark3.0-s_2.12

EXPOSE 8888

ENTRYPOINT [ "/usr/bin/tini", "--" ]
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--NotebookApp.token=''"]
