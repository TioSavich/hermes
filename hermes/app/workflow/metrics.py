#!/usr/bin/env python3
"""Compute deterministic discussion metrics from parsed.json.

Independent of the PML rubric. Computes:

  1. Word counts (per post, per student, per thread, per prompt).
  2. Community graph density (reply network among students).
  3. Return-post completion rate (and return-vs-initial lexical distance).
  4. Named-uptake rate (replies that name the peer they're answering).

Usage:

    python3 metrics.py                 # all parsed prompts
    python3 metrics.py --only 01_maddy_square_or_diamond
    python3 metrics.py --graph         # also emit Graphviz .dot + .html

Outputs:

    output/metrics/<prompt_id>.json   (per-prompt metrics)
    output/metrics/per_student.csv    (student-level aggregates across prompts)
    output/metrics/comparison.csv     (prompt-level table for grant)
    output/metrics/graph_<prompt_id>.dot   (with --graph)
    output/metrics/graph_<prompt_id>.html  (with --graph)
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import os as _os
HERE = Path(_os.environ.get("HERMES_PACK_ROOT", HERE.parent))
DATA = HERE / "runtime"

from lib import roster as rosterlib  # noqa: E402

PARSED_DIR = DATA / "output" / "parsed"
METRICS_DIR = DATA / "output" / "metrics"


WORD_RE = re.compile(r"\b[\w']+\b", flags=re.UNICODE)


def words(text: str) -> list[str]:
    return WORD_RE.findall((text or "").lower())


def jaccard_distance(a: list[str], b: list[str]) -> float:
    sa, sb = set(a), set(b)
    if not sa and not sb:
        return 0.0
    union = sa | sb
    inter = sa & sb
    if not union:
        return 0.0
    return 1.0 - (len(inter) / len(union))


def name_mention_in(text: str, student: rosterlib.Student) -> bool:
    """Whether the text mentions this student by first name as a vocative."""
    first = (student.first_name or "").strip()
    if len(first) < 2:
        return False
    pattern = re.compile(rf"\b{re.escape(first)}\b", flags=re.IGNORECASE)
    return bool(pattern.search(text or ""))


def metrics_for_prompt(
    parsed: dict,
    students: list[rosterlib.Student],
) -> dict:
    by_sid = {s.student_id: s for s in students}
    threads = parsed.get("threads", [])
    prompt_text = parsed.get("instructor_prompt_text", "") or ""
    prompt_vocab = set(words(prompt_text))

    posts: list[dict] = []
    initial_authors: set[str] = set()
    return_authors: set[str] = set()
    initial_text_by_sid: dict[str, list[str]] = defaultdict(list)
    return_text_by_sid: dict[str, list[str]] = defaultdict(list)
    reply_edges: list[tuple[str, str]] = []
    reply_named_uptake: list[bool] = []

    for thread in threads:
        thread_posts = thread.get("posts", [])
        if not thread_posts:
            continue
        # By convention the first post is the initial post.
        first_sid = thread_posts[0].get("author_student_id")
        if first_sid:
            initial_authors.add(first_sid)

        for idx, p in enumerate(thread_posts):
            sid = p.get("author_student_id")
            role = (p.get("role") or "").lower() or ("initial" if idx == 0 else "reply")
            text = (p.get("text") or "").strip()
            ws = words(text)
            posts.append({
                "prompt_id": parsed.get("prompt_id"),
                "thread_index": thread.get("thread_index"),
                "post_index": p.get("post_index", idx),
                "student_id": sid,
                "role": role,
                "word_count": len(ws),
                "char_count": len(text),
                "anti_parrot_jaccard": jaccard_distance(ws, list(prompt_vocab)),
            })
            if not sid:
                continue
            if role == "initial":
                initial_text_by_sid[sid].append(text)
            elif role == "return":
                return_authors.add(sid)
                return_text_by_sid[sid].append(text)
            elif role == "reply":
                if first_sid and sid != first_sid:
                    reply_edges.append((sid, first_sid))
                    parent_student = by_sid.get(first_sid)
                    reply_named_uptake.append(
                        bool(parent_student) and name_mention_in(text, parent_student)
                    )

    # Community graph (undirected for density; we keep directed edges in JSON).
    nodes = sorted({sid for edge in reply_edges for sid in edge} | initial_authors)
    undirected_edges = {tuple(sorted(e)) for e in reply_edges if e[0] != e[1]}
    node_degree: dict[str, int] = defaultdict(int)
    for a, b in undirected_edges:
        node_degree[a] += 1
        node_degree[b] += 1
    n_nodes = len(nodes)
    n_edges = len(undirected_edges)
    possible_edges = n_nodes * (n_nodes - 1) / 2 if n_nodes > 1 else 0
    density = (n_edges / possible_edges) if possible_edges else 0.0
    avg_degree = (sum(node_degree.values()) / n_nodes) if n_nodes else 0.0
    isolated = [sid for sid in nodes if node_degree[sid] == 0]

    # Return-post completion and lexical distance.
    return_distances: list[float] = []
    for sid, returns in return_text_by_sid.items():
        initials = initial_text_by_sid.get(sid, [])
        if not initials or not returns:
            continue
        return_distances.append(jaccard_distance(words(returns[-1]), words(initials[0])))
    n_with_initial = len(initial_text_by_sid)
    return_rate = (len(return_authors & set(initial_text_by_sid)) / n_with_initial) if n_with_initial else 0.0
    avg_return_distance = (sum(return_distances) / len(return_distances)) if return_distances else 0.0

    # Named-uptake rate.
    named_rate = (sum(reply_named_uptake) / len(reply_named_uptake)) if reply_named_uptake else 0.0

    # Word count aggregates.
    n_posts = len(posts)
    total_words = sum(p["word_count"] for p in posts)
    avg_words = (total_words / n_posts) if n_posts else 0.0
    avg_jaccard = (sum(p["anti_parrot_jaccard"] for p in posts) / n_posts) if n_posts else 0.0

    return {
        "prompt_id": parsed.get("prompt_id"),
        "raw_header": parsed.get("raw_header"),
        "n_threads": len(threads),
        "n_posts": n_posts,
        "n_unique_authors": len({p["student_id"] for p in posts if p["student_id"]}),
        "word_counts": {
            "total": total_words,
            "avg_per_post": round(avg_words, 1),
            "avg_anti_parrot_jaccard": round(avg_jaccard, 3),
        },
        "community_graph": {
            "n_nodes": n_nodes,
            "n_edges": n_edges,
            "density": round(density, 3),
            "avg_degree": round(avg_degree, 2),
            "isolated_authors": isolated,
            "edges": [list(e) for e in sorted(undirected_edges)],
        },
        "return_post": {
            "completion_rate": round(return_rate, 3),
            "avg_return_initial_distance": round(avg_return_distance, 3),
            "n_returns": len(return_authors),
            "n_initials": n_with_initial,
        },
        "named_uptake": {
            "rate": round(named_rate, 3),
            "n_named": sum(reply_named_uptake),
            "n_replies": len(reply_named_uptake),
        },
        "posts": posts,
    }


def write_graph_dot(metrics: dict, students: list[rosterlib.Student], path: Path) -> None:
    by_sid = {s.student_id: s for s in students}
    edges = metrics["community_graph"]["edges"]
    nodes = sorted({sid for e in edges for sid in e} | set(metrics["community_graph"]["isolated_authors"]))

    lines = [
        "graph G {",
        '  graph [bgcolor="white", fontname="Helvetica"];',
        '  node [shape=ellipse, style=filled, fillcolor="#fdeee8", fontname="Helvetica"];',
        '  edge [color="#990000"];',
    ]
    for sid in nodes:
        label = by_sid[sid].display() if sid in by_sid else sid
        lines.append(f'  "{sid}" [label="{label}"];')
    for a, b in edges:
        lines.append(f'  "{a}" -- "{b}";')
    lines.append("}")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_graph_html(metrics: dict, students: list[rosterlib.Student], path: Path) -> None:
    """A tiny standalone HTML using vis-network from CDN."""
    by_sid = {s.student_id: s for s in students}
    edges = metrics["community_graph"]["edges"]
    nodes = sorted({sid for e in edges for sid in e} | set(metrics["community_graph"]["isolated_authors"]))
    node_objs = [{"id": sid, "label": (by_sid[sid].display() if sid in by_sid else sid)} for sid in nodes]
    edge_objs = [{"from": a, "to": b} for a, b in edges]
    title = metrics.get("raw_header") or metrics.get("prompt_id") or ""
    nodes_json = json.dumps(node_objs)
    edges_json = json.dumps(edge_objs)
    html = f"""<!doctype html>
