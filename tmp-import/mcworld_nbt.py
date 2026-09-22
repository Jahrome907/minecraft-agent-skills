#!/usr/bin/env python3
"""Minecraft Java 1.21.8 NBT / Anvil region inspection and targeted editing.

Pure-Python NBT parser/writer. Region compression supports gzip, zlib, none,
and Mojang/Paper's lz4-java LZ4Block stream when python-lz4 is installed.

Safety model:
- Read operations never modify inputs.
- Write operations require a distinct --out path.
- Existing output files are refused unless --force is supplied.
- Region edits preserve all untouched chunk bytes and their timestamps.
- Modified chunks preserve their original compression codec.
"""
from __future__ import annotations

import argparse
import copy
import dataclasses
import gzip
import hashlib
import io
import json
import math
import os
from pathlib import Path
import re
import shutil
import struct
import sys
import time
import zlib
from collections import OrderedDict
from typing import Any, Iterable

try:
    import lz4.block as _lz4_block
except Exception:
    _lz4_block = None

TAG_NAMES = {
    0: "end", 1: "byte", 2: "short", 3: "int", 4: "long",
    5: "float", 6: "double", 7: "byte_array", 8: "string",
    9: "list", 10: "compound", 11: "int_array", 12: "long_array",
}
NAME_TO_TAG = {v: k for k, v in TAG_NAMES.items()}
MAX_DEPTH = 512
MAX_CONTAINER_ITEMS = 64_000_000
SECTOR_BYTES = 4096
REGION_HEADER_BYTES = 8192
EXTERNAL_STREAM_FLAG = 0x80
REGION_RE = re.compile(r"^r\.(-?\d+)\.(-?\d+)\.mca$")

class NBTError(Exception):
    pass

class RegionError(Exception):
    pass

@dataclasses.dataclass
class ListValue:
    element_type: int
    items: list["Tag"]

@dataclasses.dataclass
class Tag:
    type_id: int
    value: Any

@dataclasses.dataclass
class RootTag:
    name: str
    tag: Tag

# -------------------- binary helpers / MUTF-8 --------------------

def _read_exact(f: io.BufferedIOBase | io.BytesIO, n: int) -> bytes:
    if n < 0:
        raise NBTError(f"negative read length: {n}")
    b = f.read(n)
    if len(b) != n:
        raise NBTError(f"unexpected EOF: wanted {n}, got {len(b)}")
    return b

def _unpack(f, fmt: str):
    size = struct.calcsize(fmt)
    return struct.unpack(fmt, _read_exact(f, size))[0]

def decode_mutf8(data: bytes) -> str:
    # Java DataInput.readUTF compatible modified UTF-8 -> UTF-16 code units.
    units: list[int] = []
    i = 0
    n = len(data)
    while i < n:
        c = data[i]
        if c <= 0x7F and c != 0:
            units.append(c); i += 1
        elif (c & 0xE0) == 0xC0:
            if i + 1 >= n:
                raise NBTError("truncated modified UTF-8 sequence")
            c2 = data[i+1]
            if (c2 & 0xC0) != 0x80:
                raise NBTError("invalid modified UTF-8 continuation")
            units.append(((c & 0x1F) << 6) | (c2 & 0x3F)); i += 2
        elif (c & 0xF0) == 0xE0:
            if i + 2 >= n:
                raise NBTError("truncated modified UTF-8 sequence")
            c2, c3 = data[i+1], data[i+2]
            if (c2 & 0xC0) != 0x80 or (c3 & 0xC0) != 0x80:
                raise NBTError("invalid modified UTF-8 continuation")
            units.append(((c & 0x0F) << 12) | ((c2 & 0x3F) << 6) | (c3 & 0x3F)); i += 3
        else:
            raise NBTError("invalid modified UTF-8 lead byte")
    raw = b"".join(struct.pack(">H", u) for u in units)
    return raw.decode("utf-16-be", errors="surrogatepass")

