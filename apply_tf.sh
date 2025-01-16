#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'
UNDERLINE='\033[4m'
YELLOW='\033[0;33m'

echo "============================================================================="
echo " "
echo -e "${GREEN}python 설치되어 있지 않으면 스크립트 종료${NC}"
echo " "
echo "============================================================================="

echo -n "파이썬 확인 중: "
for i in {1..10}; do
  echo -n "█"
  sleep 0.2
done

# Python 실행 명령어 감지
if command -v python3 > /dev/null 2>&1; then
  PYTHON_CMD="python3"
elif command -v python > /dev/null 2>&1; then
  PYTHON_CMD="python"
else
  echo -e "${RED}python 설치 필요${NC}"
  exit 1
fi
echo ""
echo -e "${GREEN}완료!${NC}"
echo ""
read -p "다음으로 넘어 가기 Enter: "

clear

while true; do
  if [ ! -f "variables.tfvars" ]; then
    
    rm -rf vpc.tf subnet.tf
    rm -rf .terraform*
    rm -rf ./logs/*
    rm -rf bastion*tf
    rm -rf general*tf
    rm -rf common*tf

    cat > variables.tf <<EOF
variable username {}
variable tenantid {}
variable Password {}
variable authurl {}
variable Region {}
variable client {}
EOF

    # 사용자 입력 받기
    echo "======================================================================================================================="
    echo " "
    echo -e "${GREEN}nhn 서버 구성 스크립트${NC}"
    echo -e "${GREEN}https://docs.nhncloud.com/ko/Compute/Instance/ko/terraform-guide/ 참고${NC}"
    echo " "
    echo "======================================================================================================================="
    echo -e "${BLUE}(ex) thlee, mjwon, eccho): ${NC}"
    read -p "NHN Cloud ID 입력 :" user_name
    clear

    echo "======================================================================================================================="
    echo " "
    echo -e "${GREEN}NHN Cloud 콘솔의 Compute > Instance > 관리 메뉴에서 API 엔드포인트 설정 버튼을 클릭해 테넌트 ID를 확인합니다.${NC}"
    echo " "
    echo "======================================================================================================================="
    read -p "tenant_id 입력 : " tenant_id
    clear

    echo "======================================================================================================================="
    echo " "
    echo -e "${GREEN}API Endpoint 설정 대화 상자에서 저장한 API 비밀번호를 사용합니다.${NC}"
    echo -e "${GREEN}API 비밀번호 설정 방법은 사용자 가이드 > Compute > Instance > API 사용 준비를 참고합니다.${NC}"
    echo " "
    echo "======================================================================================================================="
    read -p "password 입력: " password
    clear

    echo "======================================================================================================================="
    echo " "
    echo -e "${GREEN}NHN Cloud 신원 서비스 주소를 명시합니다.${NC}"
    echo -e "${GREEN}NHN Cloud 콘솔의 Compute > Instance > 관리 메뉴에서 API 엔드포인트 설정 버튼을 클릭해 신원 서비스(identity) URL을 확인합니다.${NC}"
    echo " "
    echo "======================================================================================================================="
    read -p "auth_url 입력: " auth_url
    clear

    echo "======================================================================================================================="
    echo " "
    echo -e "${GREEN}NHN Cloud 리소스를 관리할 리전 정보를 입력합니다.${NC}"
    echo " "
    echo "======================================================================================================================="
    echo -e "${BLUE}ex) KR1 판교, KR2 평촌, JP1 일본${NC}"
    # 리전 입력받기

    while true; do
      read -p "region 입력: " region
      
      # 유효한 리전 체크 (KR1, KR2, JP1만 허용)
      if [[ "$region" == "KR1" || "$region" == "KR2" || "$region" == "JP1" ]]; then
        break
      else
        echo -e "${RED}잘못된 입력입니다. KR1, KR2, JP1 중에서 선택해주세요.${NC}"
      fi
    done

    clear
    ## 볼드처리로 변경경
    echo "======================================================================================================================="
    echo " "
    echo -e "${GREEN}입력받은 고객사 명은 모든 자원 이름 앞에 붙게 됩니다.${NC}"
    echo -e "${GREEN}ex) ${BOLD}${UNDERLINE}pomia${NC}${GREEN}-vpc-01 ${BOLD}${UNDERLINE}pomia${NC}${GREEN}-private-subnet-01 ${BOLD}${UNDERLINE}pomia${NC}${GREEN}-private-subnet-02${NC}"
    echo " "
    echo "======================================================================================================================="
    read -p "고객사 명을 입력해주세요(자원 생성 시 사용 할 이름): " client
    clear 
    cat > variables.tfvars <<EOF
username = "$user_name"
tenantid = "$tenant_id"
Password = "$password"
authurl = "$auth_url"
Region = "$region"
client = "$client"
EOF

    break  
  else
    echo -e "${GREEN}variables.tfvars 파일이 존재합니다. 초기화 하시겠습니까? ${NC}(y/n)  " 
    echo "   y - provider 초기화 후 재시작"
    echo "   n - 자격인증 시작"
    read -p ": " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
      clear
      rm -rf vpc.tf subnet.tf
      rm -rf .terraform*
      rm -rf ./logs/*
      rm -rf bastion*tf
      rm -rf general*tf
      rm -rf common*tf

      cat > variables.tf <<EOF
variable username {}
variable tenantid {}
variable Password {}
variable authurl {}
variable Region {}
variable client {}
EOF

      # 사용자 입력 받기
      echo "======================================================================================================================="
      echo " "
      echo -e "${GREEN}nhn 서버 구성 스크립트${NC}"
      echo -e "${GREEN}https://docs.nhncloud.com/ko/Compute/Instance/ko/terraform-guide/ 참고${NC}"
      echo " "
      echo "======================================================================================================================="
      echo -e "${BLUE}(ex) thlee, mjwon, eccho): ${NC}"
      read -p "NHN Cloud ID 입력 :" user_name
      clear

      echo "======================================================================================================================="
      echo " "
      echo -e "${GREEN}NHN Cloud 콘솔의 Compute > Instance > 관리 메뉴에서 API 엔드포인트 설정 버튼을 클릭해 테넌트 ID를 확인합니다.${NC}"
      echo " "
      echo "======================================================================================================================="
      read -p "tenant_id 입력 : " tenant_id
      clear

      echo "======================================================================================================================="
      echo " "
      echo -e "${GREEN}API Endpoint 설정 대화 상자에서 저장한 API 비밀번호를 사용합니다.${NC}"
      echo -e "${GREEN}API 비밀번호 설정 방법은 사용자 가이드 > Compute > Instance > API 사용 준비를 참고합니다.${NC}"
      echo " "
      echo "======================================================================================================================="
      read -p "password 입력: " password
      clear

      echo "======================================================================================================================="
      echo " "
      echo -e "${GREEN}NHN Cloud 신원 서비스 주소를 명시합니다.${NC}"
      echo -e "${GREEN}NHN Cloud 콘솔의 Compute > Instance > 관리 메뉴에서 API 엔드포인트 설정 버튼을 클릭해 신원 서비스(identity) URL을 확인합니다.${NC}"
      echo " "
      echo "======================================================================================================================="
      read -p "auth_url 입력: " auth_url
      clear

      echo "======================================================================================================================="
      echo " "
      echo -e "${GREEN}NHN Cloud 리소스를 관리할 리전 정보를 입력합니다.${NC}"
      echo " "
      echo "======================================================================================================================="
      echo -e "${BLUE}ex) KR1 판교, KR2 평촌, JP1 일본${NC}"
      # 리전 입력받기

      while true; do
        read -p "region 입력: " region
        
        # 유효한 리전 체크 (KR1, KR2, JP1만 허용)
        if [[ "$region" == "KR1" || "$region" == "KR2" || "$region" == "JP1" ]]; then
          break
        else
          echo -e "${RED}잘못된 입력입니다. KR1, KR2, JP1 중에서 선택해주세요.${NC}"
        fi
      done

      clear
      ## 볼드처리로 변경경
      echo "======================================================================================================================="
      echo " "
      echo -e "${GREEN}입력받은 고객사 명은 모든 자원 이름 앞에 붙게 됩니다.${NC}"
      echo -e "${GREEN}ex) ${BOLD}${UNDERLINE}pomia${NC}${GREEN}-vpc-01 ${BOLD}${UNDERLINE}pomia${NC}${GREEN}-private-subnet-01 ${BOLD}${UNDERLINE}pomia${NC}${GREEN}-private-subnet-02${NC}"
      echo " "
      echo "======================================================================================================================="
      read -p "고객사 명을 입력해주세요(자원 생성 시 사용 할 이름): " client
      clear 
      cat > variables.tfvars <<EOF
username = "$user_name"
tenantid = "$tenant_id"
Password = "$password"
authurl = "$auth_url"
Region = "$region"
client = "$client"
EOF
      break  
    elif [[ "$choice" == "n" || "$choice" == "N" ]]; then
      while IFS= read -r line; do
        # 공백을 제거하고, '=' 앞뒤 공백을 제거한 후 eval 사용
        line=$(echo $line | tr -d ' ')

        # '='이 있을 경우만 변수로 설정
        if [[ "$line" == *=* ]]; then
          eval "$line"
        fi
      done < variables.tfvars
      user_name=$username
      tenant_id=$tenantid 
      password=$Password
      auth_url=$authurl
      region=$Region
      client=$client
      break  # End loop if user chooses no
      clear
    else
      echo "다시 입력해 주시기 바랍니다. 'y' or 'n'."
    fi
  fi
done

text="자격 인증 확인 중..."
$PYTHON_CMD ./python_code/provider.py "$tenant_id" "$user_name" "$password" "$client" "$auth_url" > ./logs/provider.log 2>&1 &
pid=$!  # 백그라운드에서 실행 중인 provider.py 프로세스의 PID 저장

while true; do
    for i in {1..3}; do
        echo -ne "\r$text$(printf '.%.0s' $(seq 1 $i))"
        sleep 0.5
    done

    # provider.py가 종료되었는지 확인
    if ! ps -p $pid > /dev/null; then
        break
    fi
    echo ""  # 로딩이 끝난 후 새로운 줄을 출력
done

# provider.py가 성공적으로 실행되었는지 확인
wait $pid
exit_code=$?

if grep -q "successfully" ./logs/provider.log; then
  echo -e " \n"
  echo -e "${GREEN}자격인증 성공${NC} Saved logs/provider.log"
else
  echo -e " \n"
  echo -e "${RED}자격인증 실패${NC} Saved logs/provider.log"
  exit 1
fi

echo ""
read -p "다음으로 넘어 가기 Enter: "
clear
while true; do
  echo -e "${GREEN} VPC / Subnet을 생성 하시겠습니까? ${NC}(y/n) "
  echo "  y - VPC / Subnet 생성"
  echo "  n - 건너 띄기"
  read -p ": " create_network

  if [[ "$create_network" == "yes" || "$create_network" == "y" ]]; then
    while true; do
      bash ./script/vpc_subnet.sh "$tenant_id" "$user_name" "$password" "$client" "$region" "$auth_url"
      if [ $? -ne 0 ]; then
        exit 1
      fi
      break 2
    done
  else
    break 
  fi
done
clear
# 사용자 입력 받기
echo "======================================================================================================================="
echo " "
echo -e "${GREEN}※일본 리전은 생성이 불가능합니다.${NC}"
echo " "
echo "======================================================================================================================="
while true; do
  read -p "Key pair를 생성 하시겠습니까? (yes | no): " create_keypair

  if [[ "$create_keypair" == "yes" || "$create_keypair" == "y" ]]; then
    while true; do
      # Key Pair 이름 입력받기
      clear
      echo -e "${GREEN}key Pair 이름을 입력해주세요: ${BLUE}ex) ${client}-stg-key${NC}"
      read -p "${client}-" keypair_name
      text="키 페어 생성 중..."
      echo -n "$text"

      # Python 스크립트 실행
      $PYTHON_CMD ./python_code/keypair.py "$tenant_id" "$user_name" "$password" "$client" "$region" "$auth_url" "$keypair_name" >> ./logs/keypair.log 2>&1 &
      pid=$!

      # 프로세스 상태 확인
      while true; do
        for i in {1..3}; do
          echo -ne "\r$text$(printf '.%.0s' $(seq 1 $i))"
          sleep 0.5
        done
        if ! ps -p $pid > /dev/null; then
          break
        fi
      done

      wait $pid

      if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to execute keypair.py${NC} Saved logs/keypair.log"
        exit 1
      else
        echo -e "${GREEN}Python script executed successfully${NC} Saved logs/keypair.log"
        echo "Private key saved to ${client}-${keypair_name}.key"
      fi
      mv *.key keyfile/
      # 추가 생성 여부 묻기
      read -p "추가로 Key Pair를 생성하시겠습니까? (yes | no): " continue_create
      if [[ "$continue_create" != "yes" && "$continue_create" != "y" ]]; then
        break 2
      fi
    done
  else
      break 
  fi
done

clear
while true; do
  echo -e "${GREEN} 보안 그룹을 생성 하시겠습니까? ${NC}(y/n) "
  echo "  y - 보안 그룹 생성"
  echo "  n - 건너 띄기"
  read -p ": " create_sg

  if [[ "$create_sg" == "yes" || "$create_sg" == "y" ]]; then
    while true; do
      bash ./script/security_group_create.sh "$tenant_id" "$user_name" "$password" "$client" "$region" "$auth_url"
      if [ $? -ne 0 ]; then
        exit 1
      fi
      break 2
    done
  else
    break 
  fi
done

clear
while true; do
  echo "============================================================================="
  echo " "
  echo -e "${GREEN}NHN 클라우드 공인 IP는 Well-Known Port가 기본적으로 막혀있습니다.${NC}"
  echo -e "${BLUE}SSLVPN 구성 방식은 복잡 하오니 베스천 서버 사용 권장${NC}"
  echo " "
  echo "============================================================================="
  echo -e "${GREEN} 베스천 서버를 생성 하시겠습니까? ${NC}(y/n) "
  echo "  y - 베스천 서버 생성"
  echo "  n - 건너 띄기"
  read -p ": " create_bastion

  if [[ "$create_bastion" == "yes" || "$create_bastion" == "y" ]]; then
    while true; do
      bash ./script/bastion_create.sh "$tenant_id" "$user_name" "$password" "$client" "$region" "$auth_url" "$PYTHON_CMD"
      if [ $? -ne 0 ]; then
        exit 1
      fi
      break 2
    done
  else
    break 
  fi
done

clear
while true; do
  echo -e "${GREEN} 일반 서버를 생성 하시겠습니까? ${NC}(y/n) "
  echo "  y - 일반 서버 생성"
  echo "  n - 건너 띄기"
  read -p ": " create_server

  if [[ "$create_server" == "yes" || "$create_server" == "y" ]]; then
    while true; do
      bash ./script/server_create.sh "$tenant_id" "$user_name" "$password" "$client" "$region" "$auth_url" "$PYTHON_CMD"
      if [ $? -ne 0 ]; then
        exit 1
      fi
      break 2
    done
  else
    break 
  fi
done

echo ""
read -p "다음으로 넘어 가기 Enter: "
clear

# Output each configuration file and its description
echo -e "${GREEN}vpc.tf                 -> VPC 설정${NC}"
echo -e "${GREEN}subnet.tf              -> Subnet 설정${NC}"
echo -e "${GREEN}general_sg.tf          -> 보안그룹 설정${NC}"
echo -e "${GREEN}general_sg_rule.tf     -> 보안그룹 규칙 설정${NC}"
echo -e "${GREEN}bastion_port.tf        -> 베스천 서버 IP 설정${NC}"
echo -e "${GREEN}bastion_server.tf      -> 베스천 서버 설정${NC}"
echo -e "${GREEN}common_port.tf         -> 일반 서버 IP 설정${NC}"
echo -e "${GREEN}common_server.tf       -> 일반 서버 설정${NC}"
echo -e "${GREEN}/key file storage location -> Key File 저장 공간${NC}"

# Terraform plan and apply commands
echo -e "${YELLOW}Terraform 자원 수정 명령어:${NC}"
echo -e "${GREEN}terraform plan -var-file=\"variables.tfvars\" && terraform apply -var-file=\"variables.tfvars\"${NC}"

# Terraform destroy command
echo -e "${YELLOW}Terraform 자원 삭제 명령어:${NC}"
echo -e "${GREEN}terraform destroy -var-file=\"variables.tfvars\"${NC}"

# API note for the Internet Gateway
echo -e "${RED}Please note:${NC}"
echo -e "${RED}인터넷 게이트웨이 부터는 api가 없어서 더이상 진행이 불가합니다.${NC}"
echo -e "${YELLOW}수동으로 생성해서 사용해주시기 바랍니다.${NC}"



echo ""
read -p " 종료: Enter"
clear
