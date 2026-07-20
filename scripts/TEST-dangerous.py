#!/usr/bin/env python3
"""TEST: Dangerous Python code — should be caught by Bandit + CodeQL + ci-scan."""

import os
import subprocess
import pickle

# Test: Command injection (Bandit: B602, B603, B604)
user_input = input("Enter command: ")
os.system(user_input)  # nosec — but should still raise alert in strict mode

# Test: Subprocess with shell=True (Bandit: B602)
subprocess.call(user_input, shell=True)
subprocess.run(["ls", "-la"], shell=True)

# Test: Hardcoded password (ci-scan T3.3)
DB_PASSWORD = "admin123456"

# Test: Insecure deserialization (Bandit: B301)
data = pickle.loads(b"cos\nsystem\n(S'cat /etc/passwd'\ntR.")

# Test: Weak crypto (Bandit: B303)
import hashlib
hashlib.md5(b"password")

# Test: eval (ci-scan T1.1)
eval("print('hello')")

# Test: Hardcoded API key (ci-scan T3.1)
API_KEY = "sk-proj-abcdefghijklmnopqrstuv"
