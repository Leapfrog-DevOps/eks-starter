#!/bin/bash

# deploy metrics server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/high-availability-1.21+.yaml
wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/high-availability-1.21+.yaml

# example to apply php-apache
kubectl apply -f https://k8s.io/examples/application/php-apache.yaml

# create hpa via kubectl command
kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=10
