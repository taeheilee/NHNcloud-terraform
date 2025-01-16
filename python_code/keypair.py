import requests
import json
import sys

def main():
  if len(sys.argv) != 8:
    print("Usage: python3 my_script.py <tenant_id> <user_name> <pass_word> <client> <region> <auth_url> <keypair_name>")
    sys.exit(1)

  tenant_Id = sys.argv[1]
  user_name = sys.argv[2]
  pass_word = sys.argv[3]
  client_name = sys.argv[4]
  region = sys.argv[5]
  auth_url = sys.argv[6]
  keypair_name = sys.argv[7]

  project_name=f"{client_name}-{keypair_name}"

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

  create_url = f"https://{rg}-api-instance-infrastructure.gov-nhncloudservice.com/v2/{tenant_Id}/os-keypairs"

  payload = json.dumps({
    "keypair": {
    "name": project_name
    }
  })
  headers = {
    'X-Auth-Token': token_id,
    'Content-Type': 'application/json'
  }

  response = requests.request("POST", create_url, headers=headers, data=payload)

  if response.status_code == 200:
    # If the keypair creation is successful, extract the private key
    response_json = response.json()
    private_key = response_json['keypair']['private_key']
    
    # Save the private key to a file
    with open(f"{project_name}.key", "w") as f:
      f.write(private_key)
    print(f"Private key saved to {project_name}.key")
  else:
    print(f"Error: {response.status_code}")
    print(response.text)    

if __name__ == "__main__":
  main()

