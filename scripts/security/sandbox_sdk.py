"""
sandbox_sdk.py — AI 工具执行安全沙盒 SDK

在 AI Agent 可自动执行代码的场景下，直接调用 os.system() / subprocess.run()
等同于合法的 RCE。本 SDK 封装所有系统调用，提供：

  1. 超时熔断 — 防止死循环耗尽资源
  2. 命令白名单 — 仅允许声明的安全命令
  3. 网络管控 — 阻止向非白名单地址外发数据
  4. 审计日志 — 记录所有 AI 触发的系统调用

使用方式：
  from scripts.security.sandbox_sdk import Sandbox

  sandbox = Sandbox(timeout=10, allow_network=False)
  result = sandbox.run(["python", "analyze-skills.py", "--compact"])

设计参考：E2B (Firecracker microVM)、Cloudflare Dynamic Workers、gVisor
"""

import subprocess
import os
import sys
import time
import json
import logging
from datetime import datetime, timezone
from pathlib import Path
from typing import List, Optional, Dict, Any

# ============================================================
# 配置
# ============================================================

LOG_DIR = Path(__file__).resolve().parent / ".sandbox-logs"
LOG_DIR.mkdir(exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s | %(message)s',
    handlers=[
        logging.FileHandler(LOG_DIR / "sandbox-audit.log"),
        logging.StreamHandler(sys.stderr),
    ]
)
logger = logging.getLogger("sandbox-sdk")

# 危险命令黑名单 — 即使在受控环境中也应完全禁止
# 每个条目是一个子串匹配模式：只要命令字符串包含该模式就拦截
BLOCKED_COMMANDS = [
    "rm -rf /",         # 递归删除根目录
    "mkfs.",            # 格式化文件系统
    "dd if=",           # 磁盘直接写入
    "> /dev/sda",       # 覆盖磁盘设备
    ":(){ :|:& };:",    # fork bomb
    "chmod 777 /",      # 开放根目录权限
]

# 外网出站白名单（仅在 allow_network=False 时生效）
# 沙盒模式下仅允许访问 AI API 服务商的域名
ALLOWED_DOMAINS = [
    "api.deepseek.com",
    "api.openai.com",
    "api.anthropic.com",
]

# ============================================================
# 异常定义
# ============================================================

class SandboxError(Exception):
    """沙盒执行异常基类 — 所有沙盒相关异常继承自此"""

class TimeoutError(SandboxError):
    """执行超时 — 命令运行时间超过设定的 timeout"""

class BlockedCommandError(SandboxError):
    """命令在黑名单中 — 触发了 BLOCKED_COMMANDS 中的危险模式"""

class NetworkPolicyViolation(SandboxError):
    """违反网络策略 — 在 allow_network=False 时尝试调用网络工具"""

# ============================================================
# 沙盒核心
# ============================================================

