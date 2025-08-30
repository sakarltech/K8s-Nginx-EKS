# K8s-Nginx-EKS
Deploying an Nginx webserver on an EKS cluster on AWS
🎯 Project Purpose
This comprehensive educational project demonstrates how Kubernetes orchestrates application deployment using a real-world nginx web server example on Amazon EKS (Elastic Kubernetes Service). It's designed specifically for students and professionals learning Kubernetes concepts through hands-on experience.
🌟 What You'll Learn
Core Kubernetes Concepts

Container Orchestration: How Kubernetes manages containerized applications
Declarative Configuration: Managing infrastructure and applications as code
Service Discovery: How services find and communicate with each other
Auto-scaling: Horizontal Pod Autoscaler (HPA) for dynamic scaling
Storage Management: Persistent Volumes and Claims for data persistence
Security: RBAC, Network Policies, and Security Contexts
High Availability: Pod Disruption Budgets and anti-affinity rules

Kubernetes Objects Demonstrated

Namespace - Resource isolation and organization
ConfigMap - Configuration data management
Secret - Sensitive data storage
PersistentVolume/PersistentVolumeClaim - Storage orchestration
ServiceAccount - Pod identity management
Role/RoleBinding/ClusterRole/ClusterRoleBinding - RBAC security
Deployment - Pod lifecycle management
Service - Network exposure (ClusterIP, LoadBalancer, Headless)
HorizontalPodAutoscaler - Automatic scaling
Ingress - HTTP/HTTPS routing
NetworkPolicy - Network security
PodDisruptionBudget - Availability during updates
ResourceQuota - Resource management
LimitRange - Default resource limits
StorageClass - Dynamic storage provisioning

📋 Prerequisites
Required Tools

AWS CLI (v2.x) with configured credentials
Terraform (≥ 1.0)
kubectl (matching your Kubernetes version)
helm (v3.x)
eksctl (for service account creation)

AWS Requirements

AWS Account with appropriate permissions
AWS CLI configured with credentials that have:

EC2 permissions (VPC, Security Groups, etc.)
EKS permissions (Cluster and Node Group management)
IAM permissions (Role creation and policy attachment)
EBS permissions (for Persistent Volumes)



Knowledge Prerequisites

Basic understanding of Docker containers
Familiarity with YAML syntax
Basic AWS concepts (VPC, EC2, IAM)
Command line interface usage

🏗️ Project Architecture
┌─────────────────────────────────────────────────────────────────┐
│                           AWS EKS Cluster                      │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐           │
│  │   nginx-1   │  │   nginx-2   │  │   nginx-3   │  (Pods)   │
│  └─────────────┘  └─────────────┘  └─────────────┘           │
│           │              │              │                    │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │              nginx-service (ClusterIP)                 │  │
│  └─────────────────────────────────────────────────────────┘  │
│           │                                                    │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │            AWS Load Balancer (NLB)                     │  │
│  └─────────────────────────────────────────────────────────┘  │
│           │                                                    │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │                  Ingress Controller                     │  │
│  └─────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                           │
                    ┌─────────────┐
                    │   Internet  │
                    └─────────────┘
📂 Project Structure
k8s-nginx-project/
├── README.md                          # This file
├── terraform/                         # Infrastructure as Code
│   ├── main.tf                       # Main Terraform configuration
│   ├── variables.tf                  # Input variables
│   ├── outputs.tf                    # Output values
│   └── versions.tf                   # Provider versions
├── k8s-manifests/                    # Kubernetes YAML files
│   ├── 01-namespace.yaml            # Namespace, ResourceQuota, LimitRange
│   ├── 02-configmap.yaml            # Configuration data
│   ├── 03-secret.yaml               # Sensitive data
│   ├── 04-persistent-volume.yaml    # Storage class and PV
│   ├── 05-persistent-volume-claim.yaml # Storage claims
│   ├── 06-service-account.yaml      # Pod identity
│   ├── 07-role.yaml                 # RBAC permissions
│   ├── 08-role-binding.yaml         # RBAC bindings
│   ├── 09-deployment.yaml           # Main application
│   ├── 10-service.yaml              # Network services
│   ├── 11-horizontal-pod-autoscaler.yaml # Auto-scaling
│   ├── 12-ingress.yaml              # HTTP routing
│   ├── 13-network-policy.yaml       # Network security
│   └── 14-pod-disruption-budget.yaml # Availability
├── scripts/                          # Automation scripts
│   ├── deploy.sh                    # Full deployment script
│   └── cleanup.sh                   # Resource cleanup script
└── docs/                            # Additional documentation
    ├── troubleshooting.md           # Common issues and solutions
    └── learning-exercises.md        # Hands-on exercises
