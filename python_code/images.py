import requests
import json
import sys
import os

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
  search_names_1 = ["Rocky"]
  search_names_2 = ["Ubuntu"]
  search_names_3 = ["Windows"]

  create_url = f"https://{rg}-api-image-infrastructure.gov-nhncloudservice.com/v2/images"
  headers = {
    'X-Auth-Token': token_id,
    'Content-Type': 'application/json'
  }

    # 🔍 이미지 목록 가져오기
  response = requests.get(create_url, headers=headers)

  if response.status_code == 200:
    response_json = response.json()
    images = response_json.get("images", [])
    all_search_names = [search_names_1, search_names_2, search_names_3]
    group_names = ['Rocky', 'Ubuntu', 'Windows']  # 각 그룹의 이름

    # 중복된 이미지를 저장할 집합
    logged_images = set()
    logged_images = set()

    # 로그 파일을 열고, 각 검색 이름 목록에 대해 반복
    with open('logs/images.log', 'w') as log_file:
      for search_names, group_name in zip(all_search_names, group_names):
        filtered_images = [img for img in images if any(name.lower() in img['name'].lower() for name in search_names)]
        
        if filtered_images:
          # 그룹 시작 구분선 출력 (한 번만 출력)
          print(f"============================================{group_name}==============================================")
          log_file.write(f"============================================{group_name}==============================================\n")
          
          for image in filtered_images:
            # 중복된 이미지를 확인
            if image['id'] not in logged_images:
              print(f"id: {image['id']}, name: {image['name']}")
              log_file.write(f"id: {image['id']}, name: {image['name']}\n")
              logged_images.add(image['id'])  # 이미지를 로그에 추가
        else:
          print(f"No images found containing the specified names for {group_name}.")
  else:
    print(f"Error: {response.status_code}")
    print(response.text)
if __name__ == "__main__":
    main()

