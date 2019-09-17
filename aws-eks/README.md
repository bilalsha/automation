# Terraform orchestrated AWS 

## Dependencies

- [Terraform](https://www.terraform.io/downloads.html)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [AWC CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html#install-tool-pip)
- [aws-iam-authenticator](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html)

---

### Terraform CLI
Install the Terraform CLI tool here: https://www.terraform.io/downloads.html  
Usage reference:
- https://www.terraform.io/docs/commands/index.html


### Kubectl & AWS Setups.

- Newer version of `kubectl`:
  - https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html

- Install the AWS IAM Authenticator, to access the EKS Cluster via `kubectl`
  - https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html
  - https://github.com/kubernetes-sigs/aws-iam-authenticator

- Have `aws-cli` installed locally too.
  - https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html


##### Aws CLI setup
I am assuming we have an aws 'profile', BUT usually aws-cli will have a `default` .   
Its good practice (from my insane adventrues) to keep an explicity 'profile`.

To configure `aws` with a profile, just run :
```bash
aws  configure  --profile st
```
When ever you use the `aws` cli, just add that profile:
```bash
# (i.e.: list out all S3 buckets)
aws --profile st s3 ls
```


--- 
## Terraform
 
#### Basic Commands
```bash
terraform init
terraform plan
terraform apply

terraform destroy

```

--- 

#### Steps
Using terraform scripts to deploy our AWS stack.  
(*Note*: Kubernetes Dashboard is not needed, its just a nice ui to manage kubernetes ) 
```bash
terraform apply

#IF, you get the error:
#* null_resource.apply_config_map_aws_auth: Error running command 
# run this:   (this will link your kubectl context to your cluster)
aws --profile st eks update-kubeconfig --name sonartrade-prod-eks-cluster
#then rerun,  
kubectl apply -f config-map-aws-auth-sonartrade-prod-eks-cluster.yaml
```

Get the dashboard to make life easy  
https://docs.aws.amazon.com/eks/latest/userguide/dashboard-tutorial.html
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
# Create an admin in EKS, used to access the dashboard
kubectl apply -f ../setup/aws/eks-admin.yaml

# Running the proxy in another screen
kubectl proxy --disable-filter=true

# Once the proxy is up, you can use the Kubernetes Dashboard
# http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/

```
To login to the dashboard, you will need to generate a JWT token.  This will generate one, just copy/paste it in the dashboard login screen 
```bash
kubectl  -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | awk '{print $1}')
```



..


#### References

- https://docs.aws.amazon.com/eks/latest/userguide/dashboard-tutorial.html
- https://learn.hashicorp.com/terraform/development/running-terraform-in-automation
- https://github.com/kubernetes/autoscaler

- https://stackoverflow.com/questions/33671449/how-to-restart-kubernetes-nodes
- http://vcloudynet.blogspot.com/2017/03/how-to-setup-vpc-peering-with-terraform.html