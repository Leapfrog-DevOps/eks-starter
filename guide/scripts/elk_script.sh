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