def encode_mutf8(s: str) -> bytes:
    raw = s.encode("utf-16-be", errors="surrogatepass")
    out = bytearray()
    for i in range(0, len(raw), 2):
        u = (raw[i] << 8) | raw[i+1]
        if 0x0001 <= u <= 0x007F:
            out.append(u)
        elif u <= 0x07FF:
            out.extend((0xC0 | ((u >> 6) & 0x1F), 0x80 | (u & 0x3F)))
        else:
            out.extend((0xE0 | ((u >> 12) & 0x0F), 0x80 | ((u >> 6) & 0x3F), 0x80 | (u & 0x3F)))
    if len(out) > 65535:
        raise NBTError("NBT string exceeds modified UTF-8 unsigned-short limit")
    return bytes(out)

def _read_string(f) -> str:
    n = _unpack(f, ">H")
    return decode_mutf8(_read_exact(f, n))

def _write_string(f, s: str) -> None:
    b = encode_mutf8(s)
    f.write(struct.pack(">H", len(b)))
    f.write(b)

# -------------------- NBT parse/write --------------------

def _check_length(n: int, kind: str) -> int:
    if n < 0:
        raise NBTError(f"negative {kind} length: {n}")
    if n > MAX_CONTAINER_ITEMS:
        raise NBTError(f"refusing implausibly large {kind} length: {n}")
    return n

def read_payload(f, type_id: int, depth: int = 0) -> Tag:
    if depth > MAX_DEPTH:
        raise NBTError("NBT nesting exceeds safety limit")
    if type_id == 1: return Tag(type_id, _unpack(f, ">b"))
    if type_id == 2: return Tag(type_id, _unpack(f, ">h"))
    if type_id == 3: return Tag(type_id, _unpack(f, ">i"))
    if type_id == 4: return Tag(type_id, _unpack(f, ">q"))
    if type_id == 5: return Tag(type_id, _unpack(f, ">f"))
    if type_id == 6: return Tag(type_id, _unpack(f, ">d"))
    if type_id == 7:
        n = _check_length(_unpack(f, ">i"), "byte array")
        b = _read_exact(f, n)
        vals = [x if x < 128 else x - 256 for x in b]
        return Tag(type_id, vals)
    if type_id == 8: return Tag(type_id, _read_string(f))
    if type_id == 9:
        elem = _unpack(f, ">B")
        if elem not in TAG_NAMES:
            raise NBTError(f"unknown list element tag id {elem}")
        n = _check_length(_unpack(f, ">i"), "list")
        if elem == 0 and n != 0:
            raise NBTError("TAG_End list element type with non-empty list")
        items = [read_payload(f, elem, depth + 1) for _ in range(n)]
        return Tag(type_id, ListValue(elem, items))
    if type_id == 10:
        d: OrderedDict[str, Tag] = OrderedDict()
        while True:
            child_type = _unpack(f, ">B")
            if child_type == 0:
                break
            if child_type not in TAG_NAMES:
                raise NBTError(f"unknown compound tag id {child_type}")
            name = _read_string(f)
            if name in d:
                raise NBTError(f"duplicate compound key {name!r}; refusing lossy parse")
            d[name] = read_payload(f, child_type, depth + 1)
        return Tag(type_id, d)
    if type_id == 11:
        n = _check_length(_unpack(f, ">i"), "int array")
        return Tag(type_id, list(struct.unpack(f">{n}i", _read_exact(f, n * 4))) if n else [])
    if type_id == 12:
        n = _check_length(_unpack(f, ">i"), "long array")
        return Tag(type_id, list(struct.unpack(f">{n}q", _read_exact(f, n * 8))) if n else [])
    raise NBTError(f"unsupported tag id {type_id}")

def read_nbt(data: bytes) -> RootTag:
    f = io.BytesIO(data)
    root_type = _unpack(f, ">B")
    if root_type == 0:
        raise NBTError("root tag cannot be TAG_End")
    if root_type not in TAG_NAMES:
        raise NBTError(f"unknown root tag id {root_type}")
    name = _read_string(f)
    tag = read_payload(f, root_type, 0)
    trailing = f.read()
    if trailing and any(b != 0 for b in trailing):
        # Preserve strictness: compressed payload should contain exactly one root tag.
        raise NBTError(f"non-zero trailing bytes after root NBT: {len(trailing)}")
    return RootTag(name, tag)

