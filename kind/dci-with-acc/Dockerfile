ARG DCI_NODE_IMAGE_NAME=dci-kind-node-non-acc:22.04
FROM $DCI_NODE_IMAGE_NAME

ARG DISTRIBUTION=ubuntu2204
ARG NV_TOOLKIT_VERSION=1.16.2-1
ARG NVIDIA_DRIVER_FILE=NVIDIA-Linux-x86_64-550.54.15.run

# install nvidia-container-toolkit
RUN curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
    && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
       sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
       tee /etc/apt/sources.list.d/nvidia-container-toolkit.list \
    && apt-get update \
    && apt-get install -y linux-headers-$(uname -r) nvidia-container-toolkit=${NV_TOOLKIT_VERSION} nvidia-container-toolkit-base=${NV_TOOLKIT_VERSION} \
    && nvidia-ctk runtime configure --runtime=crio --set-as-default --config=/etc/crio/crio.conf.d/99-nvidia.conf

COPY kind/dci-with-acc/etc/crio/crio.conf.d/99-nvidia.conf /etc/crio/crio.conf.d/99-nvidia.conf
COPY kind/dci-with-acc/etc/nvidia-container-runtime/config.toml /etc/nvidia-container-runtime/config.toml

# install gpu driver
COPY driver/nvidia/${NVIDIA_DRIVER_FILE} /root/
RUN cd /root; sh ${NVIDIA_DRIVER_FILE} -q --ui=none --skip-module-load --allow-installation-with-running-driver

# install nvidia-mps and setup as service
RUN printf "\nexport CUDA_DEVICE_ORDER=\"PCI_BUS_ID\"\nexport CUDA_VISIBLE_DEVICES=0,1\nexport CUDA_MPS_PIPE_DIRECTORY=/tmp/nvidia-mps\nexport CUDA_MPS_LOG_DIRECTORY=/tmp/nvidia-mps\n" >> /root/.bashrc
COPY kind/dci-with-acc/etc/systemd/system/nvidia-mps.service /etc/systemd/system/nvidia-mps.service
RUN systemctl enable nvidia-mps

# install DCGM
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/${DISTRIBUTION}/x86_64/cuda-keyring_1.1-1_all.deb \
    && dpkg -i cuda-keyring_1.1-1_all.deb \
    && apt-get update \
    && apt-get install -y datacenter-gpu-manager
