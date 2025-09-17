###########################################
# 2025-03-11 kathy
# k3s - lightweight k8s creted by rancher
# k3d - k3s running in a container
# like kind, works on config file
# unlike kind, comes with ingress (traeffik)
# many things removed from the image
# so is very light but not fully compliant
# podman?
#

#################################
# K3d                           #
# How to run Kubernetes locally #
# 2021-04-06 24mins             #
# https://youtu.be/mCesuGk-Fks  #
#################################

# Referenced videos:
# - [2025-03-11] How to run local multi-node Kubernetes clusters using kind: https://youtu.be/C0v5gJSWuSo
# - Kaniko - Building Container Images In Kubernetes Without Docker: https://youtu.be/EgwVQN6GNJg

#########
# Setup #
#########

# Install `k3d` CLI (https://k3d.io/#installation)
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
#################################
# Creating single-node clusters #
#################################

export KUBECONFIG=$PWD/kubeconfig.yaml

k3d cluster create my-cluster
# failed to run with podman
# https://k3d.io/v5.4.1/usage/advanced/podman/
#
# instructions for rootles
19:37:22 ~/vfarcic/k3d-demo (master) $ systemctl --user enable --now podman.socket
Created symlink /home/me/.config/systemd/user/sockets.target.wants/podman.socket → /usr/lib/systemd/user/podman.socket.

19:40:33 ~/vfarcic/k3d-demo (master) $ XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}

19:41:02 ~/vfarcic/k3d-demo (master) $ echo $XDG_RUNTIME_DIR
/run/user/1000/

19:41:13 ~/vfarcic/k3d-demo (master) $ export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock

19:41:29 ~/vfarcic/k3d-demo (master) $ echo $DOCKER_HOST
unix:///run/user/1000//podman/podman.sock

19:41:42 ~/vfarcic/k3d-demo (master) $ k3d cluster create my-cluster
INFO[0000] Prep: Network
INFO[0001] Created network 'k3d-my-cluster'
INFO[0001] Created image volume k3d-my-cluster-images
INFO[0001] Starting new tools node...
INFO[0002] Creating node 'k3d-my-cluster-server-0'
INFO[0005] Pulling image 'ghcr.io/k3d-io/k3d-tools:5.8.3'
INFO[0006] Pulling image 'docker.io/rancher/k3s:v1.31.5-k3s1'
ERRO[0022] Failed to run tools container for cluster 'my-cluster'
INFO[0126] Creating LoadBalancer 'k3d-my-cluster-serverlb'
INFO[0129] Pulling image 'ghcr.io/k3d-io/k3d-proxy:5.8.3'
ERRO[0168] failed to ensure tools node: failed to run k3d-tools node for cluster 'my-cluster': failed to create node 'k3d-my-cluster-tools': runtime failed to create node 'k3d-my-cluster-tools': failed to create container for node 'k3d-my-cluster-tools': docker failed to create container 'k3d-my-cluster-tools': Error response from daemon: make cli opts(): making volume mountpoint for volume /var/run/docker.sock: mkdir /var/run/docker.sock: permission denied
ERRO[0168] Failed to create cluster >>> Rolling Back
INFO[0168] Deleting cluster 'my-cluster'
INFO[0169] Deleting cluster network 'k3d-my-cluster'
INFO[0169] Deleting 1 attached volumes...
FATA[0170] Cluster creation FAILED, all changes have been rolled back!
################################################
# then tried a hybrid (not sure whether my case is rootles or not)
19:49:08 ~/vfarcic/k3d-demo (master) $ systemctl status podman.socket
● podman.socket - Podman API Socket
     Loaded: loaded (/usr/lib/systemd/system/podman.socket; enabled; preset: enabled)
     Active: active (listening) since Tue 2025-03-11 11:13:42 IST; 8h ago
   Triggers: ● podman.service
       Docs: man:podman-system-service(1)
     Listen: /run/podman/podman.sock (Stream)
     CGroup: /system.slice/podman.socket

19:51:30 ~/vfarcic/k3d-demo (master) $ ll /run/user/1000/podman/podman.sock
srw-rw---- 1 me me 0 Mar 11 19:40 /run/user/1000/podman/podman.sock

19:52:31 ~/vfarcic/k3d-demo (master) $ ln -s /run/podman/podman.sock /var/run/docker.sock
ln: failed to create symbolic link '/var/run/docker.sock': Permission denied

19:53:12 ~/vfarcic/k3d-demo (master) $ sudo ln -s /run/podman/podman.sock /var/run/docker.sock

