"""Each query must find exactly the incident injected by generate.py, and
nothing in the baseline traffic."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import generate  # noqa: E402
import queries  # noqa: E402


@pytest.fixture(scope="module")
def con(tmp_path_factory):
    path = tmp_path_factory.mktemp("logs") / "http_requests.ndjson"
    with path.open("w") as f:
        for r in generate.generate(seed=7):
            f.write(json.dumps(r) + "\n")
    return queries.connect(str(path))


def test_every_query_runs(con):
    assert set(queries.names()) == {
        "cache_efficiency", "credential_stuffing", "origin_errors", "top_blocked_ips", "waf_false_positives",
    }
    for name in queries.names():
        queries.run(con, name)


def test_credential_stuffing_finds_exactly_the_attackers(con):
    rows = queries.run(con, "credential_stuffing")
    assert {r["client_ip"] for r in rows} == set(generate.STUFFING_IPS)
    for r in rows:
        assert r["rate_limited"] > 0, "rate limiting should already be catching some attempts"
        assert r["reached_origin"] > 0, "some attempts got through; the query must show that"


def test_top_blocked_includes_attackers_and_scanner(con):
    ips = {r["client_ip"] for r in queries.run(con, "top_blocked_ips")}
    assert generate.SCANNER_IP in ips
    assert set(generate.STUFFING_IPS) <= ips
    assert not any(ip.startswith("192.0.2.") for ip in ips), "no single normal user is blocked 10+ times"


def test_false_positive_rule_is_flagged_and_real_attacks_are_not(con):
    rows = queries.run(con, "waf_false_positives")
    assert [(r["rule_id"], r["path"]) for r in rows] == [(generate.FP_RULE_ID, generate.FP_PATH)]
    assert rows[0]["pct_browser_ua"] == 100.0


def test_origin_errors_cover_exactly_the_incident_window(con):
    rows = queries.run(con, "origin_errors")
    minutes = [int((r["minute"] - generate.START.replace(tzinfo=None)).total_seconds() // 60) for r in rows]
    assert minutes == list(range(*generate.ORIGIN_ERROR_WINDOW))
    assert all(r["p95_origin_ms"] > 5000 for r in rows)


def test_static_assets_are_cached(con):
    rows = queries.run(con, "cache_efficiency")
    assert rows and all(r["hit_pct"] == 100.0 for r in rows if r["path"].startswith("/static/"))
