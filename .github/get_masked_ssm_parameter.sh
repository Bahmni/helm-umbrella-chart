#!/bin/bash
set -e

#Parameters (SSM_PARAMETER_NAME, OUTPUT_VARIABLE_NAME)

if [ $# -ne 2 ]
then
echo "Invalid Arguments. Need SSM_PARAMETER_NAME, OUTPUT_VARIABLE_NAME"
exit 2
fi

SSM_PARAMETER_NAME=$1
OUTPUT_VARIABLE_NAME=$2

PARAMETER_VALUE=$(aws ssm get-parameter --with-decryption --name "$SSM_PARAMETER_NAME" --query "Parameter.Value" --output text)
echo "::add-mask::$PARAMETER_VALUE"
echo "$OUTPUT_VARIABLE_NAME=$PARAMETER_VALUE" >> $GITHUB_ENV
