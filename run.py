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
table = dynamodb.Table('BPSVVUFZ')

def print_table():
    scan = table.scan()
    for item in scan['Items']:
        #print(f"Att0={item['Att0']},Att1={item['Att1']}")
        print(item)

def clean_table():
    scan = table.scan()
    with table.batch_writer() as batch_writer:
        for item in scan['Items']:
            batch_writer.delete_item(Key={
                'Att0': item['Att0'],
                'Att1': item['Att1'],
            })

clean_table()

with table.batch_writer() as batch_writer:
    for i in range(4):
        for j in range(4):
            table.put_item(Item={'Att0':f'i{i}','Att1':f'j{j}'})

print_table()

query_ret = table.query(
    KeyConditionExpression=boto3.dynamodb.conditions.Key('Att0').eq('i0')
)
print(query_ret)

query_ret = table.query(
    IndexName='Index1',
    KeyConditionExpression=boto3.dynamodb.conditions.Key('Att1').eq('j0'),
)
print(query_ret)

clean_table()

with table.batch_writer() as batch_writer:
    for i in range(4):
        for j in range(4):
            table.put_item(Item={'Att0':f'i{i}','Att1':f'j{j}','Att2':f'k{i+j}'})

print_table()

clean_table()

print('=============')

with table.batch_writer() as batch_writer:
    for i in range(2):
        for j in range(2):
            table.put_item(Item={'Att0':f'i{i}','Att1':f'j{j}','Att2':f'k{i+j}'})

table.update_item(
    #Key={'Att0':{'S':'i0'},'Att1':{'S':'j0'}},
    Key={'Att0':'i0','Att1':'j0'},
    UpdateExpression='SET Att2 = :v',
    ExpressionAttributeValues={':v':'asdf'},
)

print_table()

clean_table()
