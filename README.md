# SAGGIE DEPLOYMENT SCRIPTS

Using Terraform to manage our AWS resources

Using Kubernetes in AWS (EKS)

Deploying all components of the platform to Kubernetes.

## AWS Deployment

### Dependencies

- AWS CLI
- aws-iam-authenticator
- kubectl
- Terraform
- Java 8
- Gradle 3.5
- git

#### Install Java 8 and Gradle 3.5(Ubuntu)

```
 $ sudo apt-get update
 $ sudo apt-get install unzip
 $ sudo apt-get install zip
 $ pip3 install awscli --upgrade --user
 $ aws --version
 

```

#### Install AWS CLI(Ubuntu)

```
 $ sudo apt-get update
 $ sudo apt-get install python3-pip
 $ pip3 install awscli --upgrade --user
 $ aws --version
 
```
Configure aws cli by using this link :  https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html

#### Install aws-iam-authenticator (Ubuntu)

```
 $ curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.13.8/2019-08-14/bin/linux/amd64/aws-iam-authenticator
 $ curl -o aws-iam-authenticator.sha256 https://amazon-eks.s3-us-west-2.amazonaws.com/1.13.8/2019-08-14/bin/linux/amd64/aws-iam-authenticator.sha256
 $ openssl sha1 -sha256 aws-iam-authenticator
 $ chmod +x ./aws-iam-authenticator
 $ mkdir -p $HOME/bin && cp ./aws-iam-authenticator $HOME/bin/aws-iam-authenticator && export PATH=$HOME/bin:$PATH
 $ echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
 $ aws-iam-authenticator help
 
```

#### Install kubectl (Ubuntu)

```
 $ sudo apt-get update && sudo apt-get install -y apt-transport-https
 $ curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
 $ echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
 $ sudo apt-get update
 $ sudo apt-get install -y kubectl
 
```

#### Install terraform (Ubuntu 64 bits)

```
 $ sudo apt-get install unzip
 $ sudo apt-get install wget unzip
 $ sudo wget https://releases.hashicorp.com/terraform/0.11.14/terraform_0.11.14_linux_amd64.zip
 $ sudo unzip ./ terraform_0.11._linux_amd64.zip –d /usr/local/bin
 $ terraform –v
```

#### Install terraform (Ubuntu 32 bits)

```
 $ sudo apt-get install unzip
 $ sudo apt-get install wget unzip
 $ sudo wget https://releases.hashicorp.com/terraform/0.12.7/terraform_0.12.7_linux_386.zip
 $ sudo unzip ./ terraform_0.12.2_linux_386.zip –d /usr/local/bin
 $ terraform –v
```

## Create kubernetes cluster in aws
```
 $ chmod -R 777 scripts
 $ cd scripts
 $ ./k8s-managment.sh --operation create
```
Two files will be generated in aws-eks directory. one name will look like
kubeconfig-saggie-dev-logging-monitoring-cluster.yaml . Update kubeconfig file path by running

```
 $ export KUBECONFIG=path_to_automation/aws-eks/kubeconfig-saggie-dev-logging-monitoring-cluster.yaml
```
please run the command above each time that you open new console to work

## Create namespace 
```
 $ ./k8s-managment.sh --operation deploy --stack namespace
```

## Deploy Mysql 
```
 $ ./k8s-managment.sh --operation deploy --stack db
```

## Run a MySQL client to connect to the server 
```
 $ kubectl run -n saggie -it --rm --image=mysql:5.6 --restart=Never mysql-client -- mysql -h mysql -ppassword 
```

Once you have connected to the mysql server, create saagie_imf database


## Deploy logging tools(Elasticsearch-Kibana-Filebeat)
```
 $ ./k8s-managment.sh --operation deploy --stack logging
 
```

## Access to kibana and elasticseach 
```
 $ kubectl port-forward svc/kibana 5601:5601 -n saggie
 $ kubectl port-forward svc/elasticsearch 9200:9200 -n saggie
```

Open your browser and access to kibana or elasticsearh by using:
- http://localhost:9200 for elasticsearch
- http://localhost:5601 for kibana


## Deploy Monitoring tools(Alertmanager-Prometheus-Grafana)
```
 $ ./k8s-managment.sh --operation deploy --stack monitoring
```

## Access to Prometheus - Grafana - Alertmanager 
```
 $ kubectl port-forward svc/grafana 3000:3000 -n saggie
 $ kubectl port-forward svc/alertmanager 9093:9093 -n saggie
 $ kubectl port-forward svc/prometheus-service 8080:8080 -n saggie
```

Open your browser and access to kibana or elasticsearh by using:
- http://localhost:8080 for prometheus
- http://localhost:3000 for grafana
- http://localhost:9093 for alertmanager



Once grafana is running:
 	- Access grafana at grafana.yourdomain.com in case of Ingress or http://<LB-IP>:3000 in case of type: LoadBalancer
 	- Add DataSource: 
 	  - Name: DS_PROMETHEUS - Type: Prometheus 
 	  - URL: http://prometheus-service:8080 
 	  - Save and Test. You can now build your custon dashboards or simply import dashboards from grafana.net. Dasboard #315 and #1471 are good to start with.
 	  - You can also import the dashboards from deployment-files/monitoring/dashboards

## Run saggie-api app
```
 $ ./k8s-managment.sh --operation deploy --stack api
 $ kubectl port-forward svc/saggie-api 8081:8081 -n saggie
```

Open your browser and access to saggie api app:
- http://localhost:8081 

## TODO
Test the deployment of saggie-api app
