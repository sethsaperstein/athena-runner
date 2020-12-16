import boto3
from json import load


def submit_query(event, context):
    print("Event:", event)
    query = event["query"]
    output_location = event["output_location"]
    client = boto3.client('athena')
    response = client.start_query_execution(
        QueryString=query,
        ResultConfiguration={
            'OutputLocation': output_location,
        }
    )
    query_execution_id = response['QueryExecutionId']

    return {"query_execution_id": query_execution_id}


def status_check(event, context):
    print("Event:", event)
    query_execution_id = event["query_execution_id"]
    client = boto3.client('athena')
    query_status = client.get_query_execution(QueryExecutionId=query_execution_id)
    query_execution_status = query_status['QueryExecution']['Status']['State']

    result = {
        "status": query_execution_status,
        "query_execution_id": query_execution_id
        }
    
    return result


def get_result(event, context):
    print("Event:", event)



if __name__ == "__main__":
    with open("test/resources/query.json") as f:
        event = load(f)
        result = submit_query(event)
