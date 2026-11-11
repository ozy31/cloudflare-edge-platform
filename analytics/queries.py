"""Run the edge analysis queries against Logpush NDJSON with DuckDB.

The same queries work on files pulled from R2, or directly on R2 through
DuckDB's httpfs/S3 support (see analytics/README.md).

    python analytics/queries.py analytics/data/http_requests.ndjson
    python analytics/queries.py "s3://edge-http-logs/http_requests/20261101/*.log.gz" top_blocked_ips
"""

from __future__ import annotations

import sys
from pathlib import Path

import duckdb

QUERY_DIR = Path(__file__).parent / "queries"


def connect(source: str) -> duckdb.DuckDBPyConnection:
    con = duckdb.connect()
    # Views cannot take prepared parameters, so the path is quoted as a SQL
    # string literal.
    literal = "'" + source.replace("'", "''") + "'"
    con.execute(
        "CREATE VIEW requests AS SELECT *, timezone('UTC', CAST(EdgeStartTimestamp AS TIMESTAMPTZ)) AS ts "
        f"FROM read_json_auto({literal}, format='newline_delimited')"
    )
    return con


def names() -> list[str]:
    return sorted(p.stem for p in QUERY_DIR.glob("*.sql"))


def run(con: duckdb.DuckDBPyConnection, name: str) -> list[dict]:
    sql = (QUERY_DIR / f"{name}.sql").read_text()
    cur = con.execute(sql)
    cols = [d[0] for d in cur.description]
    return [dict(zip(cols, row)) for row in cur.fetchall()]


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit(f"usage: {sys.argv[0]} <ndjson path or glob> [query ...]\nqueries: {', '.join(names())}")
    con = connect(sys.argv[1])
    for name in sys.argv[2:] or names():
        rows = run(con, name)
        print(f"\n== {name} ({len(rows)} rows)")
        for r in rows[:10]:
            print("  " + "  ".join(f"{k}={v}" for k, v in r.items()))


if __name__ == "__main__":
    main()