🚀 Step-by-Step Implementation
Step 1: Environment Setup

Clone the project (or create the directory structure):
bashmkdir k8s-nginx-project
cd k8s-nginx-project

Verify prerequisites:
bash# Check AWS CLI
aws --version
aws sts get-caller-identity

# Check Terraform
terraform --version

# Check kubectl
kubectl version --client

# Check helm
helm version

# Check eksctl
eksctl version

Set environment variables:
bashexport AWS_REGION=us-west-2  # Change to your preferred region
export AWS_PROFILE=default   # Change to your AWS profile


Step 2: Create Project Files
Create all the files from the artifact above in their respective directories. You can copy each section into the appropriate file.
Step 3: Infrastructure Deployment

Navigate to terraform directory:
bashcd terraform

Initialize Terraform:
bashterraform init

Review the planned changes:
bashterraform plan

Apply the infrastructure:
bashterraform apply
Type yes when prompted. This process takes 15-20 minutes.
Note the outputs:
bashterraform output


Step 4: Configure kubectl for EKS

Update kubeconfig:
bashaws eks update-kubeconfig --region us-west-2 --name nginx-learning-cluster

Verify cluster access:
bashkubectl cluster-info
kubectl get nodes


Step 5: Install AWS Load Balancer Controller

Create IAM service account:
basheksctl create iamserviceaccount \
  --cluster=nginx-learning-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess \
  --approve \
  --region=us-west-2

Add Helm repository:
bashhelm repo add eks https://aws.github.io/eks-charts
helm repo update

Install the controller:
bashhelm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=nginx-learning-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller


Step 6: Deploy Kubernetes Manifests

Navigate back to project root:
bashcd ..

Deploy in order (understanding each component):
a. Create namespace and resource controls:
bashkubectl apply -f k8s-manifests/01-namespace.yaml
Teaching moment: Explain how namespaces provide isolation
b. Create configuration data:
bashkubectl apply -f k8s-manifests/02-configmap.yaml
kubectl apply -f k8s-manifests/03-secret.yaml
Teaching moment: Show how to view config data safely
c. Set up storage:
bashkubectl apply -f k8s-manifests/04-persistent-volume.yaml
kubectl apply -f k8s-manifests/05-persistent-volume-claim.yaml
Teaching moment: Explain storage lifecycle
d. Configure security:
bashkubectl apply -f k8s-manifests/06-service-account.yaml
kubectl apply -f k8s-manifests/07-role.yaml
kubectl apply -f k8s-manifests/08-role-binding.yaml
Teaching moment: RBAC and principle of least privilege
e. Deploy the application:
bashkubectl apply -f k8s-manifests/09-deployment.yaml
Teaching moment: Watch pods being created and scheduled
f. Create networking:
bashkubectl apply -f k8s-manifests/10-service.yaml
kubectl apply -f k8s-manifests/12-ingress.yaml
Teaching moment: Different service types and routing
g. Configure scaling and policies:
bashkubectl apply -f k8s-manifests/11-horizontal-pod-autoscaler.yaml
kubectl apply -f k8s-manifests/13-network-policy.yaml
kubectl apply -f k8s-manifests/14-pod-disruption-budget.yaml
Teaching moment: Scaling, security, and availability

Step 7: Verification and Testing

Check all resources are running:
bashkubectl get all -n nginx-demo

Verify pod status:
bashkubectl get pods -n nginx-demo -o wide

Check service endpoints:
bashkubectl get svc -n nginx-demo

Get LoadBalancer URL:
bashkubectl get svc nginx-loadbalancer -n nginx-demo

