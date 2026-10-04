# Documentary patches

`fdb_v3_changes.patch` is the diff of our vendored `Full-Duplex-Bench/v3` files versus upstream commit `3e799c45a045256f47d5f1c9cda90157e2d2ec9e`.

The submission **vendors** those files with the patch already applied. Reproduction scripts never `git clone` Full-Duplex-Bench and never `git apply` this file. It exists so reviewers can see the harness delta without an extra clone.

To re-check on a clean upstream checkout:

```bash
git clone https://github.com/DanielLin94144/Full-Duplex-Bench.git /tmp/fdb
git -C /tmp/fdb checkout 3e799c45a045256f47d5f1c9cda90157e2d2ec9e
git apply --directory=/tmp/fdb patches/fdb_v3_changes.patch
diff -u /tmp/fdb/v3/lk_agent_tool.py Full-Duplex-Bench/v3/lk_agent_tool.py
```
