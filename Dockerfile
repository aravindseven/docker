FROM ubuntu:18.04

RUN apt-get update && apt-get install -y \
    sudo \
    curl \
    git \
    wget \
    zip \
    software-properties-common 

# Python package management and basic dependencies
RUN apt-get install -y curl python3.7 python3.7-dev python3.7-distutils

# Register the version in alternatives
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.7 1

# Set python 3 as the default python
RUN update-alternatives --set python /usr/bin/python3.7

# Upgrade pip to latest version
RUN curl -s https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python get-pip.py --force-reinstall && \
    rm get-pip.py

RUN apt-get update && apt-get -y install cmake protobuf-compiler

ADD torch_setup .

RUN git clone https://github.com/torch/distro.git ~/torch --recursive

COPY torch_setup/install-deps /root/torch
# ADD /home/nuc-obs-06/torch/install-deps /root/torch/

RUN cat /etc/os-release

RUN cd ~/torch  && \
    bash install-deps

RUN cd ~/torch && \
    ./install.sh

RUN git clone https://github.com/cmusatyalab/openface.git ~/openface

ADD . /root/openface
RUN python -m pip install --upgrade --force pip
RUN cd ~/openface && \
    # ./models/get-models.sh && \
    python setup.py install

RUN ~/torch/install/bin/luarocks install torch
RUN ~/torch/install/bin/luarocks install nn
RUN ~/torch/install/bin/luarocks install dpnn


RUN ln -s /root/torch/install/bin/* /usr/local/bin

#OPENVINO
ARG DOWNLOAD_LINK=http://registrationcenter-download.intel.com/akdlm/irc_nas/16057/l_openvino_toolkit_p_2019.3.376.tgz
ARG INSTALL_DIR=/opt/intel/openvino
ARG TEMP_DIR=/tmp/openvino_installer
RUN apt-get install -y --no-install-recommends \
    cpio \
    lsb-release && \
    rm -rf /var/lib/apt/lists/*
RUN mkdir -p $TEMP_DIR && cd $TEMP_DIR && \
    wget -c $DOWNLOAD_LINK && \
    tar xf l_openvino_toolkit*.tgz && \
    cd l_openvino_toolkit* && \
    sed -i 's/decline/accept/g' silent.cfg && \
    ./install.sh -s silent.cfg && \
    rm -rf $TEMP_DIR

RUN $INSTALL_DIR/install_dependencies/install_openvino_dependencies.sh

# build Inference Engine samples
RUN mkdir $INSTALL_DIR/deployment_tools/inference_engine/samples/build && cd $INSTALL_DIR/deployment_tools/inference_engine/samples/build && \
    /bin/bash -c "source $INSTALL_DIR/bin/setupvars.sh"

# Create app directory
WORKDIR /app

ADD kisoks_docker .

# Install app dependencies
RUN pip install -r requirements.txt

RUN apt-get install -y tesseract-ocr
RUN apt-get install -y libtesseract-dev
RUN pip install tesseract
RUN pip install tesseract-ocr

EXPOSE 9090

COPY kisoks_docker/start.sh /app/start.sh

ENTRYPOINT ["bash", "/app/start.sh"]

    