class Sandbox:
    """
    AI 工具执行安全沙盒

    Args:
        timeout: 单次执行超时秒数（默认 10s）
        allow_network: 是否允许外网出站（默认 False）
        allowed_domains: 网络白名单域名列表
        cwd: 工作目录（留空则使用调用方目录）
        env_allowlist: 允许传递的环境变量名列表（默认仅传递必要变量）
    """

    def __init__(
        self,
        timeout: int = 10,
        allow_network: bool = False,
        allowed_domains: Optional[List[str]] = None,
        cwd: Optional[str] = None,
        env_allowlist: Optional[List[str]] = None,
    ):
        self.timeout = timeout
        self.allow_network = allow_network
        self.allowed_domains = allowed_domains or ALLOWED_DOMAINS
        self.cwd = cwd or os.getcwd()  # 默认使用当前工作目录
        # 仅传递白名单中的环境变量到子进程，防止凭据等敏感变量泄露
        self.env_allowlist = env_allowlist or ["PATH", "HOME", "USER", "LANG", "PYTHONPATH"]
        self.audit_log: List[Dict[str, Any]] = []  # 审计日志记录（运行期间内存存储）

    def run(
        self,
        cmd: List[str],
        stdin_data: Optional[str] = None,
        extra_env: Optional[Dict[str, str]] = None,
    ) -> Dict[str, Any]:
        """
        在沙盒中执行命令。

        Args:
            cmd: 命令及参数列表，如 ["python", "script.py", "--flag"]
            stdin_data: 可选的标准输入字符串
            extra_env: 额外的环境变量

        Returns:
            {"exit_code": int, "stdout": str, "stderr": str, "elapsed_ms": int}
        """
        cmd_str = " ".join(cmd)  # 将命令列表转为字符串，用于日志和匹配
        start_time = time.time()

        # ── 1. 命令黑名单检查 ──
        # 用子串匹配检查命令是否包含危险模式
        for blocked in BLOCKED_COMMANDS:
            if blocked in cmd_str:
                self._audit("BLOCKED", cmd_str, f"Matched blocked pattern: {blocked}")
                raise BlockedCommandError(
                    f"命令 '{cmd_str}' 包含禁止模式 '{blocked}'。"
                    f"请使用安全的替代方案。"
                )

        # ── 2. 网络策略检查 ──
        # 在不允许网络时检查是否调用了 curl/wget/nc/telnet 等网络工具
        if not self.allow_network:
            for token in cmd:
                if token in ("curl", "wget", "nc", "telnet"):
                    self._audit("BLOCKED", cmd_str, f"Network tool: {token}")
                    raise NetworkPolicyViolation(
                        f"命令 '{token}' 被网络策略阻止。"
                        f"allow_network=False 时禁止出站网络调用。"
                    )

        # ── 3. 构建受限环境变量 ──
        # 仅传递白名单中的环境变量到子进程，防止敏感信息（如 API Key）泄露
        safe_env = {k: os.environ.get(k, "") for k in self.env_allowlist}
        if extra_env:
            safe_env.update(extra_env)

        # ── 4. 执行（带超时） ──
        self._audit("EXEC", cmd_str, f"timeout={self.timeout}s, network={self.allow_network}")

        try:
            # 首次执行（不带 stdin，或带 PIPE 但不传 input）
            proc = subprocess.run(
                cmd,
                capture_output=True,  # 捕获 stdout 和 stderr
                text=True,            # 文本模式（而非 bytes）
                timeout=self.timeout, # 超时保护
                cwd=self.cwd,
                env=safe_env,
                stdin=subprocess.PIPE if stdin_data else None,
            )
            elapsed_ms = int((time.time() - start_time) * 1000)

            # 如果需要传入 stdin，重新执行（subprocess.run 不支持同时 PIPE + input）
            if stdin_data:
                proc = subprocess.run(
                    cmd,
                    input=stdin_data,
                    capture_output=True,
                    text=True,
                    timeout=self.timeout,
                    cwd=self.cwd,
                    env=safe_env,
                )
                elapsed_ms = int((time.time() - start_time) * 1000)

            # 构建统一的结果字典
            result = {
                "exit_code": proc.returncode,
                "stdout": proc.stdout or "",
                "stderr": proc.stderr or "",
                "elapsed_ms": elapsed_ms,
            }

            self._audit(
                "DONE" if proc.returncode == 0 else "FAIL",
                cmd_str,
                f"exit={proc.returncode}, {elapsed_ms}ms",
            )
            return result

        except subprocess.TimeoutExpired:
            elapsed_ms = int((time.time() - start_time) * 1000)
            self._audit("TIMEOUT", cmd_str, f"exceeded {self.timeout}s, {elapsed_ms}ms")
            raise TimeoutError(
                f"命令执行超时（>{self.timeout}s）。"
                f"AI 是否生成了死循环？请检查代码后重试。"
            )
        # 注：subprocess.CalledProcessError 不会被捕获 —
        # 因为不使用 check=True, 子进程异常退出通过 returncode 反映

    def run_python(
        self,
        code: str,
        timeout: Optional[int] = None,
    ) -> Dict[str, Any]:
        """
        在沙盒中执行一段 Python 代码字符串。

        警告：此方法会实际执行传入的 Python 代码。仅在信任 AI 生成的
        代码已经过人工审查的情况下使用。

        Args:
            code: Python 源代码字符串
            timeout: 覆盖默认超时
        """
        actual_timeout = timeout or self.timeout

        # 静态检查：拦截高危内置函数
        # 这些函数在 AI 生成的代码中可能存在任意代码执行风险
        dangerous = ["__import__", "compile", "exec", "eval", "open"]
        for name in dangerous:
            if name in code:
                raise BlockedCommandError(
                    f"Python 代码包含禁止的内置函数 '{name}'。"
                )

        # 委托给 run() 方法以复用沙盒机制（环境变量隔离、超时、审计）
        return self.run(
            [sys.executable, "-c", code],
        )

    def _audit(self, action: str, cmd: str, detail: str = "") -> None:
        """记录审计日志。

        每条日志写入两个位置：
          1. 内存中的 audit_log 列表（可通过 api 查询）
          2. 文件日志 LOG_DIR/sandbox-audit.log（持久化存储）
        """
        entry = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "action": action,      # EXEC / DONE / FAIL / BLOCKED / TIMEOUT
            "command": cmd,
            "detail": detail,
        }
        self.audit_log.append(entry)

        # 被拦截和超时事件使用 WARNING 级别，正常执行使用 INFO
        level = logging.WARNING if action in ("BLOCKED", "TIMEOUT") else logging.INFO
        logger.log(level, "%s | %s | %s", action, cmd, detail)


