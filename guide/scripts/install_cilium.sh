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
