import boto3


def submit_query(event, context):
    print("submit_query")
    print(event)


def status_check(event, context):
    print("status_check")
    print(event)
    return {"status": "SUCCEEDED"}


def get_result(event, context):
    print("get_result")
    print(event)