# now could create a cluster but only with sudo
19:54:00 ~/vfarcic/k3d-demo (master) $ sudo k3d cluster create my-cluster
INFO[0000] Prep: Network
INFO[0000] Created network 'k3d-my-cluster'
INFO[0000] Created image volume k3d-my-cluster-images
INFO[0000] Starting new tools node...
INFO[0001] Creating node 'k3d-my-cluster-server-0'
INFO[0002] Pulling image 'ghcr.io/k3d-io/k3d-tools:5.8.3'
INFO[0005] Pulling image 'docker.io/rancher/k3s:v1.31.5-k3s1'
INFO[0013] Starting node 'k3d-my-cluster-tools'
INFO[0107] Creating LoadBalancer 'k3d-my-cluster-serverlb'
INFO[0109] Pulling image 'ghcr.io/k3d-io/k3d-proxy:5.8.3'
INFO[0153] Using the k3d-tools node to gather environment information
INFO[0157] HostIP: using network gateway 10.89.0.1 address
INFO[0157] Starting cluster 'my-cluster'
INFO[0157] Starting servers...
INFO[0157] Starting node 'k3d-my-cluster-server-0'
INFO[0164] All agents already running.
INFO[0164] Starting helpers...
INFO[0164] Starting node 'k3d-my-cluster-serverlb'
INFO[0170] Injecting records for hostAliases (incl. host.k3d.internal) and for 2 network members into CoreDNS configmap...
INFO[0172] Cluster 'my-cluster' created successfully!
####################################################
# but this was not working due to a rootless mess :-(
20:04:50 ~/vfarcic/k3d-demo (master) $ sudo k3d kubeconfig merge my-cluster --kubeconfig-switch-context
/root/.config/k3d/kubeconfig-my-cluster.yaml

# almost gave up but then got to a different instructions 
# for running with podman
# https://k3d.io/stable/usage/advanced/podman/?h=podman#using-rootless-podman
# done as they say and it looks better
systemctl --user enable --now podman.socket
XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock
export DOCKER_SOCK=$XDG_RUNTIME_DIR/podman/podman.sock
k3d cluster create new

20:34:43 ~/vfarcic/k3d-demo (master) $ k3d cluster create new
INFO[0000] Prep: Network
INFO[0001] Created network 'k3d-new'
INFO[0001] Created image volume k3d-new-images
INFO[0001] Starting new tools node...
INFO[0002] Creating node 'k3d-new-server-0'
INFO[0002] Creating LoadBalancer 'k3d-new-serverlb'
INFO[0002] Starting node 'k3d-new-tools'
INFO[0003] Using the k3d-tools node to gather environment information
INFO[0005] HostIP: using network gateway 10.89.1.1 address
INFO[0005] Starting cluster 'new'
INFO[0005] Starting servers...
INFO[0007] Starting node 'k3d-new-server-0'

^C

20:53:05 ~/vfarcic/k3d-demo (master) $

20:53:11 ~/vfarcic/k3d-demo (master) $ k3d cluster list
NAME   SERVERS   AGENTS   LOADBALANCER
new    1/1       0/0      true

20:55:00 ~/vfarcic/k3d-demo (master) $ k3d kubeconfig get new
ERRO[0001] error getting loadbalancer config from k3d-new-serverlb: runtime failed to read loadbalancer config '/etc/confd/values.yaml' from node 'k3d-new-serverlb': Error response from daemon: no such file or directory: file not found
---
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUJkekNDQVIyZ0F3SUJBZ0lCQURBS0JnZ3Foa2pPUFFRREFqQWpNU0V3SHdZRFZRUUREQmhyTTNNdGMyVnkKZG1WeUxXTmhRREUzTkRFM01UZ3hNVGt3SGhjTk1qVXdNekV4TVRnek5URTVXaGNOTXpVd016QTVNVGd6TlRFNQpXakFqTVNFd0h3WURWUVFEREJock0zTXRjMlZ5ZG1WeUxXTmhRREUzTkRFM01UZ3hNVGt3V1RBVEJnY3Foa2pPClBRSUJCZ2dxaGtqT1BRTUJCd05DQUFUeS9vemtNcHJsZFhSc1FnNjV1K2s4djJSOGpwVDdvUVBQVVpCTEVaUm8KelFLR2NNZ01GVk1kR2N6dkVQcUxhaUVwb1VNOHBlMW8zM3loWnpXTTdFTDNvMEl3UURBT0JnTlZIUThCQWY4RQpCQU1DQXFRd0R3WURWUjBUQVFIL0JBVXdBd0VCL3pBZEJnTlZIUTRFRmdRVVljOHphZ1BMWkZINXMxNnd0OGE4CnFPWDJRMXd3Q2dZSUtvWkl6ajBFQXdJRFNBQXdSUUlnRDBPM1dWTG4weWh4MWh2WjdhQUcwcjVENDVkU2hQTjYKUU5HdE5hS05PbE1DSVFDa2xhRVNiQ1NZSnZxY1RxR3gxZS83OXJtVlZScUg1WXdwbThBd2psSnFkQT09Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
    server: https://0.0.0.0:46743
  name: k3d-new
contexts:
- context:
    cluster: k3d-new
    user: admin@k3d-new
  name: k3d-new
