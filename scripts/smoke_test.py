#!/usr/bin/env python3
"""
Structured smoke test harness for local dev stack.

- Waits for backend readiness with retries
- Probes an unauthenticated admin vehicles endpoint
- Attempts a list of candidate admin passwords to obtain a token
- If token obtained, calls authenticated vehicles endpoint
- Emits structured JSON to stdout and uses exit codes:
  0 = success (backend reachable); 2 = backend unreachable

Designed as a replacement for `scripts/smoke_test.sh` with JSON output for CI.
"""
import argparse
import json
import sys
import time
import urllib.request
import urllib.error


def http_get(url, headers=None, timeout=5):
    req = urllib.request.Request(url, headers=(headers or {}))
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        body = resp.read()
        code = resp.getcode()
        return code, body


def http_post_json(url, data, headers=None, timeout=5):
    hdrs = dict(headers or {})
    hdrs.setdefault("Content-Type", "application/json")
    payload = json.dumps(data).encode("utf-8")
    req = urllib.request.Request(url, data=payload, headers=hdrs, method="POST")
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        body = resp.read()
        code = resp.getcode()
        return code, body


def try_parse_token(body_bytes):
    try:
        j = json.loads(body_bytes.decode("utf-8"))
        for key in ("token", "accessToken", "access_token", "jwt"):
            if key in j and isinstance(j[key], str):
                return j[key]
        # some APIs nest token under data or result
        for v in j.values() if isinstance(j, dict) else []:
            if isinstance(v, dict):
                for key in ("token", "accessToken", "access_token", "jwt"):
                    if key in v and isinstance(v[key], str):
                        return v[key]
    except Exception:
        return None
    return None


def approximate_count_from_body(body_bytes):
    # Try JSON parsing first
    try:
        j = json.loads(body_bytes.decode("utf-8"))
        if isinstance(j, list):
            return len(j)
        if isinstance(j, dict):
            # common patterns: {content: [...]} or {data: [...]}
            for k in ("content", "data", "items", "results"):
                if k in j and isinstance(j[k], list):
                    return len(j[k])
            # fallback: count top-level keys that look like entries
            return sum(1 for _ in j.keys())
    except Exception:
        pass
    # Fallback: count occurrences of "\"id\""
    try:
        s = body_bytes.decode("utf-8", errors="ignore")
        return s.count('"id"')
    except Exception:
        return 0


def run_smoke(base_url, tries, sleep, passwords, username, timeout):
    out = {
        "base_url": base_url,
        "backend_reachable": False,
        "unauthenticated": {},
        "auth": {"token_obtained": False, "password_used": None},
        "errors": [],
    }

    probe_url = f"{base_url.rstrip('/')}/api/admin/vehicles/all"

    # wait for backend readiness
    code = None
    for i in range(tries):
        try:
            code, body = http_get(probe_url, timeout=timeout)
            out["backend_reachable"] = True
            out["backend_http_code"] = code
            break
        except Exception as e:
            out["errors"].append(f"probe_{i}_err:{str(e)}")
            time.sleep(sleep)

    if not out["backend_reachable"]:
        out["message"] = f"backend unreachable after {tries} attempts"
        print(json.dumps(out, indent=2))
        return out, 2

    # unauthenticated probe
    try:
        code, body = http_get(probe_url, timeout=timeout)
        out["unauthenticated"]["http_code"] = code
        out["unauthenticated"]["approx_count"] = approximate_count_from_body(body)
    except Exception as e:
        out["unauthenticated"]["error"] = str(e)

    # try candidate passwords
    login_url = f"{base_url.rstrip('/')}/api/auth/login"
    for p in passwords:
        try:
            payload = {"username": username, "password": p}
            code, body = http_post_json(login_url, payload, timeout=timeout)
            token = try_parse_token(body)
            if token:
                out["auth"]["token_obtained"] = True
                out["auth"]["password_used"] = p
                out["auth"]["http_code"] = code
                out["auth"]["token_preview"] = token[:8] + "..."
                break
        except urllib.error.HTTPError as he:
            # capture response body if possible
            try:
                body = he.read()
                token = try_parse_token(body)
                if token:
                    out["auth"]["token_obtained"] = True
                    out["auth"]["password_used"] = p
                    out["auth"]["http_code"] = he.code
                    out["auth"]["token_preview"] = token[:8] + "..."
                    break
            except Exception:
                out["errors"].append(f"login_http_error:{str(he)}")
        except Exception as e:
            out["errors"].append(f"login_err_{p}:{str(e)}")

    # if token obtained, call authenticated endpoint
    if out["auth"]["token_obtained"]:
        try:
            headers = {"Authorization": f"Bearer {token}"}
            code, body = http_get(probe_url, headers=headers, timeout=timeout)
            out["auth"]["authenticated_http_code"] = code
            out["auth"]["authenticated_approx_count"] = approximate_count_from_body(body)
        except Exception as e:
            out["errors"].append(f"auth_probe_err:{str(e)}")

    return out, 0


def main(argv=None):
    parser = argparse.ArgumentParser(description="Structured smoke test for the dev stack")
    parser.add_argument("--base", default="http://localhost:8080", help="Base URL of the backend")
    parser.add_argument("--tries", type=int, default=60, help="Number of readiness tries")
    parser.add_argument("--sleep", type=int, default=2, help="Seconds between tries")
    parser.add_argument("--timeout", type=int, default=5, help="HTTP timeout seconds")
    parser.add_argument("--username", default="admin", help="Admin username to try")
    parser.add_argument("--passwords", default="admin password changeme admin123 secret", help="Space-separated candidate passwords")
    args = parser.parse_args(argv)

    passwords = args.passwords.split()
    start = time.time()
    result, code = run_smoke(args.base, args.tries, args.sleep, passwords, args.username, args.timeout)
    result["elapsed_seconds"] = round(time.time() - start, 2)
    print(json.dumps(result, indent=2))
    sys.exit(code)


if __name__ == "__main__":
    main()
