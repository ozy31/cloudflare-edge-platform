"""Generate synthetic Cloudflare Logpush http_requests logs (NDJSON).

The data has realistic baseline traffic plus four incidents injected at
known times, so the queries in analytics/queries/ can be tested against a
known answer:

- credential_stuffing: a handful of IPs hammering POST /api/auth/login
- scanner: one IP probing /.env, /wp-login.php, /.git/config
- false_positive: real users blocked by one WAF rule on /api/upload
- origin_errors: a 3-minute burst of 502/504 from the origin

All IPs are from documentation ranges (RFC 5737); no real data is used.
"""

from __future__ import annotations

import argparse
import json
import random
from datetime import datetime, timedelta, timezone
from pathlib import Path

START = datetime(2026, 11, 1, 12, 0, tzinfo=timezone.utc)
MINUTES = 60

BROWSER_UA = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 15_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/19.0 Safari/605.1.15",
    "Mozilla/5.0 (iPhone; CPU iPhone OS 19_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148",
]
PAGES = ["/", "/pricing", "/docs", "/app", "/api/items", "/api/items/42", "/static/app.3f9a.js", "/static/app.3f9a.css"]

# Incident parameters (also used by the tests).
STUFFING_IPS = [f"198.51.100.{i}" for i in range(10, 16)]
SCANNER_IP = "203.0.113.66"
FP_RULE_ID = "waf-custom-0007"
FP_PATH = "/api/upload"
ORIGIN_ERROR_WINDOW = (35, 38)  # minutes after START


def ray(rng: random.Random) -> str:
    return "%016x" % rng.getrandbits(64)


def base_record(rng: random.Random, ts: datetime) -> dict:
    path = rng.choice(PAGES)
    static = path.startswith("/static/")
    return {
        "RayID": ray(rng),
        "EdgeStartTimestamp": ts.isoformat().replace("+00:00", "Z"),
        "ClientIP": f"192.0.2.{rng.randint(1, 254)}",
        "ClientCountry": rng.choice(["de", "tr", "gb", "nl", "us", "fr"]),
        "ClientRequestHost": "app.example.com",
        "ClientRequestMethod": "GET",
        "ClientRequestPath": path,
        "ClientRequestUserAgent": rng.choice(BROWSER_UA),
        "EdgeResponseStatus": 200,
        "OriginResponseStatus": 0 if static else 200,
        "OriginResponseDurationMs": 0 if static else rng.randint(20, 180),
        "EdgeTimeToFirstByteMs": rng.randint(5, 40) if static else rng.randint(30, 220),
        "CacheCacheStatus": "hit" if static else "dynamic",
        "SecurityAction": "",
        "SecurityRuleID": "",
        "SecurityRuleDescription": "",
        "BotScore": rng.randint(60, 99),
        "WAFAttackScore": rng.randint(70, 99),
    }


def generate(seed: int = 7) -> list[dict]:
    rng = random.Random(seed)
    out: list[dict] = []
    for minute in range(MINUTES):
        t0 = START + timedelta(minutes=minute)
        for _ in range(rng.randint(80, 120)):
            r = base_record(rng, t0 + timedelta(seconds=rng.random() * 60))
            if ORIGIN_ERROR_WINDOW[0] <= minute < ORIGIN_ERROR_WINDOW[1] and r["CacheCacheStatus"] == "dynamic":
                status = rng.choice([502, 502, 504])
                r.update(EdgeResponseStatus=status, OriginResponseStatus=status, OriginResponseDurationMs=rng.randint(9000, 30000))
            out.append(r)

        # credential stuffing: minutes 10-25
        if 10 <= minute < 25:
            for ip in STUFFING_IPS:
                for _ in range(rng.randint(15, 25)):
                    r = base_record(rng, t0 + timedelta(seconds=rng.random() * 60))
                    r.update(
                        ClientIP=ip, ClientCountry="zz", ClientRequestMethod="POST",
                        ClientRequestPath="/api/auth/login", ClientRequestUserAgent="python-requests/2.33",
                        BotScore=rng.randint(1, 9), CacheCacheStatus="dynamic",
                    )
                    if rng.random() < 0.6:
                        r.update(EdgeResponseStatus=429, OriginResponseStatus=0, SecurityAction="block",
                                 SecurityRuleID="ratelimit-login_bruteforce", SecurityRuleDescription="Password guessing on the login endpoint")
                    else:
                        r.update(EdgeResponseStatus=401, OriginResponseStatus=401)
                    out.append(r)

        # scanner: minute 5
        if minute == 5:
            for p in ["/.env", "/wp-login.php", "/.git/config", "/.aws/credentials", "/phpinfo.php"] * 4:
                r = base_record(rng, t0 + timedelta(seconds=rng.random() * 60))
                r.update(ClientIP=SCANNER_IP, ClientRequestPath=p, ClientRequestUserAgent="Mozilla/5.0 zgrab/0.x",
                         EdgeResponseStatus=403, OriginResponseStatus=0, BotScore=2, WAFAttackScore=8,
                         SecurityAction="block", SecurityRuleID="waf-custom-block_scanner_paths",
                         SecurityRuleDescription="Paths only scanners ask for", CacheCacheStatus="dynamic")
                out.append(r)

        # false positive: a rule blocks real browser uploads, many users, all minutes after 40
        if minute >= 40:
            for _ in range(rng.randint(4, 8)):
                r = base_record(rng, t0 + timedelta(seconds=rng.random() * 60))
                r.update(ClientRequestMethod="POST", ClientRequestPath=FP_PATH, EdgeResponseStatus=403,
                         OriginResponseStatus=0, SecurityAction="block", SecurityRuleID=FP_RULE_ID,
                         SecurityRuleDescription="Block large request bodies", CacheCacheStatus="dynamic")
                out.append(r)

    out.sort(key=lambda r: r["EdgeStartTimestamp"])
    return out


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--out", type=Path, default=Path(__file__).parent / "data" / "http_requests.ndjson")
    ap.add_argument("--seed", type=int, default=7)
    args = ap.parse_args()
    rows = generate(args.seed)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w") as f:
        for r in rows:
            f.write(json.dumps(r) + "\n")
    print(f"wrote {len(rows)} records to {args.out}")


if __name__ == "__main__":
    main()
