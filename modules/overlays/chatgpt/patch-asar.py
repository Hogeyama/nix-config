"""Replace one file inside an asar archive in place.

The replacement is padded to the original entry's exact byte length so every
offset in the archive stays valid, and the entry's integrity hash is rewritten
by substituting the old hex digest with the new one inside the raw header
bytes. Both digests are 64 hex characters, so the header's length -- and
therefore the archive's data offset -- is unchanged. Re-serialising the header
JSON would risk changing its length, so it is deliberately never re-encoded.
"""

import hashlib
import json
import struct
import sys


def find_entry(node, target, path=""):
    for name, value in node.get("files", {}).items():
        child = path + "/" + name
        if "files" in value:
            found = find_entry(value, target, child)
            if found is not None:
                return found
        elif child == target:
            return value
    return None


def main():
    archive, target, replacement = sys.argv[1:4]

    with open(archive, "r+b") as f:
        _, header_size, _, json_len = struct.unpack("<IIII", f.read(16))
        header_bytes = f.read(json_len)
        header = json.loads(header_bytes.decode("utf-8"))
        data_offset = 8 + header_size

        entry = find_entry(header, target)
        if entry is None:
            raise SystemExit(f"{target} not found in {archive}")

        size = entry["size"]
        with open(replacement, "rb") as g:
            content = g.read()
        if len(content) > size:
            raise SystemExit(
                f"replacement is {len(content)} bytes, must not exceed {size}"
            )
        content += b" " * (size - len(content))

        f.seek(data_offset + int(entry["offset"]))
        f.write(content)

        integrity = entry.get("integrity")
        if integrity is not None:
            if integrity.get("algorithm") != "SHA256":
                raise SystemExit(f"unsupported integrity algorithm in {target}")
            old = integrity["hash"]
            new = hashlib.sha256(content).hexdigest()
            if len(old) != len(new):
                raise SystemExit("digest length changed, header would shift")
            patched = header_bytes.replace(old.encode(), new.encode())
            if patched == header_bytes:
                raise SystemExit(f"integrity hash for {target} not found in header")
            f.seek(16)
            f.write(patched)

    print(f"patched {target} in {archive}")


if __name__ == "__main__":
    main()
