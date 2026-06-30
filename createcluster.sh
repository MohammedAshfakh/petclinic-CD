#!/bin/bash

CLUSTNAME= "petclinic-cluster"
REGION="us-east-1"
TIER="t3.medium"
NODESCOUNT=3


eksctl create cluster \
	--name "$CLUSTNAME" \
	--region "$REGION" \
	--nodegroup-name workers \
	--node-type "$TIER" \
	--nodes "$NODESCOUNT"	


curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

sudo snap install kubectl --classic 

aws eks update-kubeconfig --region "$REGION" --name "$CLUSTNAME"
