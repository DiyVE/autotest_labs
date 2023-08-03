FROM ubuntu:22.04

RUN apt-get update
# RUN apt-get install -y sudo gcc g++ gperf bison flex texinfo help2man make libncurses5-dev \
# 	python3-dev autoconf automake libtool libtool-bin gawk wget bzip2 xz-utils unzip \
# 	patch libstdc++6 rsync git meson ninja-build bc cpio kmod libssl-dev \
# 	device-tree-compiler swig python3-distutils
RUN apt-get install -y gcc g++ gperf bison flex texinfo help2man make libncurses5-dev \
    python3-dev autoconf automake libtool libtool-bin gawk wget bzip2 xz-utils unzip \
    patch libstdc++6 rsync git meson ninja-build
RUN useradd -rm -s /bin/bash -u 1000 -g root -G sudo -d /home/work work
RUN passwd -d work

ADD . /home/work/

USER work

ENV USER=work

WORKDIR /home/work/

ENTRYPOINT ["./run-lab.sh"]
