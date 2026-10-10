"""Formats the one Dart file that was just edited. Never touches anything else, never fails the edit."""
import json
import subprocess
import sys

try:
    path = json.load(sys.stdin).get("tool_input", {}).get("file_path", "")
    if path.endswith(".dart") and "/packages/" not in path.replace("\\", "/"):
        subprocess.run(["dart", "format", path], capture_output=True, timeout=60, shell=sys.platform == "win32")
except Exception:
    pass
