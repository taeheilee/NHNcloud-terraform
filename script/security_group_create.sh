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

index=1
rule_index=1

rm -rf general_sg*.tf

# 보안그룹 생성 반복문
while true; do
  clear
  echo -e "${GREEN}보안 그룹 이름을 입력해주세요: ${BLUE}ex) ${client}-stg-01${NC}"
  read -p "$client-" general_sg_name

  # 보안그룹 파일 생성
  echo "resource \"nhncloud_networking_secgroup_v2\" \"resource-sg-${index}\" {" >> general_sg.tf
  echo "  name = \"\${var.client}-${general_sg_name}\"" >> general_sg.tf
  echo "}" >> general_sg.tf
  echo "" >> general_sg.tf
  echo " " >> logs/general_sg.log
  echo -e "general_sg - Name: ${BOLD}$client-$general_sg_name${NC}" >> logs/general_sg.log
  echo "++++++++++++++++++++++++++++++++++++++++++++" >> logs/general_sg.log
  rule_cout=1
  # 룰셋 생성 반복문
  while true; do
    clear
    echo -e "${GREEN}인바운드(ingress), 아웃바운드(egress) 둘 중 하나 선택해주세요.${NC}"
    read -p " ingress | egress: " general_gress
    read -p " Protocol을 입력해주세요 (tcp | udp): " general_protocol
    echo -e "${GREEN}Port 최소범위 최대범위 입력해주세요 (단일 포트라면 동일하게 입력).${NC}"
    read -p " port 최소 범위: " general_port_range_min
    read -p " port 최대 범위: " general_port_range_max
    echo -e "${BLUE}대상 IP CIDR를 입력해주세요 (예: 183.111.170.128/27)${NC}"
    read -p "대상 IP CIDR: " general_remote_ip_prefix
    read -p "비고란 입력: " general_description

    # 룰셋 파일에 추가
    echo "resource \"nhncloud_networking_secgroup_rule_v2\" \"resource-sg-rule-${rule_index}\" {" >> general_sg_rule.tf
    echo "  direction        = \"${general_gress}\"" >> general_sg_rule.tf
    echo "  protocol         = \"${general_protocol}\"" >> general_sg_rule.tf
    echo "  port_range_min   = ${general_port_range_min}" >> general_sg_rule.tf
    echo "  port_range_max   = ${general_port_range_max}" >> general_sg_rule.tf
    echo "  remote_ip_prefix = \"${general_remote_ip_prefix}\"" >> general_sg_rule.tf
    echo "  description      = \"${general_description}\"" >> general_sg_rule.tf
    echo "  security_group_id = nhncloud_networking_secgroup_v2.resource-sg-${index}.id" >> general_sg_rule.tf
    echo "}" >> general_sg_rule.tf
    echo "" >> general_sg_rule.tf

    # 로그에 기록
    echo "general_sg_rule_${rule_cout} - ${general_gress}|${general_protocol}|${general_port_range_min}~${general_port_range_max}|${general_remote_ip_prefix}|${general_description}" >> logs/general_sg.log

    # 추가 룰셋 생성 여부 확인
    read -p "추가 룰셋을 생성하시겠습니까? (y | n): " add_more_rule
    if [[ "$add_more_rule" == "y" || "$add_more_rule" == "yes" ]]; then
      ((rule_index++))
      ((rule_cout++))
      continue
    else
      break
    fi
  done
  # 최종 확인 단계
  echo -e "${GREEN}생성될 보안그룹 및 룰셋 목록:${NC}"
  cat logs/general_sg.log
  echo ""
  echo -e "${GREEN}리소스 생성 옵션을 선택하세요:${NC}"
  echo "  y: 추가 보안그룹 생성"
  echo "  n: 보안그룹 설정 초기화 후 재시작"
  echo "  c: 리소스 생성 완료 및 종료"
  read -p "옵션을 선택하세요 (y | n | c): " create_option
  if [[ "$create_option" == "y" ]]; then
    ((index++))
    ((rule_index++))
    echo "++++++++++++++++++++++++++++++++++++++++++++" >> logs/general_sg.log
  elif [[ "$create_option" == "n" ]]; then
    echo -e "${RED}리소스 생성이 취소되었습니다. 초기화 중...${NC}"
    rm -f logs/general_sg.log general_sg.tf general_sg_rule.tf
    rule_index=${save_rule_index}
    index=2
  elif [[ "$create_option" == "c" ]]; then
    echo -e "${GREEN}리소스 생성을 완료하고 종료합니다.${NC}"
    break
  else
    echo -e "${RED}잘못된 입력입니다. y, n 또는 c를 입력해주세요.${NC}"
    sleep 1
  fi
done

VAR_FILE="./variables.tfvars"

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
  rm -rf logs/general_sg.log
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
  rm -rf logs/general_sg.log
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
  rm -rf ./logs/general_sg.log
  exit 1
fi
echo -e "${GREEN}OK${NC} Saved logs/terraform_apply.log"
sleep 2

clear


# 보안 그룹 목록 
echo -e "${GREEN}CREATE RESOURCE${NC}"
echo ""
cat logs/general_sg.log

echo ""
read -p "다음으로 넘어 가기 Enter: "
clear