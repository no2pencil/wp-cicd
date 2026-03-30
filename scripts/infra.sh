#!/bin/bash
set -e

if [ ! $2 ] ;then 
	echo "You must provide an infra state [ up ] [ down ]"
	exit 1
fi

if [ ! $1 ] ;then 
	echo "You must provide an environment [ dev ] [ stg ] [ prod ]"
	exit 1
fi


INFRA_STATE=$(echo $2)
ENV=$(echo $1)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

TF_DIR=${ROOT_DIR}/terraform/

case ${ENV} in
dev|DEV)
	ENV_DEV=~${TF_DIR}environments/dev
	;;
stg|STG)
	ENV_STG=~${TF_DIR}environments/stg
	;;
prod|PROD)
	ENV_PROD=~${TF_DIR}environments/prod
	;;
*)
	echo "Invalid Environment provided"
	;;
esac


case ${INFRA_STATE} in
up|UP)
	## Terraform - Stand up infra

	## Update IP in security group
	bash ${SCRIPT_DIR}/update-security-ip.sh ${ENV}

	echo "Provisioning infrastructure..."

	cd ${TF_DIR}environments/${ENV}
	echo "Launching Terraform"
	terraform init
	terraform apply -auto-approve
	
	echo "Infrastructure ready."
	;;


down|DOWN)
	## Terraform - destroy
	
	echo "Destroy Terraform"
	cd ${TF_DIR}environments/${ENV}
	terraform destroy -auto-approve
	echo "All gone!"
	;;

esac
