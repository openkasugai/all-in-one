ARG NODE_IMAGE_NAME=kind-ubuntu-node:22.04
FROM $NODE_IMAGE_NAME

ARG CRIO_OS=xUbuntu_22.04

ARG KUBERNETES_VERSION=v1.31
ARG CRIO_REPO_VERSION=v1.31
ARG CRIO_PKG_VERSION=1.31.0-1.1
ARG PROJECT_PATH=stable:/${CRIO_REPO_VERSION}

RUN echo "Installing Packages ..." \
    && apt-get update \
    && apt-get install -y software-properties-common curl \
    && curl -fsSL https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list \
    && curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/${PROJECT_PATH}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/${PROJECT_PATH}/deb/ /" | tee /etc/apt/sources.list.d/cri-o.list \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get --option=Dpkg::Options::=--force-confdef install -y cri-o=${CRIO_PKG_VERSION} \
    && mkdir /etc/crio/net.d/ \
    && mv /etc/cni/net.d/11-crio-ipv4-bridge.conflist /etc/crio/net.d/ \
    && rm -rf /etc/cni/net.d/ \
    && apt-mark hold cri-o \
    && systemctl disable containerd \
    && systemctl enable crio
