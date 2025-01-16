import requests
import json
import sys

def main():
  if len(sys.argv) != 6:
    print("Usage: python3 my_script.py <tenant_id> <user_name> <pass_word> <client> <auth_url>")
    sys.exit(1)

  tenant_Id = sys.argv[1]
  user_name = sys.argv[2]
  pass_word = sys.argv[3]
  client_name = sys.argv[4]
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
  # HTTP POST 요청
  response = requests.post(url, headers=headers, data=payload)
  
  # 응답 상태 코드와 메시지 출력
  if response.status_code == 200:
    print("successfully!")
    print(response.json())
  else:
    print(f"Failed to authenticate. Status code: {response.status_code}")
    print(response.text)
    sys.exit(1)
    

if __name__ == "__main__":
    main()