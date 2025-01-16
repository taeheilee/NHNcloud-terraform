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
PYTHON_CMD=$7
clear

rm -rf common_port.tf common_server.tf
# CIDR 값을 저장할 배열 선언
declare -a CIDRs

# 로그 파일에서 CIDR 값 추출 및 배열에 저장
cidr_index=1
while read -r line; do
  CIDR=$(echo "$line" | awk -F 'CIDR: ' '{print $2}' | cut -d '/' -f 1 | cut -d '.' -f 1-3)
  CIDRs+=("$CIDR")
  cidr_index=$((cidr_index + 1))
done < <(cat ./logs/network_resources.log | grep "Subnet")

echo "#!/bin/bash" >> connection_security_group.sh

declare -A instance_types=(
  ["1-1"]="t2c1m1"
  ["1-2"]="m2c1m2"
  ["4-8"]="m2c4m8"
  ["8-16"]="m2c8m16"
  ["16-32"]="m2c16m32"
  ["2-2"]="c2c2m2"
  ["2-4"]="m2c2m4"
  ["4-4"]="c2c4m4"
  ["8-8"]="c2c8m8"
  ["16-16"]="c2c16m16"
  ["2-8"]="r2c2m8"
  ["4-16"]="r2c4m16"
  ["4-32"]="r2c4m32"
  ["4-64"]="r2c4m64"
  ["8-32"]="r2c8m32"
  ["8-64"]="r2c8m64"
  ["16-64"]="x1c16m64"
  ["16-128"]="x1c16m128"
  ["32-128"]="x1c32m128"
  ["32-256"]="x1c32m256"
  ["64-256"]="x1c64m256"
)

