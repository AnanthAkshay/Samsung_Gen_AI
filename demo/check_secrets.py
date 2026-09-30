import os
from pathlib import Path

env_path = Path("a:/Samsung_2/.env")
secrets = []
if env_path.exists():
    with open(env_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if "=" in line and not line.startswith("#"):
                k, v = line.split("=", 1)
                k_upper = k.strip().upper()
                if any(s in k_upper for s in ["KEY", "SECRET", "TOKEN", "PASS", "CREDENTIAL"]):
                    v_clean = v.strip("\"' ")
                    if len(v_clean) > 8:
                        secrets.append((k.strip(), v_clean))

print(f"Loaded {len(secrets)} active credentials to audit.")
leak_found = False
demo_dir = Path("a:/Samsung_2/demo")

for p in demo_dir.rglob("*"):
    if p.name == "check_secrets.py":
        continue
    if p.suffix.lower() in [".py", ".ps1", ".log", ".txt", ".md", ".json"]:
        try:
            content = p.read_text(encoding="utf-8", errors="ignore")
            for name, sec in secrets:
                if sec in content:
                    print(f"LEAK DETECTED in {p}: credential {name}")
                    leak_found = True
            for pat in ["AIza", "sk-proj"]:
                if pat in content:
                    print(f"KEY PATTERN DETECTED in {p}: {pat}")
                    leak_found = True
        except Exception as e:
            pass

if not leak_found:
    print("AUDIT PASS: Zero secrets or key patterns found anywhere in demo/ directory.")
else:
    print("AUDIT FAIL: Potential secret leak detected!")