Test the application:
bash# Get the external IP/hostname
EXTERNAL_IP=$(kubectl get svc nginx-loadbalancer -n nginx-demo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Application URL: http://$EXTERNAL_IP"

# Test with curl
curl http://$EXTERNAL_IP
curl http://$EXTERNAL_IP/health


🔍 Educational Exploration Commands
Understanding Pods and Deployments
bash# View pod details
kubectl describe pod <pod-name> -n nginx-demo

# Check pod logs
kubectl logs -f deployment/nginx-deployment -n nginx-demo

# Execute commands inside a pod
kubectl exec -it <pod-name> -n nginx-demo -- /bin/sh

# Scale the deployment manually
kubectl scale deployment nginx-deployment --replicas=5 -n nginx-demo
Exploring Configuration
bash# View ConfigMap data
kubectl get configmap nginx-config -n nginx-demo -o yaml

# View Secret data (base64 encoded)
kubectl get secret nginx-secrets -n nginx-demo -o yaml

# Decode secret values
kubectl get secret nginx-secrets -n nginx-demo -o jsonpath='{.data.username}' | base64 -d
Understanding Storage
bash# Check PVC status
kubectl get pvc -n nginx-demo

# View PV details
kubectl get pv

# Check storage class
kubectl get storageclass
Monitoring and Scaling
bash# Watch HPA in action
kubectl get hpa -n nginx-demo -w

# Generate load to trigger scaling
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh
# Inside the pod:
while true; do wget -q -O- http://nginx-service.nginx-demo.svc.cluster.local; done
Security Exploration
bash# Check RBAC permissions
kubectl auth can-i get pods --as=system:serviceaccount:nginx-demo:nginx-service-account -n nginx-demo

# View network policies
kubectl get networkpolicy -n nginx-demo

# Check pod security context
kubectl get pod <pod-name> -n nginx-demo -o jsonpath='{.spec.securityContext}'
📊 Monitoring and Observability
Resource Usage
bash# Check resource usage
kubectl top pods -n nginx-demo
kubectl top nodes

# View resource quotas
kubectl describe quota -n nginx-demo

# Check limit ranges
kubectl describe limitrange -n nginx-demo
Events and Troubleshooting
bash# View namespace events
kubectl get events -n nginx-demo --sort-by=.metadata.creationTimestamp

# Check deployment status
kubectl rollout status deployment/nginx-deployment -n nginx-demo

# View deployment history
kubectl rollout history deployment/nginx-deployment -n nginx-demo
🛠️ Quick Start (Automated)
For a fully automated deployment, use the provided scripts:
bash# Make scripts executable
chmod +x scripts/deploy.sh scripts/cleanup.sh

# Deploy everything
./scripts/deploy.sh

# When done learning, cleanup
./scripts/cleanup.sh
📚 Learning Exercises
Exercise 1: Scale and Observe

Scale the deployment to 1 replica and observe behavior
Scale to 10 replicas and watch pod distribution
Generate load and observe HPA scaling

Exercise 2: Configuration Changes

Update the ConfigMap with new HTML content
Restart the deployment to pick up changes
Observe rolling update behavior

Exercise 3: Storage Testing

Create a file in the persistent volume
Delete a pod and verify file persistence
Scale down and up, confirm data remains

Exercise 4: Security Testing

Try to access resources from different namespaces
Test network policies by creating test pods
Verify RBAC permissions with different service accounts

Exercise 5: Failure Simulation

Delete a node and observe pod rescheduling
Simulate pod failures and observe recovery
Test PodDisruptionBudget during updates

🔧 Customization Options
Modify Resource Limits
Edit k8s-manifests/01-namespace.yaml to change:

CPU/Memory quotas
Pod limits
Storage limits

Change Scaling Behavior
Edit k8s-manifests/11-horizontal-pod-autoscaler.yaml to:

Adjust CPU/Memory thresholds
Change min/max replicas
Modify scaling policies

Update Application Configuration
Edit k8s-manifests/02-configmap.yaml to:

Change nginx configuration
Modify the HTML content
Add new configuration files

Enhance Security
Edit k8s-manifests/13-network-policy.yaml to:

Restrict network access further
Add ingress/egress rules
Test isolation between namespaces

🚨 Troubleshooting Guide
Common Issues
Pods Stuck in Pending State
bash# Check node resources
kubectl describe nodes

# Check PVC binding
kubectl get pvc -n nginx-demo

# Check pod events
kubectl describe pod <pod-name> -n nginx-demo
LoadBalancer Service Not Getting External IP
bash# Check AWS Load Balancer Controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Verify service annotations
kubectl describe svc nginx-loadbalancer -n nginx-demo

# Check AWS Console for load balancer creation
HPA Not Scaling
bash# Check metrics server
kubectl get apiservice v1beta1.metrics.k8s.io -o yaml

# Install metrics server if missing
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Check HPA status
kubectl describe hpa nginx-hpa -n nginx-demo
Network Policy Blocking Traffic
bash# Temporarily delete network policy for testing
kubectl delete networkpolicy nginx-network-policy -n nginx-demo

# Check pod-to-pod connectivity
kubectl run test-pod --image=busybox -it --rm --restart=Never -n nginx-demo -- /bin/sh
Useful Debugging Commands
bash# Get all resources in namespace
kubectl get all -n nginx-demo

# Check resource usage
kubectl top pods -n nginx-demo

# View detailed resource information
kubectl describe <resource-type> <resource-name> -n nginx-demo

# Check cluster events
kubectl get events --sort-by=.metadata.creationTimestamp -A

# View controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
💰 Cost Management
Estimated AWS Costs

EKS Cluster: ~$0.10/hour ($73/month)
t3.medium nodes (2x): ~$0.08/hour ($60/month total)
EBS volumes: ~$0.10/GB/month
Load Balancer: ~$16/month
Data transfer: Variable based on usage

Total estimated cost: ~$150/month for learning environment
Cost Optimization Tips

Use t3.small instances for basic learning (modify terraform/variables.tf)
Stop cluster when not in use (scale node group to 0)
Use spot instances for node groups
Clean up resources after learning sessions

🧹 Cleanup Instructions
Automated Cleanup
bash./scripts/cleanup.sh
Manual Cleanup (if script fails)
bash# Delete Kubernetes resources
kubectl delete namespace nginx-demo

# Delete AWS Load Balancer Controller
helm uninstall aws-load-balancer-controller -n kube-system

# Destroy infrastructure
cd terraform
terraform destroy
Verify Cleanup

Check AWS Console for remaining resources
Verify no unexpected charges in billing
Ensure EBS volumes are deleted

📖 Additional Learning Resources
Kubernetes Documentation

Official Kubernetes Docs
EKS User Guide
kubectl Cheat Sheet

Hands-on Learning

Experiment with different configurations
Try breaking things intentionally to understand error handling
Monitor resource usage during different operations
Practice troubleshooting common issues

Next Steps

Implement monitoring with Prometheus and Grafana
Add CI/CD pipelines with GitOps
Explore service mesh (Istio/Linkerd)
Learn about operators and custom resources

🤝 Contributing to Learning
This project is designed for educational purposes. Students and instructors can:

Modify configurations to explore different scenarios
Add new Kubernetes objects for extended learning
Create additional exercises and challenges
Share improvements and bug fixes

⚠️ Important Notes
Security Considerations

This project uses simplified security for educational purposes
DO NOT use in production without proper security hardening
Secrets contain dummy data for demonstration
Network policies are basic examples

Production Differences

Use proper TLS certificates (not self-signed)
Implement proper monitoring and logging
Use encrypted storage
Follow security best practices
Implement backup and disaster recovery
Use GitOps for deployment management

Learning Objectives Checklist
After completing this project, students should understand:

 How Kubernetes schedules and manages pods
 The relationship between different K8s objects
 How services provide network abstraction
 Configuration management patterns
 Storage orchestration concepts
 RBAC and security models
 Scaling and availability strategies
 Troubleshooting techniques

🆘 Support and Questions
For questions about this educational project:

Check the troubleshooting section above
Review Kubernetes official documentation
Search for similar issues in K8s community forums
Practice with kubectl explain <resource> for object documentation

📝 License
This educational project is provided for learning purposes. Use responsibly and ensure compliance with your organization's policies when deploying in AWS environments.

Happy Learning! 🎓
Remember: The best way to learn Kubernetes is by experimenting, breaking things, and understanding how they work together. This project provides a safe environment to do exactly that!
