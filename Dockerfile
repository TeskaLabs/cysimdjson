FROM ubuntu:20.10

RUN apt-get update -qq
RUN apt-get install -y git python3 python3-dev python3-pip
RUN pip3 install cython
RUN pip3 install git+https://github.com/TeskaLabs/cysimdjson.git
RUN pip3 install ipython

CMD ["ipython"]
