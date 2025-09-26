import boto3
import json
import os
import time
import requests

athena = boto3.client("athena")
bedrock = boto3.client("bedrock-runtime")

ATHENA_DB = os.environ.get("ATHENA_DB")
ATHENA_TABLE = os.environ.get("ATHENA_TABLE")
ATHENA_OUTPUT = os.environ.get("ATHENA_OUTPUT")  
SLACK_WEBHOOK_URL = os.environ.get("SLACK_WEBHOOK_URL")

def run_athena_query(query):
    response = athena.start_query_execution(
        QueryString=query,
        QueryExecutionContext={"Database": ATHENA_DB},
        ResultConfiguration={"OutputLocation": ATHENA_OUTPUT},
    )
    query_execution_id = response["QueryExecutionId"]

    while True:
        status = athena.get_query_execution(QueryExecutionId=query_execution_id)
        state = status["QueryExecution"]["Status"]["State"]
        if state in ["SUCCEEDED", "FAILED", "CANCELLED"]:
            break
        time.sleep(1)

    if state != "SUCCEEDED":
        Exception(f"Athena query failed with state: {state}")

    result = athena.get_query_results(QueryExecutionId=query_execution_id)
    rows = result["ResultSet"]["Rows"]
    header = [col["VarCharValue"] for col in rows[0]["Data"]]
    data = [
        dict(zip(header, [col.get("VarCharValue", "") for col in row["Data"]]))
        for row in rows[1:]
    ]
    return data

def invoke_bedrock(prompt, max_retries=3):
    payload = {
        "messages": [{"role": "user", "content": [{"text": prompt}]}],
        "inferenceConfig": {"temperature": 0.3, "topP": 0.9, "maxTokens": 1000}
    }

    for attempt in range(max_retries):
        try:
            response = bedrock.invoke_model(
                modelId="amazon.nova-lite-v1:0",
                contentType="application/json",
                accept="application/json",
                body=json.dumps(payload)
            )
            result = json.loads(response["body"].read().decode("utf-8"))
            message = result["output"]["message"]["content"][0]["text"]

            if "blocked by our content filters" in message.lower():
                print(f"[WARN] Content blocked (attempt {attempt+1}): {message}")
                time.sleep(1)
                continue 
            
            return message 
        
        except Exception as e:
            print(f"[WARN] Bedrock failed (attempt {attempt+1}): {e}")
            time.sleep(1)
    raise Exception("Bedrock failed after retries")

def lambda_handler(event, context):
    query = f"""
        SELECT 
            "id.orig_h" AS source_ip,
            method,
            status_code,
            COUNT(*) AS count,
            'anomaly_method' AS reason
        FROM {ATHENA_TABLE}
        WHERE method NOT IN ('GET', 'POST')
        GROUP BY "id.orig_h", method, status_code

        UNION ALL

        SELECT 
            "id.orig_h" AS source_ip,
            method,
            status_code,
            COUNT(*) AS count,
            'mass_access' AS reason
        FROM {ATHENA_TABLE}
        GROUP BY "id.orig_h", method, status_code
        HAVING COUNT(*) > 100
    """

    records = run_athena_query(query)
    print("=== records ===")
    print(records)

    prompt_lines = [
        "以下はシステム動作の分析支援を目的とした出力で、HTTPメソッド、ステータスコード、送信元IP別に集計したアクセス件数の一覧です。\n"
        "このデータをもとに、セキュリティ的に不審なアクセスパターンがないかを分析してください。\n"
        "・異常なアクセス傾向（例：不審なメソッド、エラーステータスの多発）\n"
        "・全体と比較して突出した件数のIPアドレスの存在\n"
        "・その他、不自然な挙動\n"
        "これらの観点で簡潔に要点をまとめてください。\n"
        "```\n["
    ]
    
    for record in records:
        status_code = (
            int(record["status_code"])
            if record["status_code"].isdigit()
            else None
    )
        prompt_lines.append(json.dumps({
            "method": record["method"],
            "status_code": status_code,
            "source_ip": record["source_ip"], 
            "count": int(record["count"])
        }) + ",")

    prompt_lines.append("]\n```")
    prompt = "\n".join(prompt_lines)
    summary = invoke_bedrock(prompt)

    if SLACK_WEBHOOK_URL:
        requests.post(SLACK_WEBHOOK_URL, json={"text": summary})
    else:
        print("Slack Webhook URL is not set.")

    return {"statusCode": 200, "body": "完了"}


