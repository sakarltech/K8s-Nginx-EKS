#!/bin/bash

# Kubernetes EKS Nginx Deployment Script
# Educational project for learning Kubernetes orchestration

set -e

echo "🚀 Starting Kubernetes EKS Nginx Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION=${AWS_REGION:-"us-west-2"}
CLUSTER_NAME="nginx-learning-cluster"

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

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if AWS CLI is installed and configured
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install it first."
        exit 1
    fi
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        print_error "Helm is not installed. Please install it first."
        exit 1
    fi
    
    print_status "All prerequisites are satisfied ✅"
}

# Deploy infrastructure with Terraform
deploy_infrastructure() {
    print_status "Deploying EKS infrastructure with Terraform..."
    
    cd terraform
    
    # Initialize Terraform
    terraform init
    
    # Plan the deployment
    terraform plan -out=tfplan
    
    # Apply the plan
    terraform apply tfplan
    
    # Get outputs
    CLUSTER_NAME=$(terraform output -raw cluster_name)
    CLUSTER_REGION=$(terraform output -raw cluster_region)
    
    cd ..
    
    print_status "Infrastructure deployed successfully ✅"
}

# Configure kubectl
configure_kubectl() {
    print_status "Configuring kubectl for EKS cluster..."
    
    aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME
    
    # Test connection
    kubectl cluster-info
    
    print_status "kubectl configured successfully ✅"
}

# Install AWS Load Balancer Controller
install_aws_load_balancer_controller() {
    print_status "Installing AWS Load Balancer Controller..."
    
    # Create service account
    eksctl create iamserviceaccount \
        --cluster=$CLUSTER_NAME \
        --namespace=kube-system \
        --name=aws-load-balancer-controller \
        --role-name AmazonEKSLoadBalancerControllerRole \
        --attach-policy-arn=arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess \
        --approve \
        --region=$AWS_REGION
    
    # Add helm repo
    helm repo add eks https://aws.github.io/eks-charts
    helm repo update
    
    # Install controller
    helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
        -n kube-system \
        --set clusterName=$CLUSTER_NAME \
        --set serviceAccount.create=false \
        --set serviceAccount.name=aws-load-balancer-controller
    
    print_status "AWS Load Balancer Controller installed ✅"
}

# Deploy Kubernetes manifests
deploy_k8s_manifests() {
    print_status "Deploying Kubernetes manifests..."
    
    # Apply manifests in order
    kubectl apply -f k8s-manifests/01-namespace.yaml
    kubectl apply -f k8s-manifests/02-configmap.yaml
    kubectl apply -f k8s-manifests/03-secret.yaml
    kubectl apply -f k8s-manifests/04-persistent-volume.yaml
    kubectl apply -f k8s-manifests/05-persistent-volume-claim.yaml
    kubectl apply -f k8s-manifests/06-service-account.yaml
    kubectl apply -f k8s-manifests/07-role.yaml
    kubectl apply -f k8s-manifests/08-role-binding.yaml
    kubectl apply -f k8s-manifests/09-deployment.yaml
    kubectl apply -f k8s-manifests/10-service.yaml
    kubectl apply -f k8s-manifests/11-horizontal-pod-autoscaler.yaml
    kubectl apply -f k8s-manifests/12-ingress.yaml
    kubectl apply -f k8s-manifests/13-network-policy.yaml
    kubectl apply -f k8s-manifests/14-pod-disruption-budget.yaml
    
    print_status "Kubernetes manifests deployed ✅"
}

# Wait for deployment to be ready
wait_for_deployment() {
    print_status "Waiting for nginx deployment to be ready..."
    
    kubectl wait --for=condition=available --timeout=300s deployment/nginx-deployment -n nginx-demo
    
    print_status "Deployment is ready ✅"
}

# Display deployment information
display_info() {
    print_status "Deployment Information:"
    echo ""
    
    # Get LoadBalancer URL
    LB_URL=$(kubectl get svc nginx-loadbalancer -n nginx-demo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    
    echo "🌐 LoadBalancer URL: http://$LB_URL"
    echo "📊 Grafana Dashboard: (if monitoring is set up)"
    echo ""
    
    print_status "Useful commands:"
    echo "  kubectl get pods -n nginx-demo"
    echo "  kubectl get svc -n nginx-demo"
    echo "  kubectl describe deployment nginx-deployment -n nginx-demo"
    echo "  kubectl logs -f deployment/nginx-deployment -n nginx-demo"
    echo ""
}

# Main execution
main() {
    check_prerequisites
    deploy_infrastructure
    configure_kubectl
    install_aws_load_balancer_controller
    deploy_k8s_manifests
    wait_for_deployment
    display_info
    
    print_status "🎉 Deployment completed successfully!"
    print_warning "Don't forget to run cleanup.sh when you're done learning!"
}

# Run main function
main "$@"