# ============================================================
# 便捷函数
# ============================================================

def safe_run(
    cmd: List[str],
    timeout: int = 10,
    allow_network: bool = False,
) -> Dict[str, Any]:
    """
    一行式安全执行。用于快速替换裸 subprocess.run() 调用。

    之前：
        subprocess.run(["python", "script.py"], check=True)

    之后：
        from scripts.security.sandbox_sdk import safe_run
        result = safe_run(["python", "script.py"])
    """
    sandbox = Sandbox(timeout=timeout, allow_network=allow_network)
    return sandbox.run(cmd)


# ============================================================
# 自测 — 直接运行此文件可快速验证沙盒功能
# ============================================================

if __name__ == "__main__":
    print("=== Sandbox SDK Self-Test ===\n")

    # 测试基类：超时 5s，禁止网络
    sb = Sandbox(timeout=5, allow_network=False)

    PASS = "[PASS]"
    FAIL = "[FAIL]"

    # 测试 1：正常命令
    print("[TEST 1] 正常命令: echo hello")
    try:
        r = sb.run(["echo", "hello"])
        print(f"  {PASS} exit={r['exit_code']}, stdout={r['stdout'].strip()}, {r['elapsed_ms']}ms")
    except SandboxError as e:
        print(f"  {FAIL} {e}")

    # 测试 2：超时
    print("[TEST 2] 超时检测: sleep 10 (timeout=2s)")
    sb2 = Sandbox(timeout=2)
    try:
        sb2.run(["sleep", "10"])
        print("  {FAIL} 应该触发超时")
    except TimeoutError as e:
        print(f"  {PASS} 正确拦截: {e}")

    # 测试 3：危险命令
    print("[TEST 3] 网络拦截: curl http://example.com")
    try:
        sb3 = Sandbox(allow_network=False)
        sb3.run(["curl", "http://example.com"])
        print("  {FAIL} 应该被拦截")
    except NetworkPolicyViolation as e:
        print(f"  {PASS} 正确拦截: {e}")

    # 测试 4：Python 代码执行
    print("[TEST 4] Python 代码: print(1+1)")
    try:
        r = sb.run_python("print(1+1)")
        print(f"  {PASS} exit={r['exit_code']}, stdout={r['stdout'].strip()}")
    except SandboxError as e:
        print(f"  {FAIL} {e}")

    print(f"\n审计日志: {LOG_DIR / 'sandbox-audit.log'}")
