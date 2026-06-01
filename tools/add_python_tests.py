"""Augment problems.json with Python test harnesses for the in-browser runner.

Each test prints `__CODE_BUDDY_ALL_PASSED__` on success; the runner detects
that sentinel and flips the problem's status to "solved".
"""

import json
from pathlib import Path

PROBLEMS = Path(__file__).resolve().parents[1] / "assets" / "problems" / "problems.json"

SENTINEL = "__CODE_BUDDY_ALL_PASSED__"

TESTS = {
    "two-sum": (
        "r = two_sum([2, 7, 11, 15], 9)\n"
        "assert sorted(r) == [0, 1], f'Expected [0, 1], got {r}'\n"
        "r = two_sum([3, 2, 4], 6)\n"
        "assert sorted(r) == [1, 2], f'Expected [1, 2], got {r}'\n"
        "r = two_sum([3, 3], 6)\n"
        "assert sorted(r) == [0, 1], f'Expected [0, 1], got {r}'\n"
        f"print('{SENTINEL}')\n"
    ),
    "reverse-string": (
        "s = list('hello')\n"
        "reverse_string(s)\n"
        "assert s == ['o','l','l','e','h'], f'Got {s}'\n"
        "s = list('A')\n"
        "reverse_string(s)\n"
        "assert s == ['A'], f'Got {s}'\n"
        f"print('{SENTINEL}')\n"
    ),
    "palindrome-check": (
        "assert is_palindrome('A man, a plan, a canal: Panama') is True\n"
        "assert is_palindrome('race a car') is False\n"
        "assert is_palindrome(' ') is True\n"
        f"print('{SENTINEL}')\n"
    ),
    "fizzbuzz": (
        "assert fizz_buzz(5) == ['1','2','Fizz','4','Buzz']\n"
        "r = fizz_buzz(15)\n"
        "assert r[-1] == 'FizzBuzz' and r[2] == 'Fizz' and r[4] == 'Buzz', f'Got {r}'\n"
        f"print('{SENTINEL}')\n"
    ),
    "valid-parentheses": (
        "assert is_valid('()[]{}') is True\n"
        "assert is_valid('(]') is False\n"
        "assert is_valid('([{}])') is True\n"
        "assert is_valid('(') is False\n"
        f"print('{SENTINEL}')\n"
    ),
    "binary-search": (
        "assert search([-1, 0, 3, 5, 9, 12], 9) == 4\n"
        "assert search([-1, 0, 3, 5, 9, 12], 2) == -1\n"
        "assert search([5], 5) == 0\n"
        "assert search([5], -5) == -1\n"
        f"print('{SENTINEL}')\n"
    ),
    "climbing-stairs": (
        "assert climb_stairs(1) == 1\n"
        "assert climb_stairs(2) == 2\n"
        "assert climb_stairs(4) == 5\n"
        "assert climb_stairs(10) == 89\n"
        f"print('{SENTINEL}')\n"
    ),
    "best-time-stock": (
        "assert max_profit([7, 1, 5, 3, 6, 4]) == 5\n"
        "assert max_profit([7, 6, 4, 3, 1]) == 0\n"
        "assert max_profit([1]) == 0\n"
        f"print('{SENTINEL}')\n"
    ),
    "maximum-subarray": (
        "assert max_subarray([-2, 1, -3, 4, -1, 2, 1, -5, 4]) == 6\n"
        "assert max_subarray([1]) == 1\n"
        "assert max_subarray([5, 4, -1, 7, 8]) == 23\n"
        "assert max_subarray([-1, -2, -3]) == -1\n"
        f"print('{SENTINEL}')\n"
    ),
    "merge-sorted-arrays": (
        "assert merge_sorted([1, 3, 5], [2, 4, 6]) == [1, 2, 3, 4, 5, 6]\n"
        "assert merge_sorted([], [1]) == [1]\n"
        "assert merge_sorted([2, 2], [1, 1]) == [1, 1, 2, 2]\n"
        f"print('{SENTINEL}')\n"
    ),
    "group-anagrams": (
        "r = group_anagrams(['eat','tea','tan','ate','nat','bat'])\n"
        "norm = sorted(tuple(sorted(g)) for g in r)\n"
        "assert norm == [('ate','eat','tea'), ('bat',), ('nat','tan')], f'Got {norm}'\n"
        f"print('{SENTINEL}')\n"
    ),
    "longest-unique-substring": (
        "assert length_of_longest_substring('abcabcbb') == 3\n"
        "assert length_of_longest_substring('bbbbb') == 1\n"
        "assert length_of_longest_substring('pwwkew') == 3\n"
        "assert length_of_longest_substring('') == 0\n"
        f"print('{SENTINEL}')\n"
    ),
}


def main() -> None:
    data = json.loads(PROBLEMS.read_text(encoding="utf-8"))
    missing = []
    for problem in data:
        pid = problem["id"]
        if pid not in TESTS:
            missing.append(pid)
            continue
        problem["pythonTests"] = TESTS[pid]
    PROBLEMS.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Augmented {len(data) - len(missing)} of {len(data)} problems with pythonTests.")
    if missing:
        print("Missing tests for:", ", ".join(missing))


if __name__ == "__main__":
    main()
