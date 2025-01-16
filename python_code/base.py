import base64

# 인코딩할 Bash 스크립트
bash_script = """#!/bin/bash
num=$(cat /etc/ssh/sshd_config | grep -n "Port 22" | cut -d ":" -f 1)
sed -i "${num}d;" /etc/ssh/sshd_config
sed -i "${num}a Port 50022" /etc/ssh/sshd_config
systemctl restart sshd
"""

# 문자열을 바이트로 변환
byte_script = bash_script.encode('utf-8')
# Base64 인코딩
base64_encoded_script = base64.b64encode(byte_script)
# 바이트를 문자열로 변환
base64_string = base64_encoded_script.decode('utf-8')

print(base64_string)