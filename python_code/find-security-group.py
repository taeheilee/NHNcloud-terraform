import requests
import json
import sys

def main():
  if len(sys.argv) != 6:
    print("Usage: python3 my_script.py <tenant_id> <user_name> <pass_word> <region> <auth_url>")
    sys.exit(1)

  tenant_Id = sys.argv[1]
  user_name = sys.argv[2]
  pass_word = sys.argv[3]
  region = sys.argv[4]
  auth_url = sys.argv[5]

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

  create_url = f"https://{rg}-api-network-infrastructure.gov-nhncloudservice.com/v2.0/security-groups"

  headers = {
    'X-Auth-Token': token_id,
    'Content-Type': 'application/json'
  }

  response = requests.request("get", create_url, headers=headers)

  if response.status_code == 200:
      # JSON 응답 파싱
      response_json = response.json()
      
      # security_groups에서 name 필드 값만 출력
      for security_group in response_json.get("security_groups", []):
          print(security_group.get("name"))
  else:
      print(f"Error: {response.status_code}")
      print(response.text)

if __name__ == "__main__":
  main()

