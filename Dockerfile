FROM debian:9.2
ENV DEBIAN_FRONTEND noninteractive

# https://github.com/William-Yeh/docker-ansible/blob/master/debian9/Dockerfile
RUN echo "===> Installing python, sudo, and supporting tools..."  && \
    apt-get update -y  &&  apt-get install --fix-missing          && \
    DEBIAN_FRONTEND=noninteractive         \
    apt-get install -y                     \
        python python-yaml sudo            \
        curl gcc python-pip python-dev libffi-dev libssl-dev  && \
    apt-get -y --purge remove python-cffi          && \
    pip install --upgrade cffi pywinrm             && \
    \
    \
    \
    echo "===> Installing Ansible..."   && \
    pip install ansible                 && \
    \
    \
    \
    echo "===> Installing handy tools (not absolutely required)..."  && \
    apt-get install -y sshpass openssh-client  && \
    \
    \
    echo "===> Removing unused APT resources..."                  && \
    apt-get -f -y --auto-remove remove \
                 gcc python-pip python-dev libffi-dev libssl-dev  && \
    apt-get clean                                                 && \
    rm -rf /var/lib/apt/lists/*  /tmp/*                           && \
    \
    \
    echo "===> Adding hosts for convenience..."        && \
    mkdir -p /etc/ansible                              && \
    echo 'localhost' > /etc/ansible/hosts

RUN apt-get update && \
    apt-get install -yq --no-install-recommends openssh-client openssl ca-certificates git && \
    apt-get clean && \
    rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

# ruby
ENV PATH $PATH:/usr/local/bin
RUN apt-get update && \
    apt-get install -yq --no-install-recommends build-essential zlib1g-dev libssl-dev libreadline-dev libyaml-dev libxml2-dev libxslt-dev dnsutils && \
    apt-get clean && \
    rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*
RUN git clone https://github.com/rbenv/ruby-build.git
RUN PREFIX=/usr/local ./ruby-build/install.sh
RUN rm -fr /ruby-build
RUN ruby-build 2.4.2 /usr/local
RUN gem update --system

RUN mkdir -p /work
WORKDIR /work
ENV PWD /work
ENV HOME /work
COPY ./Gemfile /work/Gemfile
RUN bundle install
COPY ./ /work
