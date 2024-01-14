# 1. Introduction

## EKS Setup

### [Creating EKS cluster and node group with Terraform](https://github.com/Leapfrog-DevOps/eks-starter)

#### [Installing and configuring kubectl](https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html)
- Kubernetes Version: 1.25

> Code Referenced From: [Install Kubectl Script](./scripts/install_kubectl.sh)

```bash
#!/bin/bash

# NOTE: add your aws region and eks cluster name in the following variables
# example:
#   AWS_REGION=us-west-2
#   EKS_CLUSTER_NAME=your-eks-cluster-dev

# TODO: Support other CPU arch and platforms
# ARCH=amd64
# PLATFORM=

verify_checksum() {
  cd $INSTALL_DIRECTORY
  sha256sum -c $1 &>/dev/null|| (echo "Signature mismatch. The downloaded file is either corrupt or is a malware.") && return 1
  rm $1
  cd -
}

setup_aws_variables() {
  # set from environment variable or to us-east-1
  AWS_REGION=${AWS_REGION:-us-east-1}

  echo "Selected EKS region: $AWS_REGION"
  if [[ $EKS_CLUSTER_NAME == "" ]]; then
    echo "Error: EKS cluster name not provided"
    exit 1
  fi
  echo "Selected EKS cluster: $EKS_CLUSTER_NAME"
}

install_kubectl() {
  # download link for 64-bit Intel systems
  KUBECTL_BINARY_LINK=https://s3.us-west-2.amazonaws.com/amazon-eks/1.25.7/2023-03-17/bin/linux/amd64/kubectl
  KUBECTL_SIGNATURE_LINK="$KUBECTL_BINARY_LINK".sha256
  INSTALL_DIRECTORY=$HOME/bin/

  # download kubectl binary and signature
  echo "Installing kubectl"
  wget -P $INSTALL_DIRECTORY $KUBECTL_BINARY_LINK
  wget -P $INSTALL_DIRECTORY $KUBECTL_SIGNATURE_LINK

  # verify signature of the downloaded binary
  verify_checksum kubectl.sha256

  # configure permission and set up path
  chmod +x ./kubectl
  mkdir -p $INSTALL_DIRECTORY
  cp ./kubectl $INSTALL_DIRECTORY
  echo $PATH | grep $INSTALL_DIRECTORY || add_path_to_shellrc
}

add_path_to_shellrc() {
  if [ $SHELL == "/usr/bin/zsh" ]; then
    shellrc=~/.zshrc
  elif [ $SHELL == "/bin/bash" ]; then
    shellrc=~/.bashrc
  else
    echo "Could not determine the current shell."
    return
  fi
  echo "Adding $INSTALL_DIRECTORY to PATH in $shellrc"
  echo 'export PATH=$PATH':$INSTALL_DIRECTORY >> $shellrc

  # check kubectl version
  echo -e "kubectl version:\n"
  kubectl version --client
}

install_aws_cli() {
  AWS_CLI_LINK=https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip

  echo -e "Installing AWS CLI:\n"
  wget -O /tmp/awscliv2.zip $AWS_CLI_LINK
  cd /tmp/ && unzip awscliv2.zip && sudo ./aws/install --install-dir $INSTALL_DIRECTORY
}

configure_kubectl() {
  # configure kubectl to connect to AWS EKS cluster
  # skip this when invoking from Github Actions workflow
  aws eks --region $AWS_REGION update-kubeconfig --name $EKS_CLUSTER_NAME
}

main() {
  setup_aws_variables
  install_aws_cli

  # if kubectl already exists, skip installation
  kubectl version --client || install_kubectl

  configure_kubectl || exit 0
}

main

```

#### [Installing and updating eksctl](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html)

> Code Referenced From: [EKSCTL Installation Script](./scripts/install_eksctl.sh)

```bash
#!/bin/bash

# NOTE: add your architecture in ARCH variable
# for ARM systems, set ARCH to: `arm64`, `armv6` or `armv7`
# Example:
#   ARCH=armv7

ARCH=amd64

PLATFORM="$(uname -s)"_$ARCH
DOWNLOAD_DIRECTORY=/tmp/eksctl
INSTALL_DIRECTORY=$HOME/bin
FILE=eksctl_$PLATFORM.tar.gz

SIGNATURE_LINK="https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_checksums.txt"
FILE_LINK="https://github.com/weaveworks/eksctl/releases/latest/download/$FILE"

install() {
  mkdir -p $INSTALL_DIRECTORY $DOWNLOAD_DIRECTORY

  # download and verify checksum
  cd $DOWNLOAD_DIRECTORY
  wget $FILE_LINK
  wget $SIGNATURE_LINK >/dev/null
  (grep -i $PLATFORM eksctl_checksums.txt | sha256sum -c || echo "Signature mismatch. The downloaded file is either corrupt or is a malware.") || return 1

  # install and add directory to PATH
  tar -xzf $FILE -C $DOWNLOAD_DIRECTORY/ && rm $FILE
  sudo mv $DOWNLOAD_DIRECTORY/eksctl $INSTALL_DIRECTORY
  echo $PATH | grep $INSTALL_DIRECTORY || add_path_to_shellrc
  cd -
}

add_path_to_shellrc() {
  if [ $SHELL == "/usr/bin/zsh" ]; then
    shellrc=~/.zshrc
  elif [ $SHELL == "/bin/bash" ]; then
    shellrc=~/.bashrc
  else
    echo "Could not determine the current shell."
    return
  fi
  echo "Adding $INSTALL_DIRECTORY to PATH in $shellrc"
  echo 'export PATH=$PATH':$INSTALL_DIRECTORY >> $shellrc

  # check kubectl version
  echo -e "kubectl version:\n"
  kubectl version --client
}

main() {
  install
}

main

```

