#!/bin/bash
set -e


if [ $# -ne 1 ]
then
  echo "Environment argument is missing"
  exit 1
fi
ENVIRONMENT=$1
RESTART_TIME_DIFF_THRESHOLD=120

getTimeDifferenceFromCurrentTime(){
  currentTimeStamp=$(TZ=UTC date +%s)
  receivedTimeStamp=$(TZ=UTC date -d"$1" +%s)
  diff=$((currentTimeStamp-receivedTimeStamp))
  echo $diff
}

checkIfDeploymentUpdated(){
  deployment_name=$1
  lastUpdatedTime=$(kubectl get deployment "$deployment_name" -n "$ENVIRONMENT" -o jsonpath='{.status.conditions[1].lastUpdateTime}')
  timeDiff=$(getTimeDifferenceFromCurrentTime "$lastUpdatedTime")
  if [ $timeDiff -le $RESTART_TIME_DIFF_THRESHOLD ]
  then
    echo "true"
  else
    echo "false"
  fi
}

echo "Checking if Clinic-config has updated.."
isConfigUpdated=$(checkIfDeploymentUpdated clinic-config)
echo "Checking if OpenMRS has updated.."
isOpenMRSUpdated=$(checkIfDeploymentUpdated openmrs)

if [ "$isConfigUpdated" == "true" ] && [ "$isOpenMRSUpdated" == "false" ]
then
  echo "Restarting OpenMRS.."
  kubectl rollout restart deployment openmrs -n $ENVIRONMENT
fi