def _write_payload(f, tag: Tag, depth: int = 0) -> None:
    if depth > MAX_DEPTH:
        raise NBTError("NBT nesting exceeds safety limit")
    t, v = tag.type_id, tag.value
    if t == 1: f.write(struct.pack(">b", int(v))); return
    if t == 2: f.write(struct.pack(">h", int(v))); return
    if t == 3: f.write(struct.pack(">i", int(v))); return
    if t == 4: f.write(struct.pack(">q", int(v))); return
    if t == 5: f.write(struct.pack(">f", float(v))); return
    if t == 6: f.write(struct.pack(">d", float(v))); return
    if t == 7:
        f.write(struct.pack(">i", len(v)))
        f.write(bytes((int(x) & 0xFF) for x in v)); return
    if t == 8: _write_string(f, str(v)); return
    if t == 9:
        if not isinstance(v, ListValue): raise NBTError("malformed TAG_List")
        f.write(struct.pack(">B", v.element_type)); f.write(struct.pack(">i", len(v.items)))
        for child in v.items:
            if child.type_id != v.element_type:
                raise NBTError("TAG_List child type mismatch")
            _write_payload(f, child, depth + 1)
        return
    if t == 10:
        for name, child in v.items():
            if child.type_id == 0: raise NBTError("TAG_End cannot be named compound child")
            f.write(struct.pack(">B", child.type_id)); _write_string(f, name); _write_payload(f, child, depth + 1)
        f.write(b"\x00"); return
    if t == 11:
        f.write(struct.pack(">i", len(v)))
        if v: f.write(struct.pack(f">{len(v)}i", *map(int, v)))
        return
    if t == 12:
        f.write(struct.pack(">i", len(v)))
        if v: f.write(struct.pack(f">{len(v)}q", *map(int, v)))
        return
    raise NBTError(f"cannot write tag id {t}")

def write_nbt(root: RootTag) -> bytes:
    f = io.BytesIO()
    f.write(struct.pack(">B", root.tag.type_id)); _write_string(f, root.name); _write_payload(f, root.tag)
    return f.getvalue()

# -------------------- typed JSON / tree --------------------

def tag_to_typed(tag: Tag, max_array: int | None = None) -> dict[str, Any]:
    t = tag.type_id
    out: dict[str, Any] = {"type": TAG_NAMES[t]}
    if t == 9:
        lv: ListValue = tag.value
        out["element_type"] = TAG_NAMES[lv.element_type]
        out["value"] = [tag_to_typed(x, max_array) for x in lv.items]
    elif t == 10:
        out["value"] = {k: tag_to_typed(v, max_array) for k, v in tag.value.items()}
    elif t in (7, 11, 12) and max_array is not None and len(tag.value) > max_array:
        out["length"] = len(tag.value)
        out["preview"] = tag.value[:max_array]
        out["truncated"] = True
    else:
        out["value"] = tag.value
    return out

def typed_to_tag(obj: dict[str, Any]) -> Tag:
    if not isinstance(obj, dict) or "type" not in obj:
        raise NBTError("typed JSON tag requires object with 'type'")
    type_name = obj["type"]
    if type_name not in NAME_TO_TAG or type_name == "end":
        raise NBTError(f"invalid typed JSON tag type: {type_name!r}")
    t = NAME_TO_TAG[type_name]
    if t == 9:
        et = obj.get("element_type")
        if et not in NAME_TO_TAG or et == "end" and obj.get("value"):
            raise NBTError("invalid list element_type")
        items = [typed_to_tag(x) for x in obj.get("value", [])]
        etid = NAME_TO_TAG[et]
        if any(x.type_id != etid for x in items): raise NBTError("list child type mismatch")
        return Tag(t, ListValue(etid, items))
    if t == 10:
        val = obj.get("value", {})
        if not isinstance(val, dict): raise NBTError("compound value must be object")
        return Tag(t, OrderedDict((k, typed_to_tag(v)) for k, v in val.items()))
    return make_scalar_tag(type_name, obj.get("value"))

