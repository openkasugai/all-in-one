.PHONY: build-dir kind-values k8s patch-kind dci-kind-base dci-kind-node dci-kind-crio dci-non-acc dci-with-acc k8s-software create-cluster delete-cluster unload-driver install-multus install-sriov-dp post-setup create-cluster-with-all create-cpufunc-ns install-metallb install-nvidia-k8s-ipam send-video-tool setup-cpufunc-sample apply-cpufunc-sample prepare-scenario create-cluster-without-scenario dataflow-calcapp-basic dataflow-calcapp-sriov dataflow-calcapp-basic-multi-worker dataflow-calcapp-sriov-multi-worker dataflow-p1c1 dataflow-p1c2 dataflow-p2c1 dataflow-p2c2 dataflow-p2c3 dataflow-p2c4 dataflow-p3c1 dataflow-p1c1-multi-worker dataflow-p1c2-multi-worker dataflow-p2c1-multi-worker dataflow-p2c2-multi-worker dataflow-p2c3-multi-worker dataflow-p2c4-multi-worker dataflow-p3c1-multi-worker

DCI_REGISTRY_ADDR := ghcr.io/openkasugai/controller
DCI_REGISTRY_ADDR_ALT := 192.168.10.100/images
DCI_REGISTRY_CERT_URL := http://192.168.10.100/harbor/ca.crt

# TODO: make it submodule to controller
DCI_K8S_SOFTWARE_TARFILE := controller.tar.gz

NVIDIA_DRIVER_FILE := NVIDIA-Linux-x86_64-550.90.12.run

K8S_VERSION := v1.31.0
GO_VERSION := 1.23.0
SRIOV_CNI_VERSION := v2.8.1
CRIO_OS := xUbuntu_22.04
CRIO_REPO_VERSION := v1.31
CRIO_PKG_VERSION := 1.31.0-1.1
METALLB_VERSION := v0.14.8
NVIDIA_K8S_IPAM_VERSION := v0.3.5

IMG_TAG := 22.04.5
UBUNTU_IMAGE_NAME := ubuntu:jammy-20240911.1
BASE_IMAGE_NAME := kind-ubuntu:$(IMG_TAG)
NODE_IMAGE_NAME := kind-ubuntu-node:$(IMG_TAG)
CRIO_IMAGE_NAME := kind-ubuntu-node-crio:$(IMG_TAG)
DCI_NODE_IMAGE_NAME := dci-kind-node-non-acc:$(IMG_TAG)
DCI_ACC_IMAGE_NAME := dci-kind-node-with-acc:$(IMG_TAG)

FLOWCTRL_NEW_URL := $(DCI_REGISTRY_ADDR)/whitebox-k8s-flowctrl:1.0.0
WBFUNCTION_NEW_URL := $(DCI_REGISTRY_ADDR)/wbfunction:1.0.0
WBCONNECTION_NEW_URL := $(DCI_REGISTRY_ADDR)/wbconnection:1.0.0

CPUFUNCTION_TARGET_FILE := crc_cpufunction_daemonset.yaml
CPUFUNCTION_OLD_URL := localhost/cpufunction:1.0.0
CPUFUNCTION_NEW_URL := $(DCI_REGISTRY_ADDR)/cpufunction:1.0.0

GPUFUNCTION_TARGET_FILE := crc_gpufunction_daemonset.yaml
GPUFUNCTION_OLD_URL := localhost/gpufunction:1.0.0
GPUFUNCTION_NEW_URL := $(DCI_REGISTRY_ADDR)/gpufunction:1.0.0

FPGAFUNCTION_TARGET_FILE := crc_fpgafunction_daemonset.yaml
FPGAFUNCTION_OLD_URL := localhost/fpgafunction:1.0.0
FPGAFUNCTION_NEW_URL := $(DCI_REGISTRY_ADDR)/fpgafunction:1.0.0

