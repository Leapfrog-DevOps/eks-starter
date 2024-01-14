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
