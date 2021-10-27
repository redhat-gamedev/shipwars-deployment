#!/usr/bin/env bash

NAMESPACE=${NAMESPACE:-shipwars}
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if ! command -v oc &> /dev/null
then
    echo "Please install oc CLI to use this script"
    exit
fi

if ! command -v rhoas &> /dev/null
then
    echo "Please install rhoas CLI to use this script"
    exit
fi

if ! command -v jq &> /dev/null
then
    echo "Please install jq CLI to use this script"
    exit
fi

oc project $NAMESPACE > /dev/null 2>&1

if [ $? -eq 0 ]; then
  echo "Using project $NAMESPACE on cluster: $(oc whoami --show-server)"
else
  echo "Failed to select $NAMESPACE project using the 'oc project' command."
  echo "Did you forget to set the NAMESPACE variable, or have not run deploy.sh yet?"
  exit 1
fi

rhoas login > /dev/null 2>&1

if [ $? -eq 0 ]; then
  echo "Logged in to OpenShift Streams for Apache Kafka."
else
  echo "Login failed for OpenShift Streams for Apache Kafka."
  exit 1
fi

KAFKA_COUNT=$(rhoas kafka list -o json | jq '.total')

if [ "0" == "$KAFKA_COUNT" ]; then
  echo "Please create a Kafka instance using 'rhoas kafka create' and retry this script"
fi

# Force user to choose a kafka instance
rhoas kafka use

# Check topics exist (yes, this is basic but should help)
rhoas kafka topic list -o json | jq -r '.items[].name' | grep 'shipwars-attacks'
if [ $? -eq 1 ]; then
  echo "Please run the configure-rhosak.sh script in the root of this repository then retry this script."
fi

# Connect the chosen instance to the cluster
rhoas cluster connect --service-type kafka -n $NAMESPACE
rhoas cluster bind --service-type kafka --app-name shipwars-game-server

# Configure permissions for the generated service account
CLIENT_ID=$(oc get secret rh-cloud-services-service-account -o jsonpath='{.data.client-id}' | base64 --decode)
rhoas kafka acl grant-access --yes --producer --consumer --service-account $CLIENT_ID --topic-prefix shipwars --group all