ETHERNETCONNECTION_TARGET_FILE := crc_ethernetconnection_daemonset.yaml
ETHERNETCONNECTION_OLD_URL := localhost/ethernetconnection:1.0.0
ETHERNETCONNECTION_NEW_URL := $(DCI_REGISTRY_ADDR)/ethernetconnection:1.0.0

PCIECONNECTION_TARGET_FILE := crc_pcieconnection_daemonset.yaml
PCIECONNECTION_OLD_URL := localhost/pcieconnection:1.0.0
PCIECONNECTION_NEW_URL := $(DCI_REGISTRY_ADDR)/pcieconnection:1.0.0

DEVICEINFO_TARGET_FILE := crc_deviceinfo_daemonset.yaml
DEVICEINFO_OLD_URL := localhost/deviceinfo:1.0.0
DEVICEINFO_NEW_URL := $(DCI_REGISTRY_ADDR)/deviceinfo:1.0.0

CPUFUNC_GST_NEW_URL := $(DCI_REGISTRY_ADDR_ALT)/cpufunc_gst:1.0.0
CPUFUNC_SIDECAR_NEW_URL := $(DCI_REGISTRY_ADDR_ALT)/cpufunc_sidecar:1.0.0
CPUFUNC_CALCAPP_NEW_URL := $(DCI_REGISTRY_ADDR_ALT)/cpufunc_calcapp:1.0.0
GPUFUNC_DSA_NEW_URL := $(DCI_REGISTRY_ADDR_ALT)/gpufunc_dsa:1.0.0

SEND_VIDEO_TOOL_TARGET_FILE := send_video_tool.yaml
SEND_VIDEO_TOOL_OLD_URL := localhost/send_video_tool:1.0.0
SEND_VIDEO_TOOL_NEW_URL := $(DCI_REGISTRY_ADDR)/send_video_tool:1.0.0

SRIOV_IF_REGEX_1 := ens9f0.*
SRIOV_IF_REGEX_2 := ens9f1.*
SRIOV_PF_IF_1 := ens9f0np0
SRIOV_PF_IF_2 := ens9f1np1
SRIOV_PF_IPADDR_1 := 192.168.20.2/24
SRIOV_PF_IPADDR_2 := 192.168.20.3/24
SRIOV_NUM_VFS := 8

NV_IPAM_SUBNET := 192.168.20.0/24
NV_IPAM_PER_NODE_BLOCK_SIZE := 30
NV_IPAM_GATEWAY := 192.168.20.1
NV_IPAM_EXCLUDE_START_1 := 192.168.20.0
NV_IPAM_EXCLUDE_END_1 := 192.168.20.9
NV_IPAM_EXCLUDE_START_2 := 192.168.20.51
NV_IPAM_EXCLUDE_END_2 := 192.168.20.255

CURRENT_DIR := $(shell pwd)
GO_BIN := $(shell which go)
GROUPNAME := $(shell id -gn)
KIND_BIN := $(shell which kind)
USERNAME := $(shell id -un)

patch-kind:
	cd kind/kind; patch -p1 -N < ../patch/kind.patch || true
	find kind/kind -name *.rej -delete

build-dir:
	mkdir $(CURRENT_DIR)/build || true

dci-kind-base: patch-kind build-dir
	cd kind/kind/images/base; sudo DOCKER_BUILDKIT=1 docker build --build-arg BASE_IMAGE=$(UBUNTU_IMAGE_NAME) --build-arg GO_VERSION=$(GO_VERSION) --build-arg TARGETARCH=amd64 -t $(BASE_IMAGE_NAME) .

k8s: build-dir
	sudo git clone https://github.com/kubernetes/kubernetes -b $(K8S_VERSION) ./build/kubernetes --depth=1 || true

dci-kind-node: build-dir k8s dci-kind-base
	cd build/kubernetes; sudo $(KIND_BIN) build node-image --arch amd64 --base-image $(BASE_IMAGE_NAME) --image $(NODE_IMAGE_NAME) .

