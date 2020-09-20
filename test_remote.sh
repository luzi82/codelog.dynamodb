#!/bin/bash

set -e

export AWS_DEFAULT_REGION=us-west-2

MY_PATH=${PWD}

cd ${MY_PATH}
rm -rf tmp

mkdir -p ${MY_PATH}/tmp
cd ${MY_PATH}/tmp
python3 -m venv venv-test
. venv-test/bin/activate
pip install -U pip wheel
pip install awscli boto3

# check if dynamodb work
aws dynamodb list-tables

# create table
aws dynamodb create-table \
    --table-name Table0 \
    --attribute-definitions \
        AttributeName=Att0,AttributeType=S \
        AttributeName=Att1,AttributeType=S \
    --key-schema \
        AttributeName=Att0,KeyType=HASH \
        AttributeName=Att1,KeyType=RANGE \
    --global-secondary-indexes \
        IndexName=Index1,KeySchema=[\{AttributeName=Att1,KeyType=HASH\}],Projection=\{ProjectionType=KEYS_ONLY\} \
    --billing-mode PAY_PER_REQUEST
aws dynamodb wait table-exists --table-name Table0

# run test
cd ${MY_PATH}
python run.py --type remote

# delete table
aws dynamodb delete-table --table-name Table0
aws dynamodb wait table-not-exists --table-name Table0

cd ${MY_PATH}
deactivate
rm -rf tmp
