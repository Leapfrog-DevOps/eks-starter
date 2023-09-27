# Install kubectl
[kubectl_install](./kubectl_install)

# Install eksctl
[eksctl_install](./eksctl_install)


### Guide lines to follow in detail
1. [***Security Considerations***](./1_security_considerations)
   -  [**Install Cilium**](./1_security_considerations/cilium_cni)
   - [**Security Rules Examples**](./1_security_considerations/security_rules)
     - [default_deny_ingress.yaml](./1_security_considerations/security_rules/default_deny_ingress.yaml)
     - [allow_app_trrafic.yaml](./1_security_considerations/security_rules/allow_app_traffic_example.yaml)
   - [**RBAC Examples**](./1_security_considerations/rbac)
     - [admin access](./1_security_considerations/rbac/admin_access_example)
     - [create custom Role](./1_security_considerations/rbac/custom_role_example.yaml)
     - [edit aws-auth](./1_security_considerations/rbac/after_custom_role_apply)
   - [**Deployment Restrictions Examples**](./1_security_considerations/deployment_restriction_to_specific_node_groups)
     - [nodeName.yaml](./1_security_considerations/deployment_restriction_to_specific_node_groups/nodeName.yaml)
     - [nodeAffinity.yaml](./1_security_considerations/deployment_restriction_to_specific_node_groups/nodeAffinity_example.yaml)
     - [podAffinity.yaml](./1_security_considerations/deployment_restriction_to_specific_node_groups/podAffinity_example.yaml)
2. [***Customizations Examples***](./2_customization)
   - [eksctl command](./2_customization/eksctl_create_managed_node_group)
   - [join self managed node](./2_customization/self_managed_node_join_example.yaml)
   - [launch template](../modules/common/eks/launch_template.tf)
   - [master node customization](../modules/common/eks/eks-cluster.tf)
   - [node groups customization](../modules/common/eks/node_group.tf)
3. [***Scalability Examples***](./3_scalability)
   - [cluster auto scaler (Node Scalability)](./3_scalability/cluster_auto_scaler_example.yaml)
   - [HPA (Pod Scalability)](./3_scalability/pod_auto_scaler_example.yaml)
4. ***Logging, Monitoring and Alerting***

    EFK
   - [pre-requisites for EFK](./4_EFK/prequisites)
   - [elastic search](./4_EFK/Elastic_Search)
   - [kibana](./4_EFK/kibana)
   - [config file for fluentd](./4_EFK/config_fluentd.yaml)
   - [fluentd.yaml](./4_EFK/fluentd.yaml)
   
   Prometheus & Grafana
   - [helm](./Prometheus_Grafana/helm)
   
    Cilium Hubble UI
   - [cilium_hubble](./ciium_hubble)