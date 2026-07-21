#!/usr/bin/env bash
#
# blame-line-counts.sh
#
# Counts how many lines of Elm code each author is currently responsible for,
# using `git blame` (i.e. the last person to touch each line). Only .elm files
# are considered, and src/Evergreen is ignored (it's auto-generated migration /
# type-snapshot code, not hand-written).
#
# Usage:
#   scripts/blame-line-counts.sh            Report per-author line counts.
#   scripts/blame-line-counts.sh --email    Group by author email instead of name.
#
# Notes:
#   * Whitespace-only changes are ignored for attribution (blame -w), so a
#     reformat doesn't steal ownership of a line from its real author.
#   * Add more paths to EXCLUDES below to skip them (e.g. "vendored/" for the
#     third-party packages, which otherwise get attributed to whoever committed
#     the vendored copy).
#
set -euo pipefail

# Run from the repo root regardless of where the script is invoked.
cd "$(git rev-parse --show-toplevel)"

# Pathspecs to exclude. src/Evergreen is auto-generated; ignore it.
EXCLUDES=(':(exclude)src/Evergreen/')

# Which blame field to group by.
FIELD="author"
if [ "${1:-}" = "--email" ]; then
    FIELD="author-mail"
fi

# List the Elm files, blame each one, and pull out the author of every line.
authors() {
    git ls-files -z -- '*.elm' "${EXCLUDES[@]}" \
        | while IFS= read -r -d '' file; do
            git blame -w --line-porcelain -- "$file"
        done \
        | sed -n "s/^${FIELD} //p"
}

authors \
    | sort \
    | uniq -c \
    | sort -rn \
    | awk '
        {
            cnt = $1
            sub(/^[ ]*[0-9]+[ ]+/, "")   # strip the count, keep the (possibly spaced) name
            name[NR] = $0
            cnts[NR] = cnt
            total += cnt
            n = NR
        }
        END {
            if (total == 0) {
                print "No Elm lines found." > "/dev/stderr"
                exit 1
            }
            printf "%-34s %8s %8s\n", "Author", "Lines", "Share"
            printf "%-34s %8s %8s\n", "------", "-----", "-----"
            for (i = 1; i <= n; i++)
                printf "%-34s %8d %7.1f%%\n", name[i], cnts[i], 100 * cnts[i] / total
            printf "%-34s %8s %8s\n", "------", "-----", "-----"
            printf "%-34s %8d %7.1f%%\n", "TOTAL", total, 100
        }'