dci-kind-crio: dci-kind-node
	cp -r kind/dci-kind-crio build/
	cd build/dci-kind-crio/; sudo docker image build --build-arg NODE_IMAGE_NAME=$(NODE_IMAGE_NAME) --build-arg CRIO_OS=$(CRIO_OS) --build-arg CRIO_REPO_VERSION=$(CRIO_REPO_VERSION) --build-arg CRIO_PKG_VERSION=$(CRIO_PKG_VERSION) -t $(CRIO_IMAGE_NAME) .

dci-non-acc: dci-kind-crio k8s-software
	cp -r kind/dci-non-acc build/
	sudo docker image build --build-arg CRIO_IMAGE_NAME=$(CRIO_IMAGE_NAME) --build-arg GO_VERSION=$(GO_VERSION) --build-arg SRIOV_CNI_VERSION=$(SRIOV_CNI_VERSION) -t $(DCI_NODE_IMAGE_NAME) -f build/dci-non-acc/Dockerfile .

unload-driver:
	# Unload NVIDIA driver on the host to load it on kind-worker
	sudo rmmod nvidia_uvm nvidia_modeset nvidia || true

dci-with-acc: dci-non-acc
	cp -r kind/dci-with-acc build
	sudo docker image build --build-arg DCI_NODE_IMAGE_NAME=$(DCI_NODE_IMAGE_NAME) --build-arg NVIDIA_DRIVER_FILE=$(NVIDIA_DRIVER_FILE) -t $(DCI_ACC_IMAGE_NAME) -f build/dci-with-acc/Dockerfile .

images: dci-with-acc