# 2. Security Considerations

## Internal TLS and encryption

### Configuring Cilium CNI

#### [Helm Installation](https://helm.sh/docs/intro/install/)

> Code Referenced From: [Helm Installation Script](./scripts/install_helm.sh)

```bash
#!/bin/bash

cd /tmp
curl -fsSL -o get_helm.sh
https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod +x get_helm.sh
./get_helm.sh
cd -

```

#### [Cilium Installation](https://docs.cilium.io/en/stable/installation/k8s-install-helm/#install-cilium)

> Code Referenced From: [Cilium Installation Script](./scripts/install_cilium.sh)

```bash
#!/bin/bash

helm repo add cilium https://helm.cilium.io/

helm install cilium cilium/cilium --version 1.13.2 \
--namespace kube-system \
--set eni.enabled=true \
--set ipam.mode=eni \
--set egressMasqueradeInterfaces=eth0 \
--set tunnel=disabled \
--set nodeinit.enabled=true \
--set encryption.enabled=true \
--set encryption.type=wireguard \
--set hubble.relay.enabled=true \
--set hubble.listenAddress=":4244" \
--set hubble.ui.enabled=true \
--set l7Proxy=false \
--set kubeProxyReplacement=strict \
--set k8sServiceHost=F016F90BF76075ACD9503A60D41F5749.gr7.us-east-1.eks.amazonaws.com \
--set k8sServicePort=443 \

```

#### Options

1. `--set eni.enabled=true`: This argument enables the use of Amazon Elastic
   Network Interfaces (ENIs) for pod networking.

2. `--set ipam.mode=eni`: This argument sets the IP address management (IPAM)
   mode to ENI, which enables Cilium to use ENIs for pod networking.

3. `--set egressMasqueradeInterfaces=eth0`: This argument specifies the network
   interface to be used for egress traffic masquerading. In this case, the
   interface is eth0.

4. `--set tunnel=disabled`: This argument disables the use of tunnels for network
   traffic between nodes.

5. `--set nodeinit.enabled=true`: This argument enables the Cilium Nodeinit
   daemonset, which sets up various network settings and creates a secure
   communication channel between nodes.

6. `--set encryption.enabled=true`: This argument enables the encryption of
   pod-to-pod traffic using WireGuard.

7. `--set encryption.type=wireguard`: This argument specifies the encryption
   protocol to be used for pod-to-pod traffic. In this case, the protocol is
   WireGuard.

8. `--set hubble.relay.enabled=true`: This argument enables the Hubble Relay, a
   component that collects network traffic data from all nodes in the cluster.

9. `--set hubble.listenAddress=":4244"`: This argument specifies the network
   address where the Hubble Relay listens for incoming connections. In this
   case, the address is :4244.

10. `--set hubble.ui.enabled=true`: This argument enables the Hubble UI, a
    web-based user interface for visualizing network traffic data.

11. `--set l7Proxy=false`: This argument disables the use of an L7 proxy for
    network traffic.

12. `--set kubeProxyReplacement=strict`: This argument enables strict enforcement
    of network policies at the application layer.

13. `--set k8sServiceHost=6075Agr7.us-east-2.eks.amazonaws.com`: This argument
    specifies the Kubernetes API server hostname.

14. `--set k8sServicePort=443:` This argument specifies the port number where the
    Kubernetes API server is listening. In this case, the port is 443.

With successful installation, you will get ouput similar to this screenshot:

