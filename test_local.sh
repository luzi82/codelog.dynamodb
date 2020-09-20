#!/bin/bash

set -e

export AWS_DEFAULT_REGION=us-west-2
TABLE_NAME=BPSVVUFZ

kill_pid() {
  if [ -f "$1" ];then
    kill `cat $1`
    rm $1
  fi
}

MY_PATH=${PWD}

cd ${MY_PATH}
kill_pid ${MY_PATH}/tmp/dynamodb.pid
rm -rf tmp

mkdir -p ${MY_PATH}/tmp
cd ${MY_PATH}/tmp
python3 -m venv venv-test
. venv-test/bin/activate
pip install -U pip wheel
pip install awscli boto3

mkdir -p ${MY_PATH}/tmp
cd ${MY_PATH}/tmp
wget https://s3.us-west-2.amazonaws.com/dynamodb-local/dynamodb_local_latest.tar.gz
wget https://s3.us-west-2.amazonaws.com/dynamodb-local/dynamodb_local_latest.tar.gz.sha256
TMP=`cat dynamodb_local_latest.tar.gz.sha256 | awk '{print $1}'`
echo "${TMP} dynamodb_local_latest.tar.gz" | sha256sum -c -

mkdir -p ${MY_PATH}/tmp/dynamodb_local
cd ${MY_PATH}/tmp/dynamodb_local
tar -xzvf ${MY_PATH}/tmp/dynamodb_local_latest.tar.gz

cd ${MY_PATH}/tmp
java -Djava.library.path=./dynamodb_local/DynamoDBLocal_lib -jar dynamodb_local/DynamoDBLocal.jar -inMemory &
echo $! > dynamodb.pid

# check if local dynamodb work
aws dynamodb list-tables --endpoint-url http://localhost:8000

# create table
aws dynamodb create-table \
    --table-name ${TABLE_NAME} \
    --attribute-definitions \
        AttributeName=Att0,AttributeType=S \
        AttributeName=Att1,AttributeType=S \
    --key-schema \
        AttributeName=Att0,KeyType=HASH \
        AttributeName=Att1,KeyType=RANGE \
    --global-secondary-indexes \
        IndexName=Index1,KeySchema=[\{AttributeName=Att1,KeyType=HASH\}],Projection=\{ProjectionType=KEYS_ONLY\} \
    --billing-mode PAY_PER_REQUEST \
    --endpoint-url http://localhost:8000
aws dynamodb wait table-exists \
    --table-name ${TABLE_NAME} \
    --endpoint-url http://localhost:8000

cd ${MY_PATH}
python run.py --type local

cd ${MY_PATH}
kill_pid ${MY_PATH}/tmp/dynamodb.pid
deactivate
rm -rf tmp
