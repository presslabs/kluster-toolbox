FROM google/cloud-sdk:315.0.0-alpine
ENV PYTHONUNBUFFERED 1
ENV GOOGLE_APPLICATION_CREDENTIALS /run/google-credentials.json

RUN set -ex \
    && apk add --no-cache bash git openssl python python3 make curl libstdc++ ca-certificates wget coreutils \
    && wget -q https://bootstrap.pypa.io/get-pip.py -O/tmp/get-pip.py \
    && python /tmp/get-pip.py \
    && rm /tmp/get-pip.py \
    && python3 -m ensurepip \
    && pip3 install zipa

# install docker
ENV DOCKER_VERSION 18.06.1-ce
RUN set -ex \
    && wget -q https://download.docker.com/linux/static/stable/x86_64/docker-$DOCKER_VERSION.tgz \
    && tar -C /usr/local/bin -xzvf docker-$DOCKER_VERSION.tgz --strip-components 1 docker/docker \
    && rm docker-$DOCKER_VERSION.tgz \
    && chmod +x /usr/local/bin/docker \
    && chown root:root /usr/local/bin/docker

# install kubectl
ENV KUBECTL_VERSION 1.14.10
RUN wget -q https://storage.googleapis.com/kubernetes-release/release/v$KUBECTL_VERSION/bin/linux/amd64/kubectl -O/usr/local/bin/kubectl \
    && chmod 0755 /usr/local/bin/kubectl \
    && chown root:root /usr/local/bin/kubectl

# install kubernetes helm
ENV HELM_VERSION 2.17.0
RUN wget -q https://kubernetes-helm.storage.googleapis.com/helm-v$HELM_VERSION-linux-amd64.tar.gz \
    && tar -C /usr/local/bin -xzvf helm-v$HELM_VERSION-linux-amd64.tar.gz --strip-components 1 linux-amd64/helm \
    && rm helm-v$HELM_VERSION-linux-amd64.tar.gz \
    && chmod 0755 /usr/local/bin/helm \
    && chown root:root /usr/local/bin/helm

# install dockerize for templating support
ENV DOCKERIZE_VERSION 1.2.0
RUN wget -q https://github.com/presslabs/dockerize/releases/download/v$DOCKERIZE_VERSION/dockerize-linux-amd64-v$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-v$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-linux-amd64-v$DOCKERIZE_VERSION.tar.gz \
    && chmod 0755 /usr/local/bin/dockerize \
    && chown root:root /usr/local/bin/dockerize

# install mozilla sops
ENV SOPS_VERSION 3.6.1
RUN wget -q https://github.com/mozilla/sops/releases/download/v$SOPS_VERSION/sops-v$SOPS_VERSION.linux -O /usr/local/bin/sops \
    && chmod 0755 /usr/local/bin/sops \
    && chown root:root /usr/local/bin/sops

# install helm secrets plugin
RUN set -ex \
    && helm init --client-only \
    && helm plugin install https://github.com/zendesk/helm-secrets \
    && helm repo add coreos https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/ \
    && helm repo add presslabs https://presslabs.github.io/charts \
    && helm repo add kubes https://presslabs-kubes.github.io/charts

COPY *.sh gh /usr/local/bin/

WORKDIR /src

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
