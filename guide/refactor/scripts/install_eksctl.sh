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
