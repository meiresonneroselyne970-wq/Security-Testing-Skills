#!/usr/bin/env python3
"""
安全的计算器工具 — 供测试 Skill 调用。

这是一个完全合法的 Python 脚本，用于验证 Bandit 和 execution-gate
不会对正常工具脚本产生误报。

安全特性:
- 不使用 subprocess / os.system
- 不使用 eval / exec
- 不发起网络请求
- 不操作文件系统（仅标准输入输出）
- 不包含硬编码凭据
"""

import sys
import math
from typing import Union, Optional


def safe_add(a: float, b: float) -> float:
    """安全的加法运算"""
    return a + b


def safe_subtract(a: float, b: float) -> float:
    """安全的减法运算"""
    return a - b


def safe_multiply(a: float, b: float) -> float:
    """安全的乘法运算"""
    return a * b


def safe_divide(a: float, b: float) -> Optional[float]:
    """安全的除法运算（含除零检查）"""
    if b == 0:
        print("错误: 除数不能为零", file=sys.stderr)
        return None
    return a / b


def safe_sqrt(a: float) -> Optional[float]:
    """安全的平方根运算（含负数检查）"""
    if a < 0:
        print("错误: 不能对负数开平方根", file=sys.stderr)
        return None
    return math.sqrt(a)


def safe_power(base: float, exp: float) -> float:
    """安全的幂运算"""
    return math.pow(base, exp)


def calculate(expression: str) -> Union[float, str]:
    """
    安全地计算基本数学表达式。

    仅支持: +, -, *, /, **, sqrt()
    不使用 eval() — 而是解析并调用对应的安全函数。
    """
    expression = expression.strip()

    # 简单的二元运算解析
    operators = {
        '+': safe_add,
        '-': safe_subtract,
        '*': safe_multiply,
        '/': safe_divide,
        '**': safe_power,
    }

    for op_symbol, op_func in operators.items():
        if op_symbol in expression:
            parts = expression.split(op_symbol, 1)
            if len(parts) == 2:
                try:
                    a = float(parts[0].strip())
                    b = float(parts[1].strip())
                    return op_func(a, b)
                except ValueError:
                    return f"错误: 无法解析数字 '{expression}'"

    # 尝试作为单个数字解析
    try:
        return float(expression)
    except ValueError:
        return f"错误: 不支持的表达式 '{expression}'"


def main():
    """主入口 — 从命令行参数读取表达式并计算"""
    if len(sys.argv) < 2:
        print("用法: python safe-calculator.py <表达式>")
        print("示例: python safe-calculator.py '3 + 5'")
        print("支持: +, -, *, /, **")
        sys.exit(1)

    expression = ' '.join(sys.argv[1:])
    result = calculate(expression)

    if isinstance(result, str):
        print(result)
        sys.exit(1)
    else:
        print(f"结果: {result}")
        sys.exit(0)


if __name__ == "__main__":
    main()
