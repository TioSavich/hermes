#!/usr/bin/env python3
"""Compile the questionnaire's deterministic L1-L3 choice sets.

The compiler reads the shipped family quotient and execution-verified input
contracts.  The two vocabulary bridges are deliberately authored JSON files;
their headers identify them as vetoable rather than derived facts.
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
import re
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Iterable


ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
FAMILY_GRAPH = ROOT / "docs/research/assets/automata/family_graph.json"
INPUT_CONTRACTS = ROOT / "knowledge/strategies/automaton_input_contracts.pl"
REGION_PARTITION = HERE / "region_partition.json"
FAMILY_DOMAIN_MAP = HERE / "family_domain_map.json"
MAX_CONTENT_CHOICES = 7
CONTENT_LETTERS = "ABCDEFG"
ABSTENTION_LETTER = "X"

CONTRACT_ROW = re.compile(
    r"^automaton_input_contract\(\s*([a-z][a-z0-9_]*)\s*,\s*"
    r"([a-z][a-z0-9_]*)\s*,\s*'(.+)'\s*,\s*'(.+)'\s*,\s*"
    r"verified\(([^)]+)\)\)\.$"
)
NUMERIC_TYPES = {"integer", "positive_integer", "number", "positive_number"}


def canonical_json(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))


def plain_label(value: str) -> str:
    return value.replace("_", " ")


@dataclass(frozen=True)
class Choice:
    letter: str
    key: str
    label: str
    value: Any


@dataclass(frozen=True)
class ChoicePage:
    level: str
    question: str
    page_index: int
    page_count: int
    choices: tuple[Choice, ...]

    @property
    def content_choices(self) -> tuple[Choice, ...]:
        return tuple(choice for choice in self.choices if choice.letter != ABSTENTION_LETTER)


@dataclass(frozen=True)
class ContractSchema:
    family: str
    schema_id: str
    discriminator: str
    template: Any
    example: Any
    kinds: tuple[str, ...]
    source_lines: tuple[int, ...]

    @property
    def representative_kind(self) -> str:
        return self.kinds[0]


@dataclass(frozen=True)
class NumericSlot:
    path: tuple[str | int, ...]
    type_name: str
    example: int | float

    @property
    def key(self) -> str:
        return "/" + "/".join(str(part) for part in self.path)


@dataclass(frozen=True)
class CompiledChoiceSets:
    graph_source: str
    contracts_source: str
    region_authorship: str
    domain_authorship: str
    family_order: tuple[str, ...]
    regions: tuple[dict[str, Any], ...]
    family_domains: dict[str, str]
    contracts: tuple[ContractSchema, ...]
    contract_row_count: int

    def region_for_family(self, family: str) -> dict[str, Any]:
        for region in self.regions:
            if family in region["families"]:
                return region
        raise KeyError(f"family is absent from the authored partition: {family}")

    def schemas_for_family(self, family: str) -> tuple[ContractSchema, ...]:
        return tuple(schema for schema in self.contracts if schema.family == family)

    def schema_by_id(self, schema_id: str) -> ContractSchema:
        for schema in self.contracts:
            if schema.schema_id == schema_id:
                return schema
        raise KeyError(schema_id)

    def l1_pages(self, *, masked_region_ids: Iterable[str] = ()) -> tuple[ChoicePage, ...]:
        masked = set(masked_region_ids)
        choices = [
            (region["id"], region["label"], region["id"])
            for region in self.regions
            if region["id"] not in masked
        ]
        return make_pages("L1", "What is the work mostly doing?", choices)

    def l2_pages(self, region_id: str) -> tuple[ChoicePage, ...]:
        region = next(region for region in self.regions if region["id"] == region_id)
        choices = [(family, plain_label(family), family) for family in region["families"]]
        return make_pages("L2", "Which Hermes family best matches the work?", choices)

    def l3_pages(self, family: str) -> tuple[ChoicePage, ...]:
        schemas = self.schemas_for_family(family)
        if len(schemas) > MAX_CONTENT_CHOICES:
            raise ValueError(f"{family} requires its discriminator stage before schema selection")
        choices = [
            (schema.schema_id, schema_label(schema), schema.schema_id)
            for schema in schemas
        ]
        return make_pages("L3", "What operand shape does the work use?", choices)

    def l3_discriminator_pages(self, family: str) -> tuple[ChoicePage, ...]:
        discriminators = sorted({schema.discriminator for schema in self.schemas_for_family(family)})
        choices = [
            (discriminator, plain_label(discriminator), discriminator)
            for discriminator in discriminators
        ]
        return make_pages("L3-kind", "Which operand-shape kind does the work use?", choices)

    def l3_schema_pages(self, family: str, discriminator: str) -> tuple[ChoicePage, ...]:
        schemas = tuple(
            schema for schema in self.schemas_for_family(family)
            if schema.discriminator == discriminator
        )
        choices = [
            (schema.schema_id, schema_label(schema), schema.schema_id)
            for schema in schemas
        ]
        return make_pages("L3-schema", "Which schema within that kind matches the work?", choices)

    def to_dict(self) -> dict[str, Any]:
        families: dict[str, Any] = {}
        for family in self.family_order:
            schemas = self.schemas_for_family(family)
            family_row: dict[str, Any] = {
                "domain": self.family_domains[family],
                "schemas": [asdict(schema) for schema in schemas],
            }
            if len(schemas) <= MAX_CONTENT_CHOICES:
                family_row["l3_pages"] = pages_as_dicts(self.l3_pages(family))
            else:
                family_row["l3_discriminator_pages"] = pages_as_dicts(
                    self.l3_discriminator_pages(family)
                )
                family_row["l3_schema_pages"] = {
                    discriminator: pages_as_dicts(self.l3_schema_pages(family, discriminator))
                    for discriminator in sorted({schema.discriminator for schema in schemas})
                }
            families[family] = family_row
        return {
            "schema": 1,
            "sources": {
                "family_graph": self.graph_source,
                "input_contracts": self.contracts_source,
            },
            "authorship": {
                "region_partition": self.region_authorship,
                "family_domain_map": self.domain_authorship,
            },
            "counts": {
                "families": len(self.family_order),
                "contract_rows": self.contract_row_count,
                "distinct_schemas": len(self.contracts),
            },
            "l1_pages": pages_as_dicts(self.l1_pages()),
            "l2_pages": {
                region["id"]: pages_as_dicts(self.l2_pages(region["id"]))
                for region in self.regions
            },
            "families": families,
        }

    def to_bytes(self) -> bytes:
        return (json.dumps(self.to_dict(), ensure_ascii=False, sort_keys=True, indent=2) + "\n").encode("utf-8")


def schema_label(schema: ContractSchema) -> str:
    numeric = ", ".join(f"{slot.key}: {plain_label(slot.type_name)}" for slot in numeric_slots(schema))
    if numeric:
        return f"{plain_label(schema.discriminator)} ({numeric})"
    return f"{plain_label(schema.discriminator)} ({canonical_json(schema.template)})"


def make_pages(
    level: str,
    question: str,
    rows: Iterable[tuple[str, str, Any]],
) -> tuple[ChoicePage, ...]:
    material = list(rows)
    if not material:
        return ()
    chunks = [material[index:index + MAX_CONTENT_CHOICES] for index in range(0, len(material), MAX_CONTENT_CHOICES)]
    pages: list[ChoicePage] = []
    for page_index, chunk in enumerate(chunks):
        choices = [
            Choice(CONTENT_LETTERS[index], key, label, value)
            for index, (key, label, value) in enumerate(chunk)
        ]
        choices.append(Choice(ABSTENTION_LETTER, "abstain", "none of these / cannot tell", None))
        pages.append(ChoicePage(level, question, page_index, len(chunks), tuple(choices)))
    return tuple(pages)


def pages_as_dicts(pages: Iterable[ChoicePage]) -> list[dict[str, Any]]:
    return [asdict(page) for page in pages]


def _decode_json_atom(text: str, *, line_number: int) -> Any:
    try:
        return json.loads(text.replace(r'\"', '"'))
    except json.JSONDecodeError as exc:
        raise ValueError(f"invalid JSON input contract at line {line_number}: {exc}") from exc


def load_contracts(path: Path = INPUT_CONTRACTS) -> tuple[tuple[ContractSchema, ...], int]:
    grouped: dict[tuple[str, str], dict[str, Any]] = {}
    row_count = 0
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        matched = CONTRACT_ROW.match(line)
        if not matched:
            continue
        family, kind, template_text, example_text, verified = matched.groups()
        if verified != "strategy_trace_ok":
            raise ValueError(f"unverified input contract at line {line_number}: {verified}")
        row_count += 1
        template = _decode_json_atom(template_text, line_number=line_number)
        example = _decode_json_atom(example_text, line_number=line_number)
        template_key = canonical_json(template)
        key = family, template_key
        if key not in grouped:
            grouped[key] = {
                "family": family,
                "template": template,
                "example": example,
                "kinds": [],
                "source_lines": [],
            }
        grouped[key]["kinds"].append(kind)
        grouped[key]["source_lines"].append(line_number)

    contracts: list[ContractSchema] = []
    for (family, template_key), row in sorted(grouped.items()):
        template = row["template"]
        discriminator = (
            template.get("kind")
            if isinstance(template, dict) and isinstance(template.get("kind"), str)
            else "untyped"
        )
        digest = hashlib.sha256(template_key.encode("utf-8")).hexdigest()[:16]
        contracts.append(ContractSchema(
            family=family,
            schema_id=f"{family}:{digest}",
            discriminator=discriminator,
            template=template,
            example=row["example"],
            kinds=tuple(sorted(row["kinds"])),
            source_lines=tuple(row["source_lines"]),
        ))
    return tuple(contracts), row_count


def compile_choice_sets() -> CompiledChoiceSets:
    graph = json.loads(FAMILY_GRAPH.read_text(encoding="utf-8"))
    family_order = tuple(node["family"] for node in graph["nodes"])
    if len(family_order) != len(set(family_order)):
        raise ValueError("family quotient contains duplicate family nodes")

    region_data = json.loads(REGION_PARTITION.read_text(encoding="utf-8"))
    domain_data = json.loads(FAMILY_DOMAIN_MAP.read_text(encoding="utf-8"))
    regions = tuple(region_data["regions"])
    partitioned = [family for region in regions for family in region["families"]]
    if len(partitioned) != len(set(partitioned)) or set(partitioned) != set(family_order):
        raise ValueError("authored region partition must contain every quotient family exactly once")
    family_domains = dict(domain_data["map"])
    if set(family_domains) != set(family_order):
        raise ValueError("authored family-domain map must contain every quotient family exactly once")

    contracts, row_count = load_contracts()
    contracted_families = {schema.family for schema in contracts}
    if contracted_families != set(family_order):
        missing = sorted(set(family_order) - contracted_families)
        extra = sorted(contracted_families - set(family_order))
        raise ValueError(f"contract families disagree with quotient; missing={missing}, extra={extra}")
    return CompiledChoiceSets(
        graph_source=str(FAMILY_GRAPH.relative_to(ROOT)),
        contracts_source=str(INPUT_CONTRACTS.relative_to(ROOT)),
        region_authorship=region_data["authorship"],
        domain_authorship=domain_data["authorship"],
        family_order=family_order,
        regions=regions,
        family_domains=family_domains,
        contracts=contracts,
        contract_row_count=row_count,
    )


def numeric_slots(schema: ContractSchema) -> tuple[NumericSlot, ...]:
    slots: list[NumericSlot] = []

    def walk(template: Any, example: Any, path: tuple[str | int, ...]) -> None:
        if isinstance(template, str):
            if template in NUMERIC_TYPES and isinstance(example, (int, float)) and not isinstance(example, bool):
                slots.append(NumericSlot(path, template, example))
            return
        if isinstance(template, dict) and isinstance(example, dict):
            for key in sorted(template):
                if key in example:
                    walk(template[key], example[key], path + (key,))
            return
        if isinstance(template, list) and len(template) == 1 and isinstance(example, list):
            for index, value in enumerate(example):
                walk(template[0], value, path + (index,))

    walk(schema.template, schema.example, ())
    return tuple(slots)


def replace_path(value: Any, path: tuple[str | int, ...], replacement: Any) -> Any:
    copied = copy.deepcopy(value)
    cursor = copied
    for part in path[:-1]:
        cursor = cursor[part]
    if not path:
        return replacement
    cursor[path[-1]] = replacement
    return copied


def conforms(template: Any, value: Any) -> bool:
    if isinstance(template, str):
        if template == "integer":
            return isinstance(value, int) and not isinstance(value, bool)
        if template == "positive_integer":
            return isinstance(value, int) and not isinstance(value, bool) and value > 0
        if template == "number":
            return isinstance(value, (int, float)) and not isinstance(value, bool)
        if template == "positive_number":
            return isinstance(value, (int, float)) and not isinstance(value, bool) and value > 0
        if template == "atom":
            return isinstance(value, str)
        return value == template
    if isinstance(template, dict):
        return isinstance(value, dict) and all(key in value and conforms(child, value[key]) for key, child in template.items())
    if isinstance(template, list):
        return isinstance(value, list) and len(template) == 1 and all(conforms(template[0], item) for item in value)
    return value == template


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, help="write the compiled JSON to this path")
    args = parser.parse_args()
    compiled = compile_choice_sets()
    payload = compiled.to_bytes()
    if args.output:
        args.output.write_bytes(payload)
    else:
        print(payload.decode("utf-8"), end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
