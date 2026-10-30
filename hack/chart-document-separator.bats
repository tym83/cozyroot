#!/usr/bin/env bats
#
# A template action written `{{- ... -}}` trims the newline on both sides of
# itself. Put one between a document separator and the document it introduces
# and the rendered stream carries `---apiVersion:` on one line: the separator
# stops separating, and the two documents become one.
#
# This cannot be caught by rendering. `helm template` writes a `# Source:`
# comment between documents, which lands in the gap and hides the defect
# entirely; the install path writes no such comment and fails with "invalid
# document separator", on a cluster, long after review. So the check reads the
# templates instead of their output.
#
# The rule it enforces: an action that follows a `---` line may trim the
# newline before itself, which is what `{{-` does and is harmless, but must not
# trim the one after. Write `*/}}` or `}}`, not `*/ -}}` or `-}}`.
#
# Vendored charts under packages/*/*/charts are out of scope: they are
# verbatim upstream and `make update` rewrites them, so a finding there is
# fixed with a patches/*.diff rather than an edit. One is known --
# redis-operator's monitoring.yaml, where the ServiceMonitor is off by default
# and the defect is therefore latent.

setup_file() {
    REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
    export REPO_ROOT
}

@test "no chart template trims the newline after a document separator" {
    run python3 - "$REPO_ROOT/packages" <<'PY'
import os, re, sys

root = sys.argv[1]
offenders = []

# An action opening the line right after a `---`, up to its close. The close
# is what matters: `-}}` eats the newline that keeps the separator a line of
# its own.
# The action that opens the line right after a `---`, and whatever follows it.
# Two things have to be true for the separator to be lost: the action trims the
# newline after itself, and what comes next is document content rather than
# another action -- a following `{{-` trims that whitespace itself, so the gap
# is already gone and the text it eventually emits lands normally.
pattern = re.compile(r'^---[ \t]*\n(\{\{-.*?\}\})[ \t]*\n?([^\n]*)', re.S | re.M)

for dirpath, _, filenames in os.walk(root):
    if os.path.basename(dirpath) != 'templates':
        continue
    # Vendored upstream charts are verbatim and `make update` rewrites them,
    # so a finding there cannot be fixed in place -- it needs a patches/*.diff
    # -- and a check that fails on every update is a check someone turns off.
    # They are still worth reporting; see the note at the top of this file.
    if os.sep + 'charts' + os.sep in dirpath:
        continue
    for name in filenames:
        if not name.endswith(('.yaml', '.yml', '.tpl')):
            continue
        path = os.path.join(dirpath, name)
        try:
            text = open(path, encoding='utf-8').read()
        except (OSError, UnicodeDecodeError):
            continue
        for match in pattern.finditer(text):
            follows = match.group(2).lstrip()
            if match.group(1).endswith('-}}') and follows and not follows.startswith('{{'):
                line = text.count('\n', 0, match.start(1)) + 1
                offenders.append(f"{os.path.relpath(path, root)}:{line}")

if offenders:
    print("an action right after `---` must not end with -}}:")
    for o in offenders:
        print("  " + o)
    sys.exit(1)
PY
    [ "$status" -eq 0 ] || {
        printf '%s\n' "$output" >&2
        false
    }
}
