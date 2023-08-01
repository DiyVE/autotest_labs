FROM ubuntu:22.04


RUN apt-get update && apt-get install -y sudo
RUN useradd -rm -s /bin/bash -g root -G sudo -d /home/work work
RUN passwd -d work

ADD . /home/work/

USER work

WORKDIR /home/work/

ENTRYPOINT ["./run-lab.sh"]