![Successful Hubble Installation](https://github.com/pranavpudasaini/markdown/assets/23631617/011dfb69-b059-4658-8460-41c7b36055e8)

**To delete aws-node daemon set from namespace kube-system:**

```bash
kubectl -n kube-system delete daemonset aws-node
```
> Is this required here? Heading only, but no topic
- create node-groups now with terraform

### [Cilium CLI Tool Installation](https://docs.cilium.io/en/stable/installation/k8s-install-helm/#install-cilium)

> Code Referenced From: [Cilium CLI Installation Script](./scripts/install_cilium_cli.sh)

```bash
#!/bin/bash

CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/master/stable.txt)
CLI_ARCH=amd64

if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi

curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

cilium status --wait
cilium connectivity test
```

![Cilium Connectivity Test from CLI](https://github.com/pranavpudasaini/markdown/assets/23631617/c36be244-ad39-46bd-9a8f-84f6fc82e682)

---

#### Communication flows between Cilium, eBPF, nodes, clusters, and pods:

**1. Cilium Deployment:**

Cilium is deployed as a daemonset on each worker node in the EKS cluster. It
runs as a Kubernetes agent responsible for managing networking and security
policies.

**2. eBPF Integration:**

Cilium utilizes eBPF programs to interact with
the Linux kernel and perform efficient packet processing and
filtering operations at the network layer.

**3. Node-level Communication:**

Each node in the EKS cluster runs
Cilium with eBPF, allowing it to intercept and handle network
traffic at the kernel level. This includes processing packets,
enforcing policies, and applying network-related operations.

**4. Cluster-level Communication:**

Cilium enables secure communication between pods across nodes within the EKS
cluster by leveraging eBPF. It implements a distributed firewall that enforces
network policies, ensuring that only allowed traffic is allowed to flow between
pods.

**5. Pod Communication:**

When a pod within the EKS cluster sends or receives network traffic, Cilium,
through eBPF, intercepts and processes the packets at the kernel level. It
enforces network policies, performs network address translation (NAT), and
applies other relevant operations before forwarding the packets to their
intended destinations.

> TODO: Revisit the header here

### [Pod-level network and security rules](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

**Problem:**

- Define network policies at the pod level, specifying ingress and egress rules based on various criteria such as pod labels, namespaces, or IP addresses
- Use network policy implementation like Calico or Cilium

**Example Solution:**

> Config Referenced From: [Allow App Traffic Example](./1_security_considerations/security_rules/allow_app_traffic_example.yaml)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-app-traffic
spec:
  podSelector:
    matchLabels:
      app: my-app
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: my-app
    ports:
    - protocol: TCP
      port: 80
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: my-app
    ports:
    - protocol: TCP
      port: 80
```


In this example, the Network Policy is named `allow-app-traffic` and applies to
Pods with the label `app: my-app`. The policy allows incoming traffic on port
80 from other Pods with the same label, and also allows outgoing traffic to
other Pods with the same label.

Note that in order for this Network Policy to take effect, your Kubernetes
cluster **must have a networking plugin**  installed that **supports Network Policies**,
such as Calico or Weave Net.

> Config Referenced From: [Default Deny Ingress Example](./1_security_considerations/security_rules/default_deny_ingress.yaml)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```

---

### RBAC to control access to resources

#### Admin access

> Code Referenced From: [./scripts/admin_access_example.sh](./scripts/admin_access_example.sh)

```bash
# needs admin access
# test your identity with aws sts
aws sts get-caller-identity

# edit the aws-auth configmap
kubectl edit -n kube-system configmap/aws-auth 

# under mapusers
mapUsers: |
  # map user IAM user Alice in 000000000000 to user "alice" in group "system:masters"
  - userarn: arn:aws:iam::000000000000:user/Alice
    username: alice
    groups:
    - system:masters
```

> Config Referenced From: [Custom Role Example](./1_security_considerations/rbac/custom_role_example.yaml)

> TODO: Refactor and test, a combination of tabs and spaces are in the referenced file


```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deployment-role
  namespace: default
rules:
  - apiGroups:
  	- ""
  	- extensions
  	- apps
	resources:
  	- deployments
  	- replicasets
  	- pods
	verbs:
  	- create
  	- get
  	- list
  	- update
  	- delete
  	- watch
  	- patch  
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: deployment-rolebinding
  namespace: default
roleRef:
  apiGroup: ""
  kind: Role
  name: deployment-role
subjects:
  - kind: User
	name: bibek
	apiGroup: ""

```

> Code Referenced From: [./scripts/after_custom_apply_role.sh](./scripts/after_custom_apply_role.sh)

```bash
#edit aws-auth
kubectl edit -n kube-system configmap/aws-auth
mapUsers: |
  # map user IAM user Alice in 000000000000 to user "alice" in group "system:masters"
  - userarn: arn:aws:iam::000000000000:user/Alice
    username: bibek
    groups:
    - deployment-role
```

---

### Deployment restrictions to specific node groups

> Config Referenced From: [Named Node](./1_security_considerations/deployment_restriction_to_specific_node_groups/nodeName.yaml)

```yaml
apiVersion: v1
kind: Pod
metadata:
 name: nginx
spec:
 containers:
 - name: nginx
   image: nginx
 nodeName: kube-01
```

#### Limitations:

**If the named node does not exist:**

- the Pod will not run (gets automatically deleted).
- have the resources to accommodate the Pod, the Pod will fail indicating the reason, for example `OutOfMemory` or `OutOfCpu`.
- Node names in cloud environments are not always predictable or stable.

### [Affinity and anti-affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)

`podAffinity` or `podAntiAffinity` with
`preferredDuringSchedulingIgnoredDuringExecution` expresses a preferred
preference, allowing some flexibility in scheduling decisions.

On the other hand, combining them with
`requiredDuringSchedulingIgnoredDuringExecution` indicates a strict
requirement, enforcing the scheduling decision based on affinity or
anti-affinity rules.

> Config Referenced From: [Pod Affinity Example](./1_security_considerations/deployment_restriction_to_specific_node_groups/podAffinity_example.yaml)
> TODO: Indentation is incorrect for `topologyKey` in the referenced file
> TODO: Replace this with a tested YAML file

```yaml
apiVersion: v1
kind: Pod
metadata:
 name: with-pod-affinity
spec:
 affinity:
   podAffinity:
     requiredDuringSchedulingIgnoredDuringExecution:
     - labelSelector:
         matchExpressions:
         - key: security
           operator: In
           values:
           - S1
       topologyKey: topology.kubernetes.io/zone
   podAntiAffinity:
     preferredDuringSchedulingIgnoredDuringExecution:
     - weight: 100
       podAffinityTerm:
         labelSelector:
           matchExpressions:
           - key: security
             operator: In
             values:
             - S2
      topologyKey: topology.kubernetes.io/zone
 containers:
 - name: with-pod-affinity
   image: registry.k8s.io/pause:2.0
```

> Note: Config Referenced From: [Node Affinity Example](./1_security_considerations/deployment_restriction_to_specific_node_groups/nodeAffinity_example.yaml)

```yaml
apiVersion: v1
kind: Pod
metadata:
 name: with-node-affinity
spec:
 affinity:
   nodeAffinity:
     requiredDuringSchedulingIgnoredDuringExecution:
       nodeSelectorTerms:
       - matchExpressions:
         - key: topology.kubernetes.io/zone
           operator: In
           values:
           - antarctica-east1
           - antarctica-west1
     preferredDuringSchedulingIgnoredDuringExecution:
     - weight: 1
       preference:
         matchExpressions:
         - key: another-node-label-key
           operator: In
           values:
           - another-node-label-value
 containers:
 - name: with-node-affinity
   image: registry.k8s.io/pause:2.0
```

> Config Referenced From: [Self Managed Node Join](./2_customization/self_managed_node_join_example.yaml)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: <YOUR_NODE_INSTANCE_ROLE_ARN>
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes

```

```bash
kubectl apply -f self-managed.yaml
```

### EKS Managed and Self Managed Node Groups

- [AWS EKS Managed node group](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html)
- [Self Managed Node Group](https://docs.aws.amazon.com/eks/latest/userguide/worker.html)


---

# 3. Scalability

## Cluster AutoScaler

- [https://aws.github.io/aws-eks-best-practices/cluster-autoscaling/](https://aws.github.io/aws-eks-best-practices/cluster-autoscaling/)
- [https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md)
- [https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler/cloudprovider/aws/examples](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler/cloudprovider/aws/examples)

```bash
eksctl create iamserviceaccount --cluster=k8s-may-12-eks-staging --namespace=kube-system \
--name=cluster-autoscaler --attach-policy-arn=arn:aws:iam::aws:policy/AutoScalingFullAccess \
--override-existing-serviceaccounts --approve --region=us-east-1
```

> Config Referenced From: [Cluster Autoscaler Example](./3_scalability/cluster_auto_scaler_example.yaml)

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-autoscaler
  labels:
    k8s-addon: cluster-autoscaler.addons.k8s.io
    k8s-app: cluster-autoscaler
rules:
  - apiGroups: [""]
    resources: ["events", "endpoints"]
    verbs: ["create", "patch"]
  - apiGroups: [""]
    resources: ["pods/eviction"]
    verbs: ["create"]
  - apiGroups: [""]
    resources: ["pods/status"]
    verbs: ["update"]
  - apiGroups: [""]
    resources: ["endpoints"]
    resourceNames: ["cluster-autoscaler"]
    verbs: ["get", "update"]
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["watch", "list", "get", "update"]
  - apiGroups: [""]
    resources:
      - "namespaces"
      - "pods"
      - "services"
      - "replicationcontrollers"
      - "persistentvolumeclaims"
      - "persistentvolumes"
    verbs: ["watch", "list", "get"]
  - apiGroups: ["extensions"]
    resources: ["replicasets", "daemonsets"]
    verbs: ["watch", "list", "get"]
  - apiGroups: ["policy"]
    resources: ["poddisruptionbudgets"]
    verbs: ["watch", "list"]
  - apiGroups: ["apps"]
    resources: ["statefulsets", "replicasets", "daemonsets"]
    verbs: ["watch", "list", "get"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses", "csinodes", "csidrivers", "csistoragecapacities"]
    verbs: ["watch", "list", "get"]
  - apiGroups: ["batch", "extensions"]
    resources: ["jobs"]
    verbs: ["get", "list", "watch", "patch"]
  - apiGroups: ["coordination.k8s.io"]
    resources: ["leases"]
    verbs: ["create"]
  - apiGroups: ["coordination.k8s.io"]
    resourceNames: ["cluster-autoscaler"]
    resources: ["leases"]
    verbs: ["get", "update"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: cluster-autoscaler
  namespace: kube-system
  labels:
    k8s-addon: cluster-autoscaler.addons.k8s.io
    k8s-app: cluster-autoscaler
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["create","list","watch"]
  - apiGroups: [""]
    resources: ["configmaps"]
    resourceNames: ["cluster-autoscaler-status", "cluster-autoscaler-priority-expander"]
    verbs: ["delete", "get", "update", "watch"]

---

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-autoscaler
  labels:
    k8s-addon: cluster-autoscaler.addons.k8s.io
    k8s-app: cluster-autoscaler
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-autoscaler
subjects:
  - kind: ServiceAccount
    name: cluster-autoscaler
    namespace: kube-system

---

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: cluster-autoscaler
  namespace: kube-system
  labels:
    k8s-addon: cluster-autoscaler.addons.k8s.io
    k8s-app: cluster-autoscaler
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: cluster-autoscaler
subjects:
  - kind: ServiceAccount
    name: cluster-autoscaler
    namespace: kube-system

---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: cluster-autoscaler
  namespace: kube-system
  labels:
    app: cluster-autoscaler
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cluster-autoscaler
  template:
    metadata:
      labels:
        app: cluster-autoscaler
      annotations:
        prometheus.io/scrape: 'true'
        prometheus.io/port: '8085'
    spec:
      priorityClassName: system-cluster-critical
      securityContext:
        runAsNonRoot: true
        runAsUser: 65534
        fsGroup: 65534
      serviceAccountName: cluster-autoscaler
      containers:
        - image: registry.k8s.io/autoscaling/cluster-autoscaler:v1.22.2
          name: cluster-autoscaler
          resources:
            limits:
              cpu: 100m
              memory: 600Mi
            requests:
              cpu: 100m
              memory: 600Mi
          command:
            - ./cluster-autoscaler
            - --v=4
            - --stderrthreshold=info
            - --cloud-provider=aws
            - --skip-nodes-with-local-storage=false
            - --expander=least-waste
            - --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/evoke-eks-evoke
          volumeMounts:
            - name: ssl-certs
              mountPath: /etc/ssl/certs/ca-certificates.crt #/etc/ssl/certs/ca-bundle.crt for Amazon Linux Worker Nodes
              readOnly: true
          imagePullPolicy: "Always"
      volumes:
        - name: ssl-certs
          hostPath:
            path: "/etc/ssl/certs/ca-bundle.crt"
```

| Parameter                      | Description                                                                                | Default       |
|--------------------------------|--------------------------------------------------------------------------------------------|---------------|
| scan-interval                  | How often cluster is reevaluated for scale up or down                                      | 10 seconds    |
| max-empty-bulk-delete          | Maximum number of empty nodes that can be deleted at the same time                         | 10 ?          |
| scale-down-delay-after-add     | How long after scale up that scale down evaluation resumes                                 | 10 minutes    |
| scale-down-delay-after-delete  | How long after node deletion that scale down evaluation resumes, defaults to scan-interval | scan-interval |
| scale-down-delay-after-failure | How long after scale down failure that scale down evaluation resumes                       | 3 minutes     |

### Pod Autoscaler Documentation

- [Horizonal Pod Autoscale](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Horizonal Pod Autoscale Walkthrough](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/)

### [Metrics Server](https://github.com/kubernetes-sigs/metrics-server#deployment)

#### Metrics Server offers:

- A single deployment that works on most clusters (see Requirements)
- Fast autoscaling, collecting metrics every 15 seconds.
- Resource efficiency, using 1 mili core of CPU and 2 MB of memory for each node in a cluster.
- Scalable support up to 5,000 node clusters.

> Code Referenced From: [Deploy Metrics Server Script](./scripts/before_metrics_server.sh)

```bash
# deploy metrics server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/high-availability-1.21+.yaml
wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/high-availability-1.21+.yaml

# example to apply php-apache
kubectl apply -f https://k8s.io/examples/application/php-apache.yaml
# create hpa via kubectl command
kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=10
```

> Config Referenced From: [Pod Autoscaler Example](./3_scalability/pod_auto_scaler_example.yaml)

```yaml
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: php-apache
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: php-apache
  minReplicas: 1
  maxReplicas: 10
  targetCPUUtilizationPercentage: 50
```

> Code Referenced From: [Deploy Metrics Server Script](./scripts/after_metrics_server.sh)

Run this in a separate terminal so that the load generation continues and you can carry on with the rest of the steps:

```bash
kubectl run -i --tty load-generator --rm --image=busybox:1.28 --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://php-apache; done"
```

1. **Metric Collection Interval**: The HPA collects metrics at regular
   intervals to assess the resource utilization of the pods. By default, the
   metrics collection interval is 30 seconds. However, you can configure a
   different interval by setting the --horizontal-pod-autoscaler-sync-period
   flag on the Kubernetes controller manager.

2. **Scaling Stabilization Window**: After each scaling action, the HPA waits
   for a stabilization window before making further scaling decisions. The
   default stabilization window is 5 minutes (300 seconds). During this window,
   the HPA observes the impact of the previous scaling action on the resource
   utilization and allows time for the new replicas to stabilize. This prevents
   rapid, unnecessary scaling actions in response to short-lived spikes in
   resource utilization.

```bash
kg hpa --watch
kg rs --watch
kgp --watch
```

---

> TODO: Revisit this with Bipin or Bibek

# 4. ELK

- [https://www.shebanglabs.io/logging-with-efk-on-aws-eks/](https://www.shebanglabs.io/logging-with-efk-on-aws-eks/)
- [https://www.elastic.co/guide/en/cloud-on-k8s/master/k8s-deploy-eck.html](https://www.elastic.co/guide/en/cloud-on-k8s/master/k8s-deploy-eck.html)

> Config Referenced From: [ELK IAM Policy](./scripts/elk_iam_policy.json)

```json
{
  "version": "2012-10-17",
  "statement": [
    {
      "effect": "allow",
      "action": [
        "iam:createservicelinkedrole",
        "ec2:describeaccountattributes",
        "ec2:describeaddresses",
        "ec2:describeavailabilityzones",
        "ec2:describeinternetgateways",
        "ec2:describevpcs",
        "ec2:describesubnets",
        "ec2:describesecuritygroups",
        "ec2:describeinstances",
        "ec2:describenetworkinterfaces",
        "ec2:describetags",
        "ec2:getcoippoolusage",
        "ec2:describecoippools",
        "elasticloadbalancing:describeloadbalancers",
        "elasticloadbalancing:describeloadbalancerattributes",
        "elasticloadbalancing:describelisteners",
        "elasticloadbalancing:describelistenercertificates",
        "elasticloadbalancing:describesslpolicies",
        "elasticloadbalancing:describerules",
        "elasticloadbalancing:describetargetgroups",
        "elasticloadbalancing:describetargetgroupattributes",
        "elasticloadbalancing:describetargethealth",
        "elasticloadbalancing:describetags"
      ],
      "resource": "*"
    },
    {
      "effect": "allow",
      "action": [
        "cognito-idp:describeuserpoolclient",
        "acm:listcertificates",
        "acm:describecertificate",
        "iam:listservercertificates",
        "iam:getservercertificate",
        "waf-regional:getwebacl",
        "waf-regional:getwebaclforresource",
        "waf-regional:associatewebacl",
        "waf-regional:disassociatewebacl",
        "wafv2:getwebacl",
        "wafv2:getwebaclforresource",
        "wafv2:associatewebacl",
        "wafv2:disassociatewebacl",
        "shield:getsubscriptionstate",
        "shield:describeprotection",
        "shield:createprotection",
        "shield:deleteprotection"
      ],
      "resource": "*"
    },
    {
      "effect": "allow",
      "action": [
        "ec2:authorizesecuritygroupingress",
        "ec2:revokesecuritygroupingress"
      ],
      "resource": "*"
    },
    {
      "effect": "allow",
      "action": [
        "ec2:createsecuritygroup"
      ],
      "resource": "*"
    },
    {
      "effect": "allow",
      "action": [
        "ec2:createtags"
      ],
      "resource": "arn:aws:ec2:*:*:security-group/*",
      "condition": {
        "stringequals": {
          "ec2:createaction": "createsecuritygroup"
        },
        "null": {
          "aws:requesttag/elbv2.k8s.aws/cluster": "false"
        }
      }
    },
    {
      "effect": "allow",
      "action": [
        "ec2:createtags",
        "ec2:deletetags"
      ],
      "resource": "arn:aws:ec2:*:*:security-group/*",
      "condition": {
        "null": {
          "aws:requesttag/elbv2.k8s.aws/cluster": "true",
          "aws:resourcetag/elbv2.k8s.aws/cluster": "false"
        }
      }
    },
    {
      "effect": "allow",
      "action": [
        "ec2:authorizesecuritygroupingress",
        "ec2:revokesecuritygroupingress",
        "ec2:deletesecuritygroup"
      ],
      "resource": "*",
      "condition": {
        "null": {
          "aws:resourcetag/elbv2.k8s.aws/cluster": "false"
        }
      }
    },
    {
      "effect": "allow",
      "action": [
        "elasticloadbalancing:createloadbalancer",
        "elasticloadbalancing:createtargetgroup"
      ],
      "resource": "*",
      "condition": {
        "null": {
          "aws:requesttag/elbv2.k8s.aws/cluster": "false"
        }
      }
    },
    {
      "effect": "allow",
      "action": [
        "elasticloadbalancing:createlistener",
        "elasticloadbalancing:deletelistener",
        "elasticloadbalancing:createrule",
        "elasticloadbalancing:deleterule"
      ],
      "resource": "*"
    },
    {
      "effect": "allow",
      "action": [
        "elasticloadbalancing:addtags",
        "elasticloadbalancing:removetags"
      ],
      "resource": [
        "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
        "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
        "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
      ],
      "condition": {
        "null": {
          "aws:requesttag/elbv2.k8s.aws/cluster": "true",
          "aws:resourcetag/elbv2.k8s.aws/cluster": "false"
        }
      }
    },
    {
      "effect": "allow",
      "action": [
        "elasticloadbalancing:addtags",
        "elasticloadbalancing:removetags"
      ],
      "resource": [
        "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
        "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
        "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
        "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
      ]
    },
    {
      "effect": "allow",
      "action": [
        "elasticloadbalancing:modifyloadbalancerattributes",
        "elasticloadbalancing:setipaddresstype",
        "elasticloadbalancing:setsecuritygroups",
        "elasticloadbalancing:setsubnets",
        "elasticloadbalancing:deleteloadbalancer",
        "elasticloadbalancing:modifytargetgroup",
        "elasticloadbalancing:modifytargetgroupattributes",
        "elasticloadbalancing:deletetargetgroup"
      ],
      "resource": "*",
      "condition": {
        "null": {
          "aws:resourcetag/elbv2.k8s.aws/cluster": "false"
        }
      }
    },
    {
      "effect": "allow",
      "action": [
        "elasticloadbalancing:registertargets",
        "elasticloadbalancing:deregistertargets"
      ],
      "resource": "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
    },
    {
      "effect": "allow",
      "action": [
        "elasticloadbalancing:setwebacl",
        "elasticloadbalancing:modifylistener",
        "elasticloadbalancing:addlistenercertificates",
        "elasticloadbalancing:removelistenercertificates",
        "elasticloadbalancing:modifyrule"
      ],
      "resource": "*"
    }
  ]
}
```

> Code Referenced From: [ELK Script](./scripts/elk_script.sh)

```bash
### If you have not done it before:
$ eksctl utils associate-iam-oidc-provider --region us-east-1 --cluster k8s-may-12-eks-staging --approve

### create SA for ebs-csi
$ eksctl create iamserviceaccount --cluster k8s-may-12-eks-staging --namespace kube-system --name ebs-csi-controller-sa --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy --override-existing-serviceaccounts --approve --region us-east-1

### Get the latest version of aws-ebs
$ aws eks describe-addon-versions --addon-name aws-ebs-csi-driver --region us-east-1 | grep v1

### Get the arn of the role:
$ kg sa ebs-csi-controller-sa -o yaml -n kube-system

### Use the above arn in below command:
$ eksctl create addon --name aws-ebs-csi-driver --cluster k8s-may-12-eks-staging --service-account-role-arn arn:aws:iam::949263681218:role/eksctl-k8s-may-12-eks-staging-addon-iamservi-Role1-78BGKDW9RMP5 --region us-east-1 --force

### If you want to update or get the information of addons
$ eksctl get addon --name aws-ebs-csi-driver --cluster k8s-may-12-eks-staging
$ eksctl update addon --name aws-ebs-csi-driver --version v1.11.4-eksbuild.1 --cluster k8s-may-12-eks-staging --force

# If there are other storage classes which are created by default, edit it and make it false as default.
k edit sc
```

```bash
# create Service Account (SA)
eksctl create iamserviceaccount --cluster k8s-may-12-eks-staging --namespace kube-system --name ebs-csi-controller-sa --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy --override-existing-serviceaccounts --approve --region us-east-1

# create a load balancer controller SA
helm repo add eks https://aws.github.io/eks-charts
helm repo update
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n aws-alb --set clusterName=k8s-may-12-eks-staging --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller --set region=us-east-1 --set vpcId=vpc-0a26e7b899f09b784

# get the latest version of addon:
aws eks describe-addon-versions --addon-name aws-ebs-csi-driver --region us-east-1 | grep v1

# get the arn of the role and use it to create addon
kg sa ebs-csi-controller-sa -o yaml -n kube-system
eksctl create addon --name aws-ebs-csi-driver --cluster k8s-may-12-eks-staging --service-account-role-arn arn:aws:iam::949263681218:role/eksctl-k8s-may-12-eks-staging-addon-iamservi-Role1-78BGKDW9RMP5 --region us-east-1 --force

# if you want to update or get the information of addons
eksctl get addon --name aws-ebs-csi-driver --cluster k8s-may-12-eks-staging
eksctl update addon --name aws-ebs-csi-driver --version v1.11.4-eksbuild.1 --cluster k8s-may-12-eks-staging --force

# create CIDR and necessary operators following the official documentation:
kubectl create -f https://download.elastic.co/downloads/eck/2.8.0/crds.yaml

# install the operator with its RBAC rules:
kubectl apply -f https://download.elastic.co/downloads/eck/2.8.0/operator.yaml
```

**Optional**:

1. Monitor the operator logs:

```bash
kubectl -n elastic-system logs -f statefulset.apps/elastic-operator
```

> TODO: could not quite get the context here
> TODO: reference from file, indentation is :gg:

```yaml
# If there are other storage classes which are created by default, edit it and make it false as default. k edit sc

kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:

annotations:

storageclass.kubernetes.io/is-default-class: "true"

name: ebs-sc

provisioner: ebs.csi.aws.com
parameters:
type: gp2
encrypted: 'true'

volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete

kubectl apply -f storage_class.yaml
```

### Using an Init Container to set virtual memory

To add an init container that changes the host kernel setting before your
Elasticsearch container starts, you can use the following example Elasticsearch
spec:

> TODO: fix indentation and reference from file

```bash
cat <<EOF | kubectl apply -f -
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:

name: quickstart

spec:

version: 8.8.0
nodeSets:
- name: default

count: 3
podTemplate:

spec:

initContainers:
- name: sysctl

securityContext:

privileged: true
runAsUser: 0

command: ['sh', '-c', 'sysctl -w

vm.max_map_count=262144']

EOF
```

### Monitor cluster health and creation progress

> TODO: clarify the situation here

```bash
kubectl get elasticsearch

# TODO: ?
# one pod is in the process of being started:

kubectl get pods --selector='elasticsearch.k8s.elastic.co/cluster-name=quickstart'

### Request Elasticsearch access

A ClusterIP Service is automatically created for your cluster:

```bash
kubectl get service quickstart-es-http
```

**Note:**

- Username is `elastic`
- Obtain password with with: `kubectl get secret quickstart-es-elastic-user -o=jsonpath='{.data.elastic}' | base64 --decode; echo`
- Access Elasticsearch with: `kubectl port-forward service/quickstart-es-http --address 0.0.0.0 9200:9200`

### Logging in to the elastic search

> TODO: are these different commands?

```bash
kg secret
PASSWORD=$(kubectl get secret elasticsearch-es-elastic-user -o go-template='{{.data.elastic | base64decode}}')
echo $PASSWORD
```

#### You can now access Elasticsearch from the network load balancer DNS on port 9200.

### Kibana

> TODO: fix indentation and reference from file

```bash
cat <<EOF | kubectl apply -f -
apiVersion: kibana.k8s.elastic.co/v1
kind: Kibana
metadata:

name: kibana

spec:

version: 8.8.0
count: 1
elasticsearchRef:

name: elasticsearch

EOF

kubectl get kibana

kubectl get pod --selector='kibana.k8s.elastic.co/name=quickstart'

kubectl port-forward service/quickstart-kb-http --address 0.0.0.0 5601:5601
```

**Note:** Passwords for Elasticsearch and Kibana are the same

### FluentD

**Config file:**

```yaml
```

> TODO: XML syntax inside the above yaml?

**Fluentd.yaml:**

> TODO: why is there another config for fluentd?

```yaml
```

> TODO: determine the level of this topic

> Login to kibana and manage index pattern, logs everything 😄

Prometeous-Grafana

```bash
## Define public Kubernetes chart repository in the Helm configuration
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

## Update local repositories
helm repo update

## Search for newly installed repositories
helm repo list

## Create a namespace for Prometheus and Grafana resources
kubectl create ns prometheus

## Install Prometheus using HELM
helm install prometheus prometheus-community/kube-prometheus-stack -n prometheus

## Check all resources in Prometheus Namespace
kubectl get all -n prometheus

## check helm manifest
helm get manifest prometheus -n prometheus

## Port forward the Prometheus service
kubectl port-forward -n prometheus svc/prometheus-operated --address 0.0.0.0 9090:9090

## Get the Username
kubectl get secret -n prometheus prometheus-grafana -o=jsonpath='{.data.admin-user}' |base64 -d

## Get the Password
kubectl get secret -n prometheus prometheus-grafana -o=jsonpath='{.data.admin-password}' |base64 -d

## Port forward the Grafana service
kubectl port-forward -n prometheus svc/prometheus-grafana 3000:80
```

> TODO: add code from file

**To add smtp details:**

```bash
k edit deploy prometheus-grafana -n prometheus

# add environment variables:

```

> TODO: understand the context here?

```bash
cilium status

export HUBBLE_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt)
HUBBLE_ARCH=amd64

if [ "$(uname -m)" = "aarch64" ]; then HUBBLE_ARCH=arm64; fi

curl -L --fail --remote-name-all https://github.com/cilium/hubble/releases/download/$HUBBLE_VERSION/hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}
sha256sum --check hubble-linux-${HUBBLE_ARCH}.tar.gz.sha256sum
sudo tar xzvfC hubble-linux-${HUBBLE_ARCH}.tar.gz /usr/local/bin
rm hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}

hubble status
hubble observe
cilium hubble ui

kg svc -n kube-system
k port-forward --address 0.0.0.0 svc/hubble-ui -n kube-system 12000:80
```

> TODO: What is this section?

> Roughs

To give access to non-AWS User to view pods

To give a non-AWS IAM user access to view pods in an AWS EKS cluster, you can use the
Kubernetes Role-Based Access Control (RBAC) mechanism to create a user and grant
appropriate permissions. Here are the steps to achieve this:

1. Create a Kubernetes ServiceAccount: Create a YAML manifest file, let's name it

user-view-pods.yaml, with the following content:

yaml
apiVersion: v1
kind: ServiceAccount
metadata:

name: non-aws-user

Apply the manifest using the kubectl apply command:

sql
kubectl apply -f user-view-pods.yaml

2. Create a ClusterRole: Create another YAML manifest file, let's name it

user-view-pods-role.yaml, with the following content:

yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:

name: view-pods-role

rules:
- apiGroups: [""]

resources: ["pods"]
verbs: ["get", "list", "watch"]

Apply the manifest using the kubectl apply command:

sql
kubectl apply -f user-view-pods-role.yaml

3. Bind the ServiceAccount and ClusterRole: Create a YAML manifest file, let's name it

user-view-pods-binding.yaml, with the following content:

yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:

name: view-pods-binding

roleRef:

apiGroup: rbac.authorization.k8s.io
kind: ClusterRole
name: view-pods-role

subjects:
- kind: ServiceAccount
name: non-aws-user
namespace: default

Apply the manifest using the kubectl apply command:

sql
kubectl apply -f user-view-pods-binding.yaml

4. Obtain the ServiceAccount Token: Get the token associated with the ServiceAccount

using the following command:

sql
kubectl get secret $(kubectl get sa non-aws-user -o
jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64
--decode

Make a note of the token value. This will be used to authenticate the non-AWS IAM user.

5. Provide the token to the non-AWS IAM user: Share the token with the non-AWS IAM
user, along with the cluster endpoint URL. The user can use these credentials to
access the EKS cluster and view pods using the kubectl command-line tool or other
Kubernetes clients.

Note: Providing a non-AWS IAM user access to an EKS cluster introduces potential security
risks. Ensure you carefully manage the user's permissions and revoke access when it's no
longer needed.

By following these steps, you can grant a non-AWS IAM user the ability to view pods in an
AWS EKS cluster using RBAC.

Certainly! Here's an example of a config file that you can provide to the non-AWS IAM user,
including the token:

yaml
apiVersion: v1
clusters:
- cluster:

server: <CLUSTER_ENDPOINT_URL>
certificate-authority-data: <CLUSTER_CA_CERTIFICATE>

name: my-eks-cluster

contexts:
- context:

cluster: my-eks-cluster
user: non-aws-user
name: my-eks-context

current-context: my-eks-context
kind: Config
preferences: {}
users:
- name: non-aws-user

user:

token: <TOKEN_VALUE>

Instructions:

1. Replace <CLUSTER_ENDPOINT_URL> with the actual endpoint URL of your EKS

cluster. This should be the value you share with the user.

2. Replace <CLUSTER_CA_CERTIFICATE> with the CA certificate data for your EKS

cluster. You can obtain this by running the following command:
css

kubectl config view --raw --minify --flatten -o
jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64
--decode

1.
2. Replace <TOKEN_VALUE> with the actual token value obtained in Step 4.

Provide this YAML config file to the non-AWS IAM user. They can use it with the kubectl
command-line tool or other Kubernetes clients by setting the KUBECONFIG environment
variable to point to this file.

Example command to set the KUBECONFIG environment variable:

javascript
export KUBECONFIG=/path/to/eks-config.yaml

Please ensure that you have securely shared the config file and token with the user, as this
grants them access to your EKS cluster.

To create NLB Load Balancer of ElasticSearch Service.

kg svc elasticsearch-es-http -o yaml > elastic_svc.yaml

Edit the elastic_svc.yaml and format it according to this example for converting this service
into Network Loadbalacer

# Please edit the object below. Lines beginning with a '#' will be ignored,
# and an empty file will abort the edit. If an error occurs while saving this file
will be
# reopened with the relevant failures.
#
apiVersion: v1
kind: Service
metadata:

annotations:

service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags:

name=eks-access,creator=bibekmishra,project=may-12

service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: instance
service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
service.beta.kubernetes.io/aws-load-balancer-subnets:

subnet-0723147f090d3f9fa,subnet-05b82cb6119dc7373

service.beta.kubernetes.io/aws-load-balancer-type: external

labels:

app: wazuh-manager

name: wazuh
namespace: wazuh

spec:

externalTrafficPolicy: Cluster
internalTrafficPolicy: Cluster
ipFamilies:
- IPv4
ipFamilyPolicy: SingleStack
ports:
- name: registration

port: 1515

protocol: TCP
targetPort: 1515

- name: api

port: 55000
protocol: TCP
targetPort: 55000

selector:

app: wazuh-manager
node-type: master
sessionAffinity: None
type: LoadBalancer
loadBalancerClass: service.k8s.aws/nlb

status:

loadBalancer: {}

Add the annotation and update it according to your requirements, tags and name.



