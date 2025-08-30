#!/bin/bash

# Cleanup script for Kubernetes EKS Nginx project
# This script removes all resources created during the demo

set -e

echo "🧹 Starting cleanup of Kubernetes EKS Nginx project..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
CLUSTER_NAME="nginx-learning-cluster"
AWS_REGION=${AWS_REGION:-"us-west-2"}

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Confirm cleanup
confirm_cleanup() {
    print_warning "This will delete ALL resources created by this project."
    print_warning "This action cannot be undone!"
    echo ""
    read -p "Are you sure you want to proceed? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo "Cleanup cancelled."
        exit 0
    fi
}

# Delete Kubernetes resources
cleanup_k8s_resources() {
    print_status "Removing Kubernetes resources..."
    
    # Delete in reverse order
    kubectl delete -f k8s-manifests/14-pod-disruption-budget.yaml --ignore-not-found=true
    kubectl delete -f k8s-manifests/13-network-policy.yaml --ignore-not-found=true
    kubectl delete -f k8s-manifests/12-ingress.yaml --ignore-not-found=true
    kubectl delete -f k8s-manifests/11-horizontal-pod-autoscaler.yaml --ignore-not-found=true
    kubectl delete -f k8s-manifests/10-service.yaml --ignore-not-found=true
    kubectl delete -f k8s-manifests/09-deployment.yaml --ignore-not-found=true
    kubectl delete -f k8s-manifests/08-role-binding.yaml --ignore-not-found=true
    kubectl delete -f k8s-manifests/07-role.yaml --ignore-not-found=true
    kubectl delete -f k8s-manifests/06-service-account.yaml --ignore-not-found=true
    kubectl delete -f k8s-manifests/05-persistent-volume-claim.yaml --ignore-not-found=true
    kubectl delete -f k8s-manifests/04-persistent-volume.yaml --ignore-not-found=true
    kubectl delete -f k8s-manifests/03-secret.yaml --ignore-not-found=true
    kubectl delete -f k8s-manifests/02-configmap.yaml --ignore-not-found=true
    kubectl delete -f k8s-manifests/01-namespace.yaml --ignore-not-found=true
    
    print_status "Kubernetes resources deleted ✅"
}

# Remove AWS Load Balancer Controller
cleanup_aws_load_balancer_controller() {
    print_status "Removing AWS Load Balancer Controller..."
    
    helm uninstall aws-load-balancer-controller -n kube-system --ignore-not-found || true
    
    # Delete service account
    eksctl delete iamserviceaccount \
        --cluster=$CLUSTER_NAME \
        --namespace=kube-system \
        --name=aws-load-balancer-controller \
        --region=$AWS_REGION || true
    
    print_status "AWS Load Balancer Controller removed ✅"
}

# Destroy infrastructure
destroy_infrastructure() {
    print_status "Destroying EKS infrastructure..."
    
    cd terraform
    terraform destroy -auto-approve
    cd ..
    
    print_status "Infrastructure destroyed ✅"
}

# Main execution
main() {
    confirm_cleanup
    cleanup_k8s_resources
    cleanup_aws_load_balancer_controller
    destroy_infrastructure
    
    print_status "🎉 Cleanup completed successfully!"
    echo ""
    print_status "All resources have been removed."
    print_warning "Please verify in AWS Console that all resources are deleted to avoid charges."
}

# Run main function
main "$@"