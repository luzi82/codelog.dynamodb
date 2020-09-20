import boto3
import argparse

CONF_DICT={
    'local':{
        'ENDPOINT_URL':'http://localhost:8000',
    },
    'remote':{
        'ENDPOINT_URL':None,
    },
}

parser = argparse.ArgumentParser()
parser.add_argument('--type', choices=['local','remote'])
args = parser.parse_args()

CONF = CONF_DICT[args.type]

dynamodb = boto3.resource('dynamodb', endpoint_url=CONF['ENDPOINT_URL'])
table0 = dynamodb.Table('Table0')

def print_table():
    scan = table0.scan()
    for item in scan['Items']:
        #print(f"Att0={item['Att0']},Att1={item['Att1']}")
        print(item)

def clean_table():
    scan = table0.scan()
    with table0.batch_writer() as batch_writer:
        for item in scan['Items']:
            batch_writer.delete_item(Key={
                'Att0': item['Att0'],
                'Att1': item['Att1'],
            })

clean_table()

with table0.batch_writer() as batch_writer:
    for i in range(4):
        for j in range(4):
            table0.put_item(Item={'Att0':f'i{i}','Att1':f'j{j}'})

print_table()

query_ret = table0.query(
    KeyConditions={
        'Att0':{
            'AttributeValueList':['i0'],
            'ComparisonOperator':'EQ',
        }
    },
)
print(query_ret)

query_ret = table0.query(
    IndexName='Index1',
    KeyConditions={
        'Att1':{
            'AttributeValueList':['j0'],
            'ComparisonOperator':'EQ',
        }
    },
)
print(query_ret)

clean_table()