<html><head>
  <meta charset="utf-8">
  <title>Community graph — {title}</title>
  <script src="https://unpkg.com/vis-network/standalone/umd/vis-network.min.js"></script>
  <style>html,body{{margin:0;padding:0;font-family:Helvetica,Arial,sans-serif}}#g{{width:100vw;height:100vh}}h1{{position:absolute;left:18px;top:14px;font-size:14px;color:#555;margin:0}}</style>
</head><body>
  <h1>{title}</h1>
  <div id="g"></div>
  <script>
    const nodes = new vis.DataSet({nodes_json});
    const edges = new vis.DataSet({edges_json});
    new vis.Network(document.getElementById('g'), {{nodes, edges}}, {{
      nodes: {{shape: 'ellipse', color: {{background: '#fdeee8', border: '#990000'}}}},
      edges: {{color: '#990000', smooth: false}},
      physics: {{stabilization: true}},
    }});
  </script>
</body></html>
"""
    path.write_text(html, encoding="utf-8")


def write_per_student_csv(all_metrics: list[dict], path: Path) -> None:
    rows: dict[str, dict] = {}
    for m in all_metrics:
        for p in m["posts"]:
            sid = p["student_id"]
            if not sid:
                continue
            agg = rows.setdefault(sid, {
                "student_id": sid,
                "total_posts": 0,
                "total_words": 0,
                "n_initial": 0,
                "n_reply": 0,
                "n_return": 0,
            })
            agg["total_posts"] += 1
            agg["total_words"] += p["word_count"]
            role_key = f"n_{p['role']}"
            agg[role_key] = agg.get(role_key, 0) + 1
    if not rows:
        return
    fields = ["student_id", "total_posts", "total_words", "n_initial", "n_reply", "n_return"]
    with path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        for sid in sorted(rows):
            w.writerow(rows[sid])


def write_comparison_csv(all_metrics: list[dict], path: Path) -> None:
    fields = [
        "prompt_id", "n_threads", "n_posts", "n_unique_authors",
        "avg_words_per_post", "avg_anti_parrot_jaccard",
        "graph_n_nodes", "graph_n_edges", "graph_density", "graph_avg_degree", "graph_isolated",
        "return_completion_rate", "avg_return_distance",
        "named_uptake_rate",
    ]
    with path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        for m in all_metrics:
            w.writerow({
                "prompt_id": m["prompt_id"],
                "n_threads": m["n_threads"],
                "n_posts": m["n_posts"],
                "n_unique_authors": m["n_unique_authors"],
                "avg_words_per_post": m["word_counts"]["avg_per_post"],
                "avg_anti_parrot_jaccard": m["word_counts"]["avg_anti_parrot_jaccard"],
                "graph_n_nodes": m["community_graph"]["n_nodes"],
                "graph_n_edges": m["community_graph"]["n_edges"],
                "graph_density": m["community_graph"]["density"],
                "graph_avg_degree": m["community_graph"]["avg_degree"],
                "graph_isolated": len(m["community_graph"]["isolated_authors"]),
                "return_completion_rate": m["return_post"]["completion_rate"],
                "avg_return_distance": m["return_post"]["avg_return_initial_distance"],
                "named_uptake_rate": m["named_uptake"]["rate"],
            })


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--only", help="Only compute metrics for one prompt_id.")
    ap.add_argument("--graph", action="store_true", help="Emit Graphviz .dot and standalone .html per prompt.")
    args = ap.parse_args()

    if not PARSED_DIR.exists() or not any(PARSED_DIR.glob("*.json")):
        sys.exit("no parsed files in output/parsed/. Run parse.py first.")
    students = rosterlib.read_roster(DATA / "roster.csv")

    METRICS_DIR.mkdir(parents=True, exist_ok=True)
    all_metrics: list[dict] = []

    for parsed_file in sorted(PARSED_DIR.glob("*.json")):
        prompt_id = parsed_file.stem
        if args.only and prompt_id != args.only:
            continue
        parsed = json.loads(parsed_file.read_text(encoding="utf-8"))
        m = metrics_for_prompt(parsed, students)
        all_metrics.append(m)
        out_path = METRICS_DIR / f"{prompt_id}.json"
        out_path.write_text(json.dumps(m, indent=2, ensure_ascii=False), encoding="utf-8")
        print(f"  {prompt_id}: posts={m['n_posts']} density={m['community_graph']['density']} "
              f"return={m['return_post']['completion_rate']} named={m['named_uptake']['rate']}")
        if args.graph:
            write_graph_dot(m, students, METRICS_DIR / f"graph_{prompt_id}.dot")
            write_graph_html(m, students, METRICS_DIR / f"graph_{prompt_id}.html")

    if all_metrics:
        write_per_student_csv(all_metrics, METRICS_DIR / "per_student.csv")
        write_comparison_csv(all_metrics, METRICS_DIR / "comparison.csv")
        print(f"done. {METRICS_DIR.relative_to(HERE)}/")


if __name__ == "__main__":
    main()
