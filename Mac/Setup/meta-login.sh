#!/bin/bash
/usr/bin/expect <<'EOF'
set timeout 30
spawn meta auth
expect "Username:"
send "sachin61742026\r"
expect "Password:"
send "HELLOworld1@#\r"
expect eof
EOF
