# needs admin access
# test your identity
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