server_index=2
# 서버 입력 받기 
while true; do
  clear
  boot_index=1
  echo -e "${GREEN}생성 할 서버 이름을 입력해주세요: ${BLUE}ex) ${client}-stg-01${NC}"
  read -p "${client}-" common_server_name
  clear
  $PYTHON_CMD ./python_code/find-keypair.py "$tenant_id" "$user_name" "$password" "$region" "$auth_url" > ./logs/find-keypair.log 2>&1 &
  echo -n "키 페어 목록 확인 중: "
  while kill -0 $! 2>/dev/null; do
    echo -n "█"
    sleep 0.2
  done
  echo -e "\n확인!"
  clear
  cat ./logs/find-keypair.log
  echo " "
  read -p "적용할 키 페어 이름을 입력 해주세요.: " common_keypair_name
  clear 
  rm -rf ./logs/find-security-group.log
  $PYTHON_CMD ./python_code/find-security-group.py "$tenant_id" "$user_name" "$password" "$region" "$auth_url" > ./logs/find-security-group.log 2>&1 &
  echo -n "보안그룹 목록 확인 중: "
  while kill -0 $! 2>/dev/null; do
    echo -n "█"
    sleep 0.2
  done
  echo -e "\n확인!"
  clear
  cat ./logs/find-security-group.log
  echo " "
  read -p "적용할 보안그룹 이름을 입력 해주세요.: " common_security_group
  clear 


  
    # 입력 반복문 시작
  while true; do
    clear
    # 사용자로부터 vCPU와 메모리 입력 받기
    echo -e "서버 사양을 입력해주세요 ${RED}(숫자만 입력)${NC}:"
    read -p "vCPU 코어 수: " vcpu
    read -p "memory 단위 (GB): " mem

    # 입력값을 키로 변환하여 인스턴스 타입 검색
    key="${vcpu}-${mem}"

    if [[ -n "${instance_types[$key]}" ]]; then
      common_instance_type="${instance_types[$key]}"
      echo -e "${GREEN}일치하는 인스턴스 타입을 확인 했습니다.${NC}"
      break  # 일치하는 인스턴스 타입을 찾았으므로 루프 종료
    else
      echo -e "${RED}일치하는 인스턴스 타입이 없습니다. 다시 입력해주세요.${NC}"
    fi
  done
  
  sleep 0.5
  $PYTHON_CMD ./python_code/images.py "$tenant_id" "$user_name" "$password" "$region" "$auth_url" > ./logs/images.log 2>&1 &
  echo -n "이미지 ID 확인 중: "
  while kill -0 $! 2>/dev/null; do
    echo -n "█"
    sleep 0.2
  done
  echo -e "\n확인!"
  clear
  cat ./logs/images.log
  echo -e "${GREEN}위에 목록에서 이미지 id를 입력해주세요${NC}"
  read -p " ex)7d4a1584-7df9-4437-9c99-4d97b0e16adb :" common_server_id
  clear
  
  echo -e "${GREEN}root 볼륨 type을 입력 해주세요${NC} ${RED}(대문자 입력)${NC}"
  read -p " ex)SSD | HDD :" common_server_volume_type
  

  echo -e "${GREEN}root 볼륨 Size를 입력 해주세요 ${NC} ${RED}(숫자만 입력)${NC}"
  read -p " 설정 가능한 사이즈 크기 (20 ~ 2000GB) :" common_server_size
  clear
  
  cat ./logs/network_resources.log | grep Subnet | sed 's/Subnet //g'
  echo -e "${GREEN}서버를 생성 할 Network 대역대의 번호를 입력해주세요"
  echo -e "${RED}첫 번째 숫자 번호만 입력${NC}"
  read -p " :" common_subnet_index
  clear


  echo -e "${GREEN}서버 IP를 입력해 주세요."
  echo -e "${BLUE} ex) ${CIDRs[$((common_subnet_index - 1))]}.10 ${NC}"
  read -p " :" common_IP
  
  echo "resource \"nhncloud_networking_port_v2\" \"port_$server_index\" {" >> common_port.tf
  echo "  name = \"tf_port_${server_index}\"" >> common_port.tf
  echo "  network_id = nhncloud_networking_vpc_v2.resource-vpc-01.id" >> common_port.tf
  echo "  fixed_ip {" >> common_port.tf
  echo "    subnet_id = nhncloud_networking_vpcsubnet_v2.resource-vpcsubnet-${common_subnet_index}.id" >> common_port.tf
  echo "    ip_address = \"${common_IP}\"" >> common_port.tf
  echo "  }" >> common_port.tf
  echo "}" >> common_port.tf


  echo "resource \"nhncloud_compute_instance_v2\" \"tf_instance_0${server_index}\" {" >> common_server.tf
  echo "  name      = \"\${var.client}-${common_server_name}\"" >> common_server.tf
  echo "  key_pair  = \"${common_keypair_name}\"" >> common_server.tf
  echo "  flavor_id = data.nhncloud_compute_flavor_v2.${common_instance_type}.id" >> common_server.tf
  echo "  security_groups = [\"default\", \"${common_security_group}\"]" >> common_server.tf
  echo "  network {" >> common_server.tf
  echo "    port = nhncloud_networking_port_v2.port_${server_index}.id" >> common_server.tf
  echo "  }" >> common_server.tf
  echo "  block_device {" >> common_server.tf
  echo "    uuid                  = \"${common_server_id}\"" >> common_server.tf
  echo "    volume_type           = \"General ${common_server_volume_type}\"" >> common_server.tf
  echo "    source_type           = \"image\"" >> common_server.tf
  echo "    destination_type      = \"volume\"" >> common_server.tf
  echo "    boot_index            = 0" >> common_server.tf
  echo "    volume_size           = ${common_server_size}" >> common_server.tf
  echo "    delete_on_termination = true" >> common_server.tf
  echo "  }" >> common_server.tf
  echo "${client}-${common_server_name}: " >> logs/common_instance.log
  echo "- Keypair: ${common_keypair_name}" >> logs/common_instance.log
  echo "- Security group: ${common_security_group}" >> logs/common_instance.log
  echo "- Instance type: ${vcpu}vCPU ${mem}GB" >> logs/common_instance.log
  echo "- Instance image:  $(cat logs/images.log | grep "${common_server_id}" | sed "s/id: ${common_server_id}, //g")" >> logs/common_instance.log
  echo "- Root volume type: ${common_server_volume_type}" >> logs/common_instance.log
  echo "- Root volume size: ${common_server_size} GB" >> logs/common_instance.log
  echo "- $(cat logs/network_resources.log | grep "Subnet ${common_subnet_index}")" >> logs/common_instance.log
  echo "- Fixed_ip: ${common_IP}" >> logs/common_instance.log
  echo " " >> logs/common_instance.log
  echo "$PYTHON_CMD ./python_code/connection_securitygroup.py "$tenant_id" "$user_name" "$password" "$region" "$auth_url" "$common_server_name" "$common_security_group" >> ./logs/conneciton_secritygroup.log 2>&1 &" >> connection_security_group.sh
  echo "pid${server_index}=\$!" >> connection_security_group.sh   
  echo "wait \$pid${server_index}" >> connection_security_group.sh  

  # 추가 디스크 생성 여부 확인
  while true; do
    echo -e "${GREEN}추가 스토리지를 생성하시겠습니까? (y/n)${NC}"
    read -p " :" add_disk

    if [[ "$add_disk" == "y" ]]; then
      echo -e "${GREEN}추가 스토리지 Volume type을 입력 해주세요${NC} ${RED}(대문자 입력)${NC}"
      read -p " ex)SSD | HDD: " add_volume_type
      echo -e "${GREEN}추가 스토리지 Volume Size를 입력 해주세요 ${NC} ${RED}(숫자만 입력)${NC}"
      read -p " ex)20 ~ 2000GB: " add_volume_size
      clear
      echo "  block_device {" >> common_server.tf
      echo "    source_type           = \"blank\"" >> common_server.tf
      echo "    volume_type           = \"General ${add_volume_type}\"" >> common_server.tf
      echo "    destination_type      = \"volume\"" >> common_server.tf
      echo "    boot_index            = ${boot_index}" >> common_server.tf
      echo "    volume_size           = ${add_volume_size}" >> common_server.tf
      echo "    delete_on_termination = true" >> common_server.tf
      echo "  }" >> common_server.tf
      
      echo "- ${boot_index} block volume type: ${add_volume_type}" >> logs/common_instance.log
      echo "- ${boot_index} block volume size: ${add_volume_size} GB" >> logs/common_instance.log
      echo " " >> logs/common_instance.log

      ((boot_index++))  # boot_index 증가
      continue  # 추가 입력을 위해 루프 계속
    elif [[ "$add_disk" == "n" ]]; then
      echo "}" >> common_server.tf
      break  # 추가 디스크 생성 루프 종료
    else
      echo "${RED}잘못된 입력입니다. y 또는 n을 입력해주세요.${NC}"
    fi
  done

  # 구성 확인
  clear
  
    # 최종 확인 단계
  while true; do
    clear
    echo -e "${GREEN}생성 될 베스천 서버 확인:${NC}"
    cat ./logs/common_instance.log
    echo " "
    echo "  y: 추가 서버 생성"
    echo "  n: 설정 값 초기화 (생성 단계로 돌아가기)"
    echo "  c: 서버 생성 진행"
    read -p "옵션을 선택하세요 (y | n | c): " create_option
    if [[ "$create_option" == "y" ]]; then
      ((server_index++))
      echo "++++++++++++++++++++++++++++++++++++++++++++" >> logs/common_instance.log  
      break
    elif [[ "$create_option" == "n" ]]; then
      echo -e "${RED}리소스 생성이 취소되었습니다. 초기화 중...${NC}"
      rm -f logs/common_instance.log.log common_port.tf common_server.tf connection_security_group.sh
      server_index=2
      echo "#!/bin/bash" >> connection_security_group.sh
      break
    elif [[ "$create_option" == "c" ]]; then
      echo -e "${GREEN}리소스 생성을 완료하고 종료합니다.${NC}"
      break 2  
    else
      echo -e "${RED}잘못된 입력입니다. y 또는 n을 입력해주세요.${NC}"
      sleep 1
    fi
  done
done

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
  rm -rf logs/common_instance.log
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
  rm -rf logs/common_instance.log
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
  rm -rf logs/common_instance.log
  exit 1
fi
echo -e "${GREEN}OK${NC} Saved logs/terraform_apply.log"
sleep 2

clear

bash ./connection_security_group.sh &
echo -n "서버에 보안 그룹 연결 중: "
while kill -0 $! 2>/dev/null; do
  echo -n "█"
  sleep 0.2
done
echo -e "\n확인!"

rm -rf connection_security_group.sh

clear
# 생성된 VPC와 서브넷 정보 출력
echo -e "${GREEN}CREATE RESOURCE${NC}"
echo ""
cat logs/common_instance.log
