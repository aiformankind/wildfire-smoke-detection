# Copyright 2018 The TensorFlow Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# #==========================================================================

FROM tensorflow/tensorflow

# Define environment variable
ENV WORKPATH /tensorflow

WORKDIR $WORKPATH

COPY . $WORKPATH/

EXPOSE 8888 6006

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y git 

# Get the tensorflow models research directory, and move it into tensorflow
# source folder to match recommendation of installation
RUN git clone --depth 1 https://github.com/tensorflow/models.git

RUN mv object_detection_wildfire.ipynb /tensorflow/models/research/object_detection/ && \
    mv create_tf_record.py /tensorflow/models/research/object_detection/

# Install the Tensorflow Object Detection API from here
# https://github.com/tensorflow/models/blob/master/research/object_detection/g3doc/installation.md

# Install object detection api dependencies
RUN apt-get install -y protobuf-compiler python-pil python-lxml python-tk && \
    pip install Cython && \
    pip install contextlib2 && \
    pip install jupyter && \
    pip install matplotlib

# Install pycocoapi
RUN git clone --depth 1 https://github.com/cocodataset/cocoapi.git && \
    cd cocoapi/PythonAPI && \
    make -j8 && \
    cp -r pycocotools /tensorflow/models/research && \
    cd ../../ && \
    rm -rf cocoapi

# Get protoc 3.0.0, rather than the old version already in the container
RUN curl -OL "https://github.com/google/protobuf/releases/download/v3.0.0/protoc-3.0.0-linux-x86_64.zip" && \
    unzip protoc-3.0.0-linux-x86_64.zip -d proto3 && \
    mv proto3/bin/* /usr/local/bin && \
    mv proto3/include/* /usr/local/include && \
    rm -rf proto3 protoc-3.0.0-linux-x86_64.zip

# Run protoc on the object detection repo
RUN cd /tensorflow/models/research && \
    protoc object_detection/protos/*.proto --python_out=.

# Set the PYTHONPATH to finish installing the API
ENV PYTHONPATH $PYTHONPATH:/tensorflow/models/research:/tensorflow/models/research/slim


# Install wget (to make life easier below) and editors (to allow people to edit
# the files inside the container)
RUN apt-get install -y wget vim emacs nano


# Grab various data files which are used throughout the demo: dataset,
# pretrained model.


# Pretrained model
RUN curl -O "http://download.tensorflow.org/models/object_detection/faster_rcnn_resnet101_coco_11_06_2017.tar.gz" && \
    mkdir train && \
    tar xzf faster_rcnn_resnet101_coco_11_06_2017.tar.gz && \
    rm faster_rcnn_resnet101_coco_11_06_2017.tar.gz && \
    mv faster_rcnn_resnet101_coco_11_06_2017 train/ && \
    mv faster_rcnn_resnet101.config train/	

ENTRYPOINT ["/bin/bash"]