k8s-software: build-dir
	sudo tar zxvf src/$(DCI_K8S_SOFTWARE_TARFILE) -C build/
	sudo chown -R root:root build/controller
	# copy sample-data-common to controller
	sudo cp build/controller/test/sample-data/sample-data-common/json/* build/controller/src/tools/InfoCollector/infrainfo
	sudo cp -r build/controller/test/sample-data/sample-data-common/yaml build/controller/src/tools/InfoCollector/infrainfo
	# needed to run infocollector
	sudo mkdir build/controller/src/tools/InfoCollector/log || true
	sudo mkdir build/controller/src/tools/InfoCollector/infocollector || true
	# replace image addr in script
	sudo find build/controller/test/script -type f -name run_controllers.sh -exec sed -i 's,localhost/whitebox-k8s-flowctrl:\$$TAG,$(FLOWCTRL_NEW_URL),g' {} +
	sudo find build/controller/test/script -type f -name run_controllers.sh -exec sed -i 's,localhost/wbfunction:\$$TAG,$(WBFUNCTION_NEW_URL),g' {} +
	sudo find build/controller/test/script -type f -name run_controllers.sh -exec sed -i 's,localhost/wbconnection:\$$TAG,$(WBCONNECTION_NEW_URL),g' {} +
	sudo find build/controller/test/script -type f -exec sed -i 's,/home/ubuntu/,/root/,g' {} +
	# replace image addr in daemonsets 
	sudo find build/controller/src/ -type f -name $(CPUFUNCTION_TARGET_FILE) -exec sed -i 's,$(CPUFUNCTION_OLD_URL),$(CPUFUNCTION_NEW_URL),g' {} +
	sudo find build/controller/src/ -type f -name $(GPUFUNCTION_TARGET_FILE) -exec sed -i 's,$(GPUFUNCTION_OLD_URL),$(GPUFUNCTION_NEW_URL),g' {} +
	sudo find build/controller/src/ -type f -name $(FPGAFUNCTION_TARGET_FILE) -exec sed -i 's,$(FPGAFUNCTION_OLD_URL),$(FPGAFUNCTION_NEW_URL),g' {} +
	sudo find build/controller/src/ -type f -name $(ETHERNETCONNECTION_TARGET_FILE) -exec sed -i 's,$(ETHERNETCONNECTION_OLD_URL),$(ETHERNETCONNECTION_NEW_URL),g' {} +
	sudo find build/controller/src/ -type f -name $(PCIECONNECTION_TARGET_FILE) -exec sed -i 's,$(PCIECONNECTION_OLD_URL),$(PCIECONNECTION_NEW_URL),g' {} +
	sudo find build/controller/src/ -type f -name $(DEVICEINFO_TARGET_FILE) -exec sed -i 's,$(DEVICEINFO_OLD_URL),$(DEVICEINFO_NEW_URL),g' {} +

kind-values:
	cp -r kind/kind-values build/
	sed -i 's,DCI_NODE_IMAGE_NAME,$(DCI_NODE_IMAGE_NAME),g' build/kind-values/values.yaml
	sed -i 's,DCI_ACC_IMAGE_NAME,$(DCI_ACC_IMAGE_NAME),g' build/kind-values/values.yaml
	sed -i 's,REPO_DIR,$(CURRENT_DIR),g' build/kind-values/values.yaml

create-cluster: patch-kind unload-driver k8s-software kind-values
	cd kind/kind/cmd/kind; sudo bash -c 'export KIND_CERT_URL=$(DCI_REGISTRY_CERT_URL) && $(GO_BIN) run ./main.go create cluster --config ../../../../build/kind-values/values.yaml --retain'
	sudo kubectl delete configmap fpgafunc-config-filter-resize-high-infer || true
	sudo kubectl delete configmap fpgafunc-config-filter-resize-low-infer || true
	sudo kubectl delete configmap cpufunc-config-decode || true
	sudo kubectl delete configmap cpufunc-config-glue-fdma-to-tcp || true
	sudo kubectl delete configmap cpufunc-config-copy-branch || true
	sudo kubectl delete configmap cpufunc-config-filter-resize-high-infer || true
	sudo kubectl delete configmap cpufunc-config-filter-resize-low-infer || true
	sudo kubectl delete configmap gpufunc-config-high-infer || true
	sudo kubectl delete configmap gpufunc-config-low-infer || true
	sudo kubectl delete -f build/controller/src/tools/InfoCollector/infrainfo/yaml/functioninfo.yaml || true
	sudo kubectl delete -f build/controller/src/tools/InfoCollector/infrainfo/yaml/functiontype.yaml || true
	sudo kubectl delete -f build/controller/src/tools/InfoCollector/infrainfo/yaml/functionchain.yaml || true
	sudo kubectl delete namespace wbfunc-imgproc || true
	sudo kubectl delete namespace chain-imgproc || true

put-sriov-ifs-to-worker:
	sudo bash -c 'echo $(SRIOV_NUM_VFS) > /sys/class/net/$(SRIOV_PF_IF_1)/device/sriov_numvfs' || true
	sudo ln -sfT /proc/$$(sudo docker inspect kind-worker --format '{{ .State.Pid }}')/ns/net /var/run/netns/kind-worker
	ip addr | grep -e $(SRIOV_IF_REGEX_1): | cut -d ':' -f2 | tr -d ' ' | while IFS= read -r line; do sudo ip link set $$line netns kind-worker; done
	ip addr | grep -e "altname $(SRIOV_IF_REGEX_1)" | awk '{print $$2}' | while IFS= read -r line; do sudo ip link set $$line netns kind-worker; done
	sudo ip netns exec kind-worker ip addr add $(SRIOV_PF_IPADDR_1) dev $(SRIOV_PF_IF_1) || true
	sudo ip netns exec kind-worker ip link set $(SRIOV_PF_IF_1) up

put-sriov-ifs-to-worker2:
	sudo bash -c 'echo $(SRIOV_NUM_VFS) > /sys/class/net/$(SRIOV_PF_IF_2)/device/sriov_numvfs' || true
	sudo ln -sfT /proc/$$(sudo docker inspect kind-worker2 --format '{{ .State.Pid }}')/ns/net /var/run/netns/kind-worker2
	ip addr | grep -e $(SRIOV_IF_REGEX_2): | cut -d ':' -f2 | tr -d ' ' | while IFS= read -r line; do sudo ip link set $$line netns kind-worker2; done
	ip addr | grep -e "altname $(SRIOV_IF_REGEX_2)" | awk '{print $$2}' | while IFS= read -r line; do sudo ip link set $$line netns kind-worker2; done
	sudo ip netns exec kind-worker2 ip addr add $(SRIOV_PF_IPADDR_2) dev $(SRIOV_PF_IF_2) || true
	sudo ip netns exec kind-worker2 ip link set $(SRIOV_PF_IF_2) up

install-multus:
	sudo kubectl apply -f manifest/multus/multus-daemonset-thick.yml
	sudo kubectl apply -f manifest/multus/kind-worker-config-net-sriov.yaml

install-sriov-dp:
	cp -r manifest/sriov build/
	sed -i 's,SRIOV_PF_IF_1,$(SRIOV_PF_IF_1),g' build/sriov/configMap.yaml
	sed -i 's,SRIOV_PF_IF_2,$(SRIOV_PF_IF_2),g' build/sriov/configMap.yaml
	sudo kubectl apply -f build/sriov/

create-cpufunc-ns:
	sudo kubectl create ns cpufunc-calcapp || true
	sudo kubectl create ns cpufunc-sample || true
	sudo kubectl create clusterrolebinding cpufunc-caclapp-default-view --clusterrole=view --serviceaccount=cpufunc-calcapp:default || true
	sudo kubectl create clusterrolebinding cpufunc-sample-default-view --clusterrole=view --serviceaccount=cpufunc-sample:default || true

install-metallb: create-cpufunc-ns
	# TODO: use kustomize
	sudo kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/$(METALLB_VERSION)/config/manifests/metallb-native.yaml
	bash tool/pod_status_check.sh
	sleep 60
	sudo kubectl apply -f manifest/metallb/

install-nvidia-k8s-ipam:
	sudo kubectl kustomize https://github.com/mellanox/nvidia-k8s-ipam/deploy/overlays/no-webhook?ref=$(NVIDIA_K8S_IPAM_VERSION) | sudo kubectl apply -f -
	cp -r manifest/nvidia-k8s-ipam build/
	sed -i 's,NV_IPAM_SUBNET,$(NV_IPAM_SUBNET),g' build/nvidia-k8s-ipam/ippool.yaml
	sed -i 's,NV_IPAM_PER_NODE_BLOCK_SIZE,$(NV_IPAM_PER_NODE_BLOCK_SIZE),g' build/nvidia-k8s-ipam/ippool.yaml
	sed -i 's,NV_IPAM_GATEWAY,$(NV_IPAM_GATEWAY),g' build/nvidia-k8s-ipam/ippool.yaml
	sed -i 's,NV_IPAM_EXCLUDE_START_1,$(NV_IPAM_EXCLUDE_START_1),g' build/nvidia-k8s-ipam/ippool.yaml
	sed -i 's,NV_IPAM_EXCLUDE_END_1,$(NV_IPAM_EXCLUDE_END_1),g' build/nvidia-k8s-ipam/ippool.yaml
	sed -i 's,NV_IPAM_EXCLUDE_START_2,$(NV_IPAM_EXCLUDE_START_2),g' build/nvidia-k8s-ipam/ippool.yaml
	sed -i 's,NV_IPAM_EXCLUDE_END_2,$(NV_IPAM_EXCLUDE_END_2),g' build/nvidia-k8s-ipam/ippool.yaml
	sudo kubectl apply -f build/nvidia-k8s-ipam/ippool.yaml

setup-cpufunc-sample: install-nvidia-k8s-ipam create-cpufunc-ns
	sudo kubectl apply -f build/nvidia-k8s-ipam/cpufunc-calcapp/networkattachmentdefinition.yaml
	sudo kubectl apply -f build/nvidia-k8s-ipam/cpufunc-sample/networkattachmentdefinition.yaml
	sudo find build/controller/test/sample-data/sample-data-for-all-in-one/ -type f -name "*.yaml" -exec sed -i 's,localhost/cpufunc_gst:latest,$(CPUFUNC_GST_NEW_URL),g' {} +
	sudo find build/controller/test/sample-data/sample-data-for-all-in-one/ -type f -name "*.yaml" -exec sed -i 's,localhost/cpufunc_sidecar:latest,$(CPUFUNC_SIDECAR_NEW_URL),g' {} +
	sudo find build/controller/test/sample-data/sample-data-for-all-in-one/ -type f -name "*.yaml" -exec sed -i 's,localhost/cpufunc_calcapp:latest,$(CPUFUNC_CALCAPP_NEW_URL),g' {} +
	sudo find build/controller/test/sample-data/sample-data-for-all-in-one/ -type f -name "*.yaml" -exec sed -i 's,localhost/gpufunc_dsa:latest,$(GPUFUNC_DSA_NEW_URL),g' {} +
	sudo cp manifest/sample/multi-worker-scenarios/kustomization.yaml build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p1c1/
	sudo cp manifest/sample/multi-worker-scenarios/kustomization.yaml build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p1c2/
	sudo cp manifest/sample/multi-worker-scenarios/kustomization.yaml build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p2c1/
	sudo cp manifest/sample/multi-worker-scenarios/kustomization.yaml build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p2c2/
	sudo cp manifest/sample/multi-worker-scenarios/kustomization.yaml build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p2c3/
	sudo cp manifest/sample/multi-worker-scenarios/kustomization.yaml build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p2c4/
	sudo cp manifest/sample/multi-worker-scenarios/kustomization.yaml build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p3c1/
	sudo cp manifest/sample/multi-worker-scenarios/kustomization.yaml build/controller/test/sample-data/sample-data-for-all-in-one/calc-func/basic/
	sudo cp manifest/sample/multi-worker-scenarios/kustomization.yaml build/controller/test/sample-data/sample-data-for-all-in-one/calc-func/sriov/
	sudo kubectl apply -f manifest/sample/multi-worker-scenarios/calc-func/strategy.yaml
	sudo kubectl apply -f manifest/sample/multi-worker-scenarios/calc-func/user_requirement.yaml
	sudo kubectl apply -f manifest/sample/multi-worker-scenarios/inferenece/strategy.yaml
	sudo kubectl apply -f manifest/sample/multi-worker-scenarios/inferenece/user_requirement.yaml

apply-cpufunc-sample: setup-cpufunc-sample
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/calc-func/basic/cm-cpufunc-config.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/calc-func/basic/functioninfo.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/calc-func/basic/functiontype.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/calc-func/basic/functionchain.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/calc-func/sriov/cm-cpufunc-config.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/calc-func/sriov/functioninfo.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/calc-func/sriov/functiontype.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/calc-func/sriov/functionchain.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p1c1/cm-cpufunc-config.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p1c1/functioninfo.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p1c1/functiontype.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p1c1/functionchain.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p1c2/cm-cpufunc-config.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p1c2/functioninfo.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p1c2/functiontype.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p1c2/functionchain.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p2c1/cm-cpufunc-config.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p2c1/functioninfo.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p2c1/functiontype.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p2c1/functionchain.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p2c2/cm-cpufunc-config.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p2c2/functioninfo.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p2c2/functiontype.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p2c2/functionchain.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p2c3/cm-cpufunc-config.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p2c3/functioninfo.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p2c3/functiontype.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p2c3/functionchain.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p2c4/cm-cpufunc-config.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p2c4/functioninfo.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p2c4/functiontype.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p2c4/functionchain.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p3c1/cm-cpufunc-config.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p3c1/functioninfo.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p3c1/functiontype.yaml
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p3c1/functionchain.yaml

send-video-tool:
	sudo kubectl create ns test || true
	cp -r manifest/tools build/
	find build/tools/ -type f -name $(SEND_VIDEO_TOOL_TARGET_FILE) -exec sed -i 's,$(SEND_VIDEO_TOOL_OLD_URL),$(SEND_VIDEO_TOOL_NEW_URL),g' {} +
	sudo kubectl apply -f build/tools/send_video_tool.yaml
	sudo kubectl get pod -n test
	bash tool/pod_status_check.sh

post-setup: install-multus put-sriov-ifs-to-worker put-sriov-ifs-to-worker2 install-sriov-dp create-cpufunc-ns install-metallb install-nvidia-k8s-ipam setup-cpufunc-sample

create-cluster-without-scenario: k8s-software create-cluster post-setup send-video-tool

prepare-scenario: apply-cpufunc-sample send-video-tool

create-cluster-with-all: k8s-software create-cluster post-setup prepare-scenario

# When the dataflow was deleted, the Pod's VFs will be removed from the worker node.
# So add it before applying the DataFlow.
dataflow-calcapp-basic: put-sriov-ifs-to-worker put-sriov-ifs-to-worker2
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/calc-func/basic/df-cpufunc.yaml

dataflow-calcapp-sriov: put-sriov-ifs-to-worker put-sriov-ifs-to-worker2
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/calc-func/sriov/df-cpufunc.yaml

dataflow-calcapp-basic-multi-worker: put-sriov-ifs-to-worker put-sriov-ifs-to-worker2
	sudo kubectl apply -k build/controller/test/sample-data/sample-data-for-all-in-one/calc-func/basic/

dataflow-calcapp-sriov-multi-worker: put-sriov-ifs-to-worker put-sriov-ifs-to-worker2
	sudo kubectl apply -k build/controller/test/sample-data/sample-data-for-all-in-one/calc-func/sriov/

dataflow-p1c1: put-sriov-ifs-to-worker put-sriov-ifs-to-worker2
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p1c1/df-cpufunc.yaml

dataflow-p1c2: put-sriov-ifs-to-worker put-sriov-ifs-to-worker2
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p1c2/df-cpufunc.yaml

dataflow-p2c1: put-sriov-ifs-to-worker put-sriov-ifs-to-worker2
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p2c1/df-cpufunc.yaml

dataflow-p2c2: put-sriov-ifs-to-worker put-sriov-ifs-to-worker2
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p2c2/df-cpufunc.yaml

dataflow-p2c3: put-sriov-ifs-to-worker put-sriov-ifs-to-worker2
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p2c3/df-cpufunc.yaml

dataflow-p2c4: put-sriov-ifs-to-worker put-sriov-ifs-to-worker2
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p2c4/df-cpufunc.yaml

dataflow-p3c1: put-sriov-ifs-to-worker put-sriov-ifs-to-worker2
	sudo kubectl apply -f build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p3c1/df-cpufunc.yaml

dataflow-p1c1-multi-worker: put-sriov-ifs-to-worker put-sriov-ifs-to-worker2
	sudo kubectl apply -k build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p1c1/

dataflow-p1c2-multi-worker: put-sriov-ifs-to-worker put-sriov-ifs-to-worker2
	sudo kubectl apply -k build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p1c2/

dataflow-p2c1-multi-worker: put-sriov-ifs-to-worker put-sriov-ifs-to-worker2
	sudo kubectl apply -k build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p2c1/

dataflow-p2c2-multi-worker: put-sriov-ifs-to-worker put-sriov-ifs-to-worker2
	sudo kubectl apply -k build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p2c2/

dataflow-p2c3-multi-worker: put-sriov-ifs-to-worker put-sriov-ifs-to-worker2
	sudo kubectl apply -k build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p2c3/

dataflow-p2c4-multi-worker: put-sriov-ifs-to-worker put-sriov-ifs-to-worker2
	sudo kubectl apply -k build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p2c4/

dataflow-p3c1-multi-worker: put-sriov-ifs-to-worker put-sriov-ifs-to-worker2
	sudo kubectl apply -k build/controller/test/sample-data/sample-data-for-all-in-one/cpugpu-func/p3c1/

delete-cluster:
	sudo $(KIND_BIN) delete cluster

clean:
	sudo rm -rf $(CURRENT_DIR)/build
