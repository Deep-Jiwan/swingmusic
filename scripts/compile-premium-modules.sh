#!/usr/bin/env bash
# compile-premium-modules.sh
#
# Compiles every non-__init__ .py file under src/swingmusic/premium/ into a
# native CPython extension (.so) using Nuitka --module mode.
#
# The resulting .so files are written back into the same directory as their
# source counterparts so that the Dockerfile builder stage can do:
#
#   RUN find src/swingmusic/premium -name "*.py" ! -name "__init__.py" -delete
#   COPY --from=compiler /build/src/swingmusic/premium/ ./src/swingmusic/premium/
#
# and end up with compiled extensions in place of the original source files.

set -euo pipefail

PREMIUM_DIR="${1:-src/swingmusic/premium}"

echo "==> Scanning ${PREMIUM_DIR} for Python modules to compile..."

# Collect all .py files except __init__.py
mapfile -t PY_FILES < <(find "${PREMIUM_DIR}" -name "*.py" ! -name "__init__.py")

if [[ ${#PY_FILES[@]} -eq 0 ]]; then
    echo "    No non-init Python files found — nothing to compile."
    exit 0
fi

for py_file in "${PY_FILES[@]}"; do
    # Derive the output directory (same as the source file's directory)
    out_dir="$(dirname "${py_file}")"

    echo "==> Compiling ${py_file} -> ${out_dir}/"

    python -m nuitka \
        --module \
        --remove-output \
        --no-pyi-file \
        --output-dir="${out_dir}" \
        "${py_file}"
done

echo "==> Compilation complete."
