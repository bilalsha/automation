#!/usr/bin/env bash


create () {
    echo ""
    echo " Create new kubernetes cluster "
    cd ../aws-eks
    terraform init
    terraform plan
    terraform apply -auto-approve
}

destroy () {
    echo ""
    echo " Destroy existing kubernetes cluster "
    cd ../aws-eks
    terraform destroy -auto-approve
}

create_namespace () {
    echo ""
    echo " Create saggie namespace "
    cd ../deployment-files
    kubectl apply -f namespace/
    kubectl apply -f storage/
}

deploy_db () {
    echo ""
    echo " Deploy Maria db "
    cd ../deployment-files
    kubectl apply -f db/mysql-pv.yml
    kubectl apply -f db/mysql-deployment.yml
}

deploy_api () {
    echo ""
    echo " Deploy Saggie api app "
    cd ../deployment-files
    kubectl apply -f api/
}

deploy_loogging_tools () {
    echo ""
    echo " Deploy Elasticsearch-Kibana-Filebeat for logging managment "
    cd ../deployment-files
    kubectl apply -f logging/2_elasticsearch/
    kubectl apply -f logging/3_kibana/
    kubectl apply -f logging/4_beats_init/
    kubectl apply -f logging/5_beats_agents/
}

deploy_monitoring_tools () {
    echo ""
    echo " Deploy Prometheus-Grafana-Alertmanager for monitoring managment "
    cd ../deployment-files
    kubectl apply -f monitoring/alertmanager/
    kubectl apply -f monitoring/prometheus/
    kubectl apply -f monitoring/kube-state-metrics/
    kubectl apply -f monitoring/grafana/
}

deploy_stack () {
    echo ""
    case "$1" in
       "namespace") create_namespace
       ;;
       "db") deploy_db
       ;;
       "api") deploy_api
       ;;
       "logging") deploy_loogging_tools
       ;;
       "monitoring") deploy_monitoring_tools
       ;;
       *) echo " Unknown operation "
       ;;
    esac
}

check_dependencies(){

    # Check AWS-cli is install
    echo "  Checking  Aws-Cli "
    if ! [ -x "$(command -v aws)" ]; then
      echo ' Error: Aws-cli is not installed.' >&2
      exit 1
    fi

    # Check aws-iam-auth is install
    echo " Checking aws-iam-auth installed"
    if ! [ -x "$(command -v aws-iam-authenticator)" ]; then
      echo ' Error: aws-iam-authenticator is not installed.' >&2
      exit 1
    fi


    # check kubectl install , and version >= 1.10
    echo " Checking Kuebectl installed"
    if ! [ -x "$(command -v kubectl)" ]; then
      echo ' Error: kubectl is not installed.' >&2
      exit 1
    fi
}

optspec=":-:"
while getopts "$optspec" optchar; do
    case "${OPTARG}" in
      operation)
        operation="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
        ;;
      stack)
        stack="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
        ;;
    esac
done

check_dependencies

case "$operation" in
   "create")
      create
   ;;
   "destroy") destroy
   ;;
   "deploy") deploy_stack $stack
   ;;
   *) echo " Unknown operation "
   ;;
esac