current-context: k3d-new
kind: Config
preferences: {}
users:
- name: admin@k3d-new
  user:
    client-certificate-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUJrRENDQVRlZ0F3SUJBZ0lJUXpVTjQ3eU5YWVV3Q2dZSUtvWkl6ajBFQXdJd0l6RWhNQjhHQTFVRUF3d1kKYXpOekxXTnNhV1Z1ZEMxallVQXhOelF4TnpFNE1URTVNQjRYRFRJMU1ETXhNVEU0TXpVeE9Wb1hEVEkyTURNeApNVEU0TXpVeE9Wb3dNREVYTUJVR0ExVUVDaE1PYzNsemRHVnRPbTFoYzNSbGNuTXhGVEFUQmdOVkJBTVRESE41CmMzUmxiVHBoWkcxcGJqQlpNQk1HQnlxR1NNNDlBZ0VHQ0NxR1NNNDlBd0VIQTBJQUJFTGFZVW5jc3ZXU1JyQi8KTEYzZ2tkSk9weGFUWlFhQjBOWnR2dzMxV0RmanU2Tmc2SDhjOFR2R0lRNmZtUHFDTEkzeW5Bb1ZlL0w5Q08yYwpQbklBQXJTalNEQkdNQTRHQTFVZER3RUIvd1FFQXdJRm9EQVRCZ05WSFNVRUREQUtCZ2dyQmdFRkJRY0RBakFmCkJnTlZIU01FR0RBV2dCU0JOc0VINGlSZ1c3eWFQNGxsQStDUzdjdEZvVEFLQmdncWhrak9QUVFEQWdOSEFEQkUKQWlCVEpJMnVwOWtNZHYwVEFENXVYN2VwOE9CTm9JdjQrSDMwUEJybE1zNUNUUUlnUFRwaUkxZ2VzcUY2QlZpYgp2OFdGY3pyNVpNanNOTDlDdkZ2cjI4YjhXaWc9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0KLS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUJlRENDQVIyZ0F3SUJBZ0lCQURBS0JnZ3Foa2pPUFFRREFqQWpNU0V3SHdZRFZRUUREQmhyTTNNdFkyeHAKWlc1MExXTmhRREUzTkRFM01UZ3hNVGt3SGhjTk1qVXdNekV4TVRnek5URTVXaGNOTXpVd016QTVNVGd6TlRFNQpXakFqTVNFd0h3WURWUVFEREJock0zTXRZMnhwWlc1MExXTmhRREUzTkRFM01UZ3hNVGt3V1RBVEJnY3Foa2pPClBRSUJCZ2dxaGtqT1BRTUJCd05DQUFRQlNqV1lLdTREL0dtc05sRXkxSnFnWTBlUUYxWE1JdHVDOFdYRlNjRHkKVUQrWUs1UXY1NWRFRDBGNGxqVmNlRWNkRWRMMDBFMjd2RDdZTkdOd1g2S2pvMEl3UURBT0JnTlZIUThCQWY4RQpCQU1DQXFRd0R3WURWUjBUQVFIL0JBVXdBd0VCL3pBZEJnTlZIUTRFRmdRVWdUYkJCK0lrWUZ1OG1qK0paUVBnCmt1M0xSYUV3Q2dZSUtvWkl6ajBFQXdJRFNRQXdSZ0loQU5ZWThXVitsYWh5Nm1FcEd5S3RVdVA5bVBkZEZBamUKUHU2MndLbmtxb2I0QWlFQWttZVlocmRkTnpqT2Z6dHZWSEE1aCtDV1ZRenpzb0JkRXd6SXN4WS9JSkk9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
    client-key-data: LS0tLS1CRUdJTiBFQyBQUklWQVRFIEtFWS0tLS0tCk1IY0NBUUVFSUlOQXZWRlFWclZjQWc1ZGd4eHJuR1ViZDkyUnludGlGT0h2cWxXWWdSd2hvQW9HQ0NxR1NNNDkKQXdFSG9VUURRZ0FFUXRwaFNkeXk5WkpHc0g4c1hlQ1IwazZuRnBObEJvSFExbTIvRGZWWU4rTzdvMkRvZnh6eApPOFloRHArWStvSXNqZktjQ2hWNzh2MEk3WncrY2dBQ3RBPT0KLS0tLS1FTkQgRUMgUFJJVkFURSBLRVktLS0tLQo=


####################################################
docker container ls

kubectl get pods -A

kubectl get nodes

################################
# Creating additional clusters #
################################

k3d cluster create another-cluster \
    --image rancher/k3s:v1.20.4-k3s1

docker container ls

#####################
# Deleting clusters #
#####################

k3d cluster delete my-cluster

k3d cluster delete another-cluster

#####################################
# Creating clusters through configs #
#####################################

git clone https://github.com/vfarcic/k3d-demo.git

cd k3d-demo

cat k3d.yaml

k3d cluster create --config k3d.yaml

kubectl get nodes

kubectl apply --filename k8s/

# Open http://localhost in a browser

#####################
# Deleting clusters #
#####################

k3d cluster delete my-cluster

###########################
# Speed test against kind #
###########################

docker system prune -a -f --volumes

k3d cluster create my-cluster

k3d cluster delete my-cluster

# Please watch https://youtu.be/C0v5gJSWuSo if you are not already familiar with kind
kind create cluster --name my-cluster

kind delete cluster --name my-cluster
