#!/bin/bash

set -e

CLUSTER_NAME=$1
REGION=${2:-us-east-1}

if [ -z "$CLUSTER_NAME" ]; then
  echo "Usage: ./cleanup-eks.sh <cluster-name> [region]"
  exit 1
fi

echo "=============================="
echo "Cleaning EKS Cluster: $CLUSTER_NAME"
echo "Region: $REGION"
echo "=============================="

# Step 1: Delete EKS cluster using eksctl (best effort)
echo "1. Deleting cluster via eksctl (if exists)..."
eksctl delete cluster \
  --name "$CLUSTER_NAME" \
  --region "$REGION" \
  --wait || true

# Step 2: Find CloudFormation stacks
echo "2. Checking CloudFormation stacks..."

STACKS=$(aws cloudformation list-stacks \
  --region "$REGION" \
  --stack-status-filter CREATE_IN_PROGRESS CREATE_COMPLETE UPDATE_COMPLETE ROLLBACK_COMPLETE UPDATE_ROLLBACK_COMPLETE DELETE_FAILED \
  --query "StackSummaries[?contains(StackName, \`eksctl-$CLUSTER_NAME\`)].StackName" \
  --output text)

echo "Found stacks: $STACKS"

# Step 3: Delete CloudFormation stacks manually
for stack in $STACKS; do
  echo "Deleting stack: $stack"

  aws cloudformation update-termination-protection \
    --stack-name "$stack" \
    --no-enable-termination-protection \
    --region "$REGION" 2>/dev/null || true

  aws cloudformation delete-stack \
    --stack-name "$stack" \
    --region "$REGION" || true
done

# Step 4: Wait check
echo "3. Waiting for deletion (this may take 10–30 min)..."
sleep 10

echo "4. Current remaining stacks:"
aws cloudformation list-stacks \
  --region "$REGION" \
  --stack-status-filter DELETE_IN_PROGRESS DELETE_FAILED \
  --query "StackSummaries[?contains(StackName, \`eksctl-$CLUSTER_NAME\`)].StackName" \
  --output table

echo "=============================="
echo "Cleanup triggered successfully!"
echo "Check AWS Console if anything remains stuck."
echo "=============================="
