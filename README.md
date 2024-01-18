# Hello world services application POC

## Design decision

Following the given task, some considerations were made regarding the chosen approach. Two solutions were considered, along with other variants, as most appropriate. 
1. Running the application as AWS ECS with Fargate is the most straightforward and easily achievable solution, especially when considering the "hello-world-services" application in isolation. ECS offers a great option for more isolated workloads utilizing containers. It can host full applications with several microservices as well. However, it is not as manageable and customizable as EKS.
2. Running the application in AWS EKS with some addons for logs and metrics. This approach was chosen by me because of mainly two reasons:
	- In the task it is mentioned that the company has many microservices that might have some internal networking. It might be a good idea to propose a central place where those can be run and managed in the same automated manner without additional management of control panel: AWS EKS. "hello-world-services" application can serve as a PoC, and other microservices could be migrated later on.
	- During the interview, we talked a lot about Kubernetes, and Lotto24 is using it. Therefore, I would like to show my vision of EKS automation and deployment style rather than just fulfilling the task in isolation.

### What is in the repo and prerequisites

1. Terraform code for creating eks (terraform/eks) and for creating eks addons (terraform/eks_addons).
2. Files for building hello-world-service image (application)
3. Kubernetes configuration for hello-world-service (application/hello-world-service.yaml).
4. GitHub actions files to create terraform and kubernetes resources in case CI will be used (.github/workflows)

For local testing, engineer should have:
1. helm, kubectl, terraform and awscli installed locally.
2. AWS account with created user or role (for PoC it shall have Admin permissions)
3. Corresponding AWS profile locally (AWS env vars or profile file)
4. S3 bucket "backend-bucket-16012024" is created in AWS account for terraform state (eu-west-1).

For CI testing, engineer should have:
1. AWS account with created user or role (for PoC it can have Admin permissions)
2. AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and ECR_REPOSITORY GitHub secrets are created.
3. S3 bucket "backend-bucket-16012024" is created in AWS account for terraform state(eu-west-1).

### What does setup include

1. Terraform code creates a VPC and an EKS cluster from scratch. EKS uses one managed node group. Additionally, EKS addons code installs the necessary addons for logging (cwagent, fluentbit agent) and exposes metrics using (prometheus and grafana).
2. The Dockerfile and Nginx configuration are used for building the Docker image. We aim to store images in ECR. The image always has the "latest" tag for simplicity.
3. Kubernetes installation consists of a Deployment with 2 replicas, scaling based on CPU, Service, and Ingress with an external AWS ALB.
4. In the end, the application should be accessible via the domain name "hello-world-service.com" (of course, with changing the local resolv.conf).


### Local testing steps
1. Clone this repo locally
2. Create AWS resources using terraform. 

```bash
cd terraform/eks
terraform init; terraform apply
aws eks --region eu-west-1 update-kubeconfig --name qa-eks-test
cd ../eks_addons
terraform init; terraform apply
```

This part creates all needed resources for VPC, EKS and EKS addons.

3. Build an image.

```bash
cd application
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin {YOUR_ACCOUNT}.dkr.ecr.eu-west-1.amazonaws.com
docker build -t hello-world-service .
docker tag hello-world-service:latest {YOUR_ACCOUNT}.dkr.ecr.eu-west-1.amazonaws.com/hello-world-service:latest
docker push {YOUR_ACCOUNT}.dkr.ecr.eu-west-1.amazonaws.com/hello-world-service:latest
```

4. Create kubernetes resources.

```bash
cd application/eks_templates
kubectl apply -f hello-world-service.yaml
```

It will create hello-world-service and expose it externally.

5. Go to AWS Accound and find newly created ALB. Copy its domain name and resolve it.

```bash
dig ALB_DOMAIN_NAME
```

6. Curl hello-world-service.com through the one of external IP address.

```bash
curl http://hello-world-service.com --resolve 'hello-world-service.com:80:EXTERNAL_IP'
```

### CI testing steps

It's much easier to install everything with CI using GitHub Actions. We have two workflows for AWS resources and for application deployment. The proposed way is as follows:
1. Fork the repo. You can use the existing one, but then you'll need to have a session with me to set the needed AWS and ECR secrets.
3. Set needed GitHub secrets AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and ECR_REPOSITORY on repo level.
2. Push dummy changes to the Terraform folder in the main branch. It will trigger Terraform for VPC, EKS, and Addons.
3. Push dummy changes to the application folder in the main branch. It will trigger application deployment with image builds included.
4. Go to the AWS account and find the newly created ALB. Copy its domain name and resolve it.

```bash
dig ALB_DOMAIN_NAME
```

5. Curl hello-world-service.com through the one of external IP address.

```bash
curl http://hello-world-service.com --resolve 'hello-world-service.com:80:EXTERNAL_IP'
```

### Logs and metrics
Logs are collected via cwagents and fluentbit agents installed in EKS. Logs for application could be found in Cloudwatch log group: /aws/containerinsights/qa-eks-test/application. Those could be moved to Datadog via forwarder if needed. 

Cloudwatch can be also used for EKS and application metrics if they are sent in needed format. In that PoC I also include installation of prometheus and grafana to be able to see basic metrics, create alerts and dashboards. In that example Grafana is internal but could be extended via Ingress. Main steps to see metrics:

1. Get grafana password: 
```bash
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```
2. Get correct prometheus endpoint for metrics (take an IP):
```bash
kubectl get svc/prometheus-kube-prometheus-prometheus -n monitoring
```
3. Expose Grafana locally:
```bash
kubectl port-forward svc/grafana 3000:80 -n monitoring
```
4. Login to http://localhost:3000/login and set known prometheus endpoint with 9090 port.
5. Import dashboards 3119 and 6417 from grafana.com and enjoy.

### Deletion of resources
All resources could be deleted only on the local machine so far.

```bash
aws eks --region eu-west-1 update-kubeconfig --name qa-eks-test
kubectl destroy -f hello-world-service.yaml
cd terraform/eks_addons
terraform init; terraform destroy
cd ../esk
terraform init; terraform destroy
```