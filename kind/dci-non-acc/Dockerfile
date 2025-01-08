ARG CRIO_IMAGE_NAME=kind-ubuntu-node-crio:22.04
FROM $CRIO_IMAGE_NAME

ARG GO_VERSION=1.20.10
ARG SRIOV_CNI_VERSION=v2.8.0
ARG CNI_PLUGIN_VERSION=v1.5.1

RUN echo "Installing Packages ..." \
    && DEBIAN_FRONTEND=noninteractive clean-install \
    git \
    wget \
    sudo \
    udev \
    build-essential \
    python3-pip \
    pkg-config \
    libnuma-dev \
    zlib1g-dev \
    libpciaccess-dev

RUN pip3 install pyyaml meson ninja pyelftools

RUN echo "Installing go ..." \
    && cd /root/ \
    && wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz \
    && tar xvfz ./go${GO_VERSION}.linux-amd64.tar.gz \
    && printf "\nexport GOPATH=\"\$HOME/gopath\"\nexport GOROOT=\"\$HOME/go\"\nexport PATH=\"\$GOROOT/bin:\$PATH\"\n" >> /root/.bashrc

# build libfpga
COPY build/controller/src/submodules/fpga-software /root/openkasugai-hardware-drivers
COPY build/controller/src/fpgadb /root/openkasugai-hardware-drivers/fpgadb
RUN echo "build libfpga ...." \
    && cd /root/openkasugai-hardware-drivers/lib/ \
    && make dpdk \
    && make mcap \
    && make json \
    && make \
    && mkdir /usr/local/include/fpgalib \
    && cp ./libfpga/include/*.h /usr/local/include/fpgalib/ \
    && cp -r ./libfpga/include/libfpga_internal /usr/local/include/fpgalib/ \
    && cp ./libptu/include/libptu.h /usr/local/include/fpgalib/ \
    && cp ../driver/xpcie_device.h /usr/local/include/fpgalib/ \
    && mkdir /usr/local/lib/fpgalib \
    && cp build/libfpga.a /usr/local/lib/fpgalib/ \
    && ln -s /root/openkasugai-hardware-drivers/lib/DPDK/dpdk /usr/local/lib/fpgalib/dpdk \
    && cp /root/openkasugai-hardware-drivers/lib/libfpga/include/libshmem* /usr/local/include/fpgalib/ \
    && cd /root/openkasugai-hardware-drivers/fpgadb/ \
    && make \
    && cp ./include/libfpgadb.h /usr/local/include/fpgalib/ \
    && cp ./build/libfpgadb.a /usr/local/lib/fpgalib/

ENV GOPATH="/root/gopath"
ENV GOROOT="/root/go"
ENV PATH="/root/go/bin:$PATH"

# install sr-iov cni
RUN echo "Install sr-iov cni" \
    && cd /root/ \
    && git clone https://github.com/k8snetworkplumbingwg/sriov-cni.git -b ${SRIOV_CNI_VERSION} \
    && cd sriov-cni \
    && env \
    && make build \
    && cp build/sriov /opt/cni/bin/ \
    && chmod +x /opt/cni/bin/sriov

# install static cni for multus usage
RUN echo "Install cni plugins" \
    && cd /root/ \
    && git clone https://github.com/containernetworking/plugins/ -b ${CNI_PLUGIN_VERSION} \
    && cd plugins/ \
    && bash ./build_linux.sh \
    && cp bin/* /opt/cni/bin/
