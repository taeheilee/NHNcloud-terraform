import requests
import json
import sys

def main():
  if len(sys.argv) != 8:
    print("Usage: python3 my_script.py <tenant_id> <user_name> <pass_word> <region> <auth_url> <bastion_server_name> <bastion_security_group>")
    sys.exit(1)

  tenant_Id = sys.argv[1]
  user_name = sys.argv[2]
  pass_word = sys.argv[3]
  region = sys.argv[4]
  auth_url = sys.argv[5]
  bastion_server_name = sys.argv[6]
  bastion_security_group = sys.argv[7]

  # 토큰 발급
  url = f"{auth_url}/tokens"

  payload = json.dumps({
    "auth": {
      "tenantId": tenant_Id,
      "passwordCredentials": {
        "username": user_name,
        "password": pass_word
      }
    }
  })
  headers = {
    'Content-Type': 'application/json'
  }

  response = requests.request("POST", url, headers=headers, data=payload)

  if response.status_code == 200:
    # Parse the JSON response
    response_json = response.json()
    # Extract token.id from the response
    token_id = response_json['access']['token']['id']
  else:
    print(f"Error: {response.status_code}")
    print(response.text)
  # 키페어 생성

  # region 값에 따라 rg 값 설정
  region_mapping = {
  "KR1": "kr1",
  "KR2": "kr2"
  }
  rg = region_mapping.get(region.upper(), "unknown")  # 기본값: "unknown"

  create_url = f"https://{rg}-api-instance-infrastructure.gov-nhncloudservice.com/v2/{tenant_Id}/servers/detail?name={bastion_server_name}"

  headers = {
    'X-Auth-Token': token_id,
    'Content-Type': 'application/json'
  }

  response = requests.request("get", create_url, headers=headers)

  if response.status_code == 200:
    # JSON 응답을 파싱합니다.
    response_json = response.json()
    server_id = response_json['servers'][0]['id']
    # "id" 값을 추출합니다.
    print(f"Server ID: {server_id}")
  else:
    print("Request failed with status code:", response.status_code)
  
  
  create_url = f"https://{rg}-api-instance-infrastructure.gov-nhncloudservice.com/v2/{tenant_Id}/servers/{server_id}/action"

  headers = {
    'X-Auth-Token': token_id,
    'Content-Type': 'application/json'
  }
  payload = json.dumps({
    "addSecurityGroup": {
      "name": bastion_security_group
    }
  })
  response = requests.request("POST", create_url, headers=headers, data=payload)
  if response.status_code == 202:
    print("successfully!")
    if response.text.strip():  # 응답이 비어 있지 않은 경우
      try:
        print(response.json())  # JSON 응답 출력
      except requests.exceptions.JSONDecodeError:
        print("Response is not a valid JSON format.")
    else:
      print("Server returned an empty response.")
  else:
    print(f"Failed to authenticate. Status code: {response.status_code}")
    print(response.text)
    sys.exit(1)
if __name__ == "__main__":
  main()

