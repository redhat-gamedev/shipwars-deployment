#!/usr/bin/env bash

CONFIG_MAP_NAME=${CONFIG_MAP_NAME:-shipwars-shared-config}

oc delete servicebinding --all
oc delete kafkaconnection --all
oc delete secret rh-cloud-services-service-account
oc delete secret rh-cloud-services-accesstoken
oc delete is,dc,route,svc,deployment -l "app.kubernetes.io/part-of=shipwars-game"
oc delete cm $CONFIG_MAP_NAME
