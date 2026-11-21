FROM ros:jazzy
RUN apt-get update && apt-get install -y iproute2 python3-numpy \
    ros-jazzy-rmw-cyclonedds-cpp ros-jazzy-rmw-zenoh-cpp \
 && rm -rf /var/lib/apt/lists/*
COPY pub.py sub.py /work/
WORKDIR /work