def make_scalar_tag(type_name: str, value: Any) -> Tag:
    if type_name not in NAME_TO_TAG or type_name in ("end", "list", "compound"):
        raise NBTError(f"set-scalar does not accept type {type_name!r}")
    t = NAME_TO_TAG[type_name]
    if t in (1,2,3,4):
        if isinstance(value, bool) or not isinstance(value, int): raise NBTError(f"{type_name} requires integer JSON value")
        ranges = {1:(-128,127),2:(-32768,32767),3:(-2147483648,2147483647),4:(-9223372036854775808,9223372036854775807)}
        lo, hi = ranges[t]
        if not lo <= value <= hi: raise NBTError(f"{type_name} out of range")
    elif t in (5,6):
        if isinstance(value, bool) or not isinstance(value, (int,float)): raise NBTError(f"{type_name} requires numeric JSON value")
        value = float(value)
    elif t == 8:
        if not isinstance(value, str): raise NBTError("string requires JSON string")
    elif t in (7,11,12):
        if not isinstance(value, list) or any(isinstance(x,bool) or not isinstance(x,int) for x in value):
            raise NBTError(f"{type_name} requires JSON integer array")
        if t == 7 and any(x < -128 or x > 255 for x in value): raise NBTError("byte_array values must be -128..255")
        if t == 11 and any(x < -2147483648 or x > 2147483647 for x in value): raise NBTError("int_array value out of range")
        if t == 12 and any(x < -9223372036854775808 or x > 9223372036854775807 for x in value): raise NBTError("long_array value out of range")
    return Tag(t, value)

def pointer_parts(path: str) -> list[str]:
    if path in ("", "/"): return []
    if not path.startswith("/"): raise NBTError(NBT path must be JSON-pointer style, e.g. /Data/LevelName")
    return [x.replace("~1", "/").replace("~0", "~") for x in path[1:].split("/")]

def resolve_tag(root: Tag, path: str) -> Tag:
    cur = root
    for p in pointer_parts(path):
        if cur.type_id == 10:
            if p not in cur.value: raise NBTError(f"compound key not found at {p!r}")
            cur = cur.value[p]
        elif cur.type_id == 9:
            try: idx = int(p)
            except ValueError: raise NBTError(f"list path component must be integer, got {p!r}")
            lv: ListValue = cur.value
            if idx < 0: idx += len(lv.items)
            if not 0 <= idx < len(lv.items): raise NBTError(f"list index out of range: {idx}")
            cur = lv.items[idx]
        else:
            raise NBTError(f"cannot descend through {TAG_NAMES[cur.type_id]}")
    return cur

def replace_tag(root: Tag, path: str, replacement: Tag, create: bool = False) -> None:
    parts = pointer_parts(path)
    if not parts: raise NBTError("refusing to replace root with set; use typed export/import workflow")
    cur = root
    for p in parts[:-1]:
        if cur.type_id == 10:
            if p not in cur.value: raise NBTError(f"compound key not found at {p!r}")
            cur = cur.value[p]
        elif cur.type_id == 9:
            lv: ListValue = cur.value
            try: idx = int(p)
            except ValueError: raise NBTError(f"list path component must be integer, got {p!r}")
            cur = lv.items[idx]
        else: raise NBTError(f"cannot descend through {TAG_NAMES[cur.type_id]}")
    last = parts[-1]
    if cur.type_id == 10:
        if last not in cur.value and not create: raise NBTError(f"compound key not found at {last!r}; use --create explicitly")
        cur.value[last] = replacement
    elif cur.type_id == 9:
        lv = cur.value
        try: idx = int(last)
        except ValueError: raise NBTError("list target must be integer")
        if replacement.type_id != lv.element_type: raise NBTError("replacement type does not match list element type")
        lv.items[idx] = replacement
    else: raise NBTError(f"cannot replace child of {TAG_NAMES[cur.type_id]}")

def _preview_scalar(tag: Tag, max_chars=120) -> str:
    t, v = tag.type_id, tag.value
    if t == 8:
        r = json.dumps(v, ensure_ascii=False)
        return r if len(r) <= max_chars else r[:max_chars-3] + "..."
    if t in (7,11,12):
        return f"len={len(v)} preview={v[:8]}"
    if t == 9: return f"len={len(v.items)} element={TAG_NAMES[v.e