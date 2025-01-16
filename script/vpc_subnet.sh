#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'
UNDERLINE='\033[4m'

tenant_id=$1
user_name=$2
password=$3
client=$4
region=$5
auth_url=$6


rm -rf vpc.tf subnet.tf

# VPC 생성 반복문문
while true; do
  # 사용자 입력 받기
  echo -e "${GREEN}VPC 이름을 입력해주세요: ${BLUE}ex) ${client}-${UNDERLINE}vpc-01${NC}"
  read -p "$client-" vpc_name
  echo " "
  echo -e "${GREEN}NHN에서 사용 가능 한 VPC 대역대는 아래와 같습니다. 이외에는 불가${NC}"
  echo -e "${BLUE}- 10.0.0.0/8~16${NC}" 
  echo -e "${BLUE}- 172.16.0.0/12~16${NC}" 
  echo -e "${BLUE}- 192.168.0.0/16${NC}"
  echo " "
  read -p "VPC CIDR 대역대 입력: " vpc_cidr
  clear
  
  # 변수 값 설정 파일에 추가
  echo "vpc_cidr = \"$vpc_cidr\"" >> ./variables.tfvars
  vpc_prefix=$(echo "$vpc_cidr" | cut -d'.' -f1-2)
  # 변수 파일에 추가
  echo "variable vpc_cidr {}" >> ./variables.tf
  echo " " >> "./logs/network_resources.log"
  echo "VPC - Name: $client-$vpc_name | CIDR: $vpc_cidr" >> "./logs/network_resources.log"
  echo " " >> "./logs/network_resources.log"
  echo "++++++++++++++++++++++++++++++++++++++++++++" >> "./logs/network_resources.log"
  echo " " >> "./logs/network_resources.log"

  # vpc.tf 파일에 VPC 리소스 추가
  echo 'resource "nhncloud_networking_vpc_v2" "resource-vpc-01" {' >> ./vpc.tf
  echo "  name   = \"\${var.client}-${vpc_name}\"" >> ./vpc.tf
  echo "  cidrv4 = var.vpc_cidr" >> ./vpc.tf
  echo '}' >> ./vpc.tf

  # Subnet 생성 반복문 시작
  index=1
  while true; do
    # 사용자 입력 받기
    clear
    echo -e "${GREEN}Subnet 이름을 입력해주세요${NC}"
    echo -e "${BLUE}ex) ${client}-${UNDERLINE}public-subnet-0$index ${NC}"
    echo -e "${BLUE}ex) ${client}-${UNDERLINE}private-subnet-0$index ${NC}"
    read -p "$client-" sub_name
    echo -e "${GREEN}Subnet CIDR을 입력해주세요 ${BLUE}ex) $vpc_prefix.$index.0/24 ${NC}" 
    read -p " :" sub_cidr

    # 파일에 서브넷 리소스 추가
    echo "resource \"nhncloud_networking_vpcsubnet_v2\" \"resource-vpcsubnet-$index\" {" >> ./subnet.tf
    echo "  name   = \"\${var.client}-${sub_name}\"" >> ./subnet.tf
    echo "  vpc_id = nhncloud_networking_vpc_v2.resource-vpc-01.id" >> ./subnet.tf
    echo "  cidr   = var.sub_cidr_$index" >> ./subnet.tf
    echo "}" >> ./subnet.tf
    echo "" >> ./subnet.tf

    # 변수 파일에 추가
    echo "variable sub_cidr_$index {}" >> ./variables.tf

    # 변수 값 설정 파일에 추가
    echo "sub_cidr_$index = \"$sub_cidr\"" >> ./variables.tfvars

    echo "Subnet $index - Name: $client-$sub_name | CIDR: $sub_cidr" >> "./logs/network_resources.log"

    # 추가 생성 여부 확인
    read -p "추가 서브넷을 생성하시겠습니까? (y | n): " add_more
    if [[ "$add_more" == "yes" || "$add_more" == "y" ]]; then
      echo " " 
    else
      break
    fi

    # 인덱스 증가
    ((index++))
  done

  # 최종 확인 단계
  while true; do
    clear
    echo -e "${GREEN}생성 될 네트워크 리소스 목록:${NC}"
    cat ./logs/network_resources.log
    echo " "

    read -p "위 리소스를 생성하시겠습니까? (y | n): " create_resources

    if [[ "$create_resources" == "y" || "$create_resources" == "yes" ]]; then
      break 2
    elif [[ "$create_resources" == "n" || "$create_resources" == "no" ]]; then
      echo -e "${RED}리소스 생성을 취소하고 VPC 생성 단계로 돌아갑니다.${NC}"
      
      # logs 파일 삭제리소스 생성을 취소하고 베스천 서버
      rm -f ./logs/network_resources.log
      rm -f ./subnet.tf
      rm -f ./vpc.tf

      # variables.tf: variable v, variable s로 시작하는 구문 삭제
      sed -i '/^variable v/d' ./variables.tf
      sed -i '/^variable s/d' ./variables.tf

      # variables.tfvars: vpc, sub로 시작하는 구문 삭제
      sed -i '/^vpc/d' ./variables.tfvars
      sed -i '/^sub/d' ./variables.tfvars
      break  # VPC 생성 단계로 돌아감
    else
      echo -e "${RED}잘못된 입력입니다. y 또는 n을 입력해주세요.${NC}"
      sleep 1  # 1초 대기 후 다시 반복
    fi 
  done
done

# 변수 파일 경로 확인
VAR_FILE="./variables.tfvars"

# terraform init 실행
clear
text="terraform init 실행 중..."
echo -n "$text"
terraform init -no-color >> ./logs/terraform_init.log 2>&1 &
pid=$!
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
  echo -e "${RED}Fail!${NC} Saved logs/terraform_init.log"
  rm -rf ./logs/network_resources.log
  exit 1
fi
echo -e "${GREEN}OK${NC} Saved logs/terraform_init.log"

# terraform plan 실행
text="terraform plan 실행 중..."
echo -n "$text"
terraform plan -var-file="$VAR_FILE" -no-color >> ./logs/terraform_plan.log 2>&1 &
pid=$!
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
  echo -e "${RED}Fail!${NC} Saved logs/terraform_plan.log"
  rm -rf ./logs/network_resources.log
  exit 1
fi
echo -e "${GREEN}OK${NC} Saved logs/terraform_plan.log"

# terraform apply 실행
text="terraform apply 실행 중..."
echo -n "$text"
terraform apply -var-file="$VAR_FILE" --auto-approve -no-color >> ./logs/terraform_apply.log 2>&1 &
pid=$!
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
  echo -e "${RED}Fail!${NC} Saved logs/terraform_apply.log"
  rm -rf ./logs/network_resources.log
  exit 1
fi
echo -e "${GREEN}OK${NC} Saved logs/terraform_apply.log"
sleep 2

clear
# 생성된 VPC와 서브넷 정보 출력
echo -e "${GREEN}CREATE RESOURCE${NC}"
echo ""
cat ./logs/network_resources.log

echo ""
read -p "다음으로 넘어 가기 Enter: "
clear
