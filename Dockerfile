FROM golang:1.8-alpine as tf-plugins
COPY terraform-install-plugin.sh /usr/local/bin/
RUN set -ex \
    && apk add --no-cache openssl tar bash \
    && mkdir /usr/lib/terraform-plugins \
    && /usr/local/bin/terraform-install-plugin.sh "terraform-provider-google" "1.0.1" \
    && /usr/local/bin/terraform-install-plugin.sh "terraform-provider-kubernetes" "1.0.0" \
    && /usr/local/bin/terraform-install-plugin.sh "terraform-provider-template" "1.0.0" \
    && /usr/local/bin/terraform-install-plugin.sh "terraform-provider-random" "1.0.0" \
    && /usr/local/bin/terraform-install-plugin.sh "https://github.com/mcuadros/terraform-provider-helm/releases/download/v0.3.2/terraform-provider-helm_v0.3.2_linux_amd64.tar.gz"

# # Install terraform-provider-helm plugin from source since it's not official yet
# ENV TF_PROVIDER_HELM_REPO mcuadros/terraform-provider-helm
# ENV TF_PROVIDER_HELM_REF v0.3.2
# RUN set -ex \
#     && mkdir -p $GOPATH/src/github.com/mcuadros/terraform-provider-helm \
#     && cd $GOPATH/src/github.com/mcuadros/terraform-provider-helm \
#     && wget https://github.com/$TF_PROVIDER_HELM_REPO/archive/$TF_PROVIDER_HELM_REF.tar.gz -O"/tmp/terraform-provider-helm.tar.gz" \
#     && tar -zxf /tmp/terraform-provider-helm.tar.gz --strip-components 1 \
#     && rm /tmp/terraform-provider-helm.tar.gz \
#     && go build \
#     && mv terraform-provider-helm /usr/lib/terraform-plugins

FROM google/cloud-sdk:176.0.0-alpine
ENV PYTHONUNBUFFERED 1
ENV GOOGLE_APPLICATION_CREDENTIALS /run/google-credentials.json

RUN set -ex \
    && apk add --no-cache bash git openssl python make curl libstdc++ \
    && wget -q https://bootstrap.pypa.io/get-pip.py -O/tmp/get-pip.py \
    && python /tmp/get-pip.py \
    && rm /tmp/get-pip.py

# install git-crypt
ENV GIT_CRYPT_VERSION 0.5.0
RUN set -ex \
    && apk add --no-cache --virtual .build-deps gcc g++ openssl-dev make \
    && mkdir -p /usr/src \
    && cd /usr/src \
    && git clone https://github.com/AGWA/git-crypt.git \
    && cd git-crypt \
    && git checkout $GIT_CRYPT_VERSION \
    && make \
    && make install \
    && apk del .build-deps \
    && rm -rf /usr/src

# install kubectl
ENV KUBECTL_VERSION 1.8.2
RUN wget https://storage.googleapis.com/kubernetes-release/release/v$KUBECTL_VERSION/bin/linux/amd64/kubectl -O/usr/local/bin/kubectl \
    && chmod 0755 /usr/local/bin/kubectl \
    && chown root:root /usr/local/bin/kubectl

# install kubernetes helm
ENV HELM_VERSION 2.7.0
RUN wget https://kubernetes-helm.storage.googleapis.com/helm-v$HELM_VERSION-linux-amd64.tar.gz \
    && tar -C /usr/local/bin -xzvf helm-v$HELM_VERSION-linux-amd64.tar.gz --strip-components 1 linux-amd64/helm \
    && rm helm-v$HELM_VERSION-linux-amd64.tar.gz \
    && chmod 0755 /usr/local/bin/helm \
    && chown root:root /usr/local/bin/helm

# install dockerize for templating support
ENV DOCKERIZE_VERSION 0.5.0
RUN wget https://github.com/jwilder/dockerize/releases/download/v$DOCKERIZE_VERSION/dockerize-alpine-linux-amd64-v$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-alpine-linux-amd64-v$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-alpine-linux-amd64-v$DOCKERIZE_VERSION.tar.gz \
    && chmod 0755 /usr/local/bin/dockerize \
    && chown root:root /usr/local/bin/dockerize

# install terraform
ENV TERRAFORM_VERSION 0.10.8
RUN wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -O terraform.zip \
    && unzip terraform.zip -d /usr/local/bin \
    && rm -f terraform.zip \
    && chmod 0755 /usr/local/bin/terraform \
    && chown root:root /usr/local/bin/terraform
# copy terraform plugins
COPY --from=tf-plugins /usr/lib/terraform-plugins /root/.terraform.d/plugins/linux_amd64/

# install mozilla sops
ENV SOPS_VERSION 3.0.0
RUN wget -q https://github.com/mozilla/sops/releases/download/$SOPS_VERSION/sops-$SOPS_VERSION.linux -O /usr/local/bin/sops \
    && chmod 0755 /usr/local/bin/sops \
    && chown root:root /usr/local/bin/sops

# install helm secrets plugin
RUN set -ex \
    && helm init --client-only \
    && helm plugin install https://github.com/futuresimple/helm-secrets \
    && helm repo add kubes https://presslabs-kubes.github.io/charts \
    && helm repo add kluster https://kluster-charts.storage.googleapis.com

# setup terraform for CI
ENV TF_INPUT 0

COPY *.sh /usr/local/bin/

WORKDIR /src

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
