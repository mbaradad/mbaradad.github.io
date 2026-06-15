#!/usr/bin/env bash
# Generates files/cv.pdf from files/cv.html.
#
# Source of truth: files/cv.html  (edit the CV there; run this script to rebuild the PDF)
# Output:          files/cv.pdf
#
# Renderer priority:
#   1. weasyprint  (pip install weasyprint)  — pure-Python, proper typeset PDF
#   2. Google Chrome headless                — pixel-perfect, requires Chrome
#   3. wkhtmltopdf                           — fallback (brew install wkhtmltopdf)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$SCRIPT_DIR/files/cv.html"
OUT="$SCRIPT_DIR/files/cv.pdf"

if [ ! -f "$SRC" ]; then
  echo "ERROR: source not found: $SRC" >&2
  exit 1
fi

echo "Source : $SRC"
echo "Output : $OUT"
echo ""

# ── 1. weasyprint ────────────────────────────────────────────────
if python3 -c "import weasyprint" 2>/dev/null; then
  echo "Renderer: weasyprint"
  python3 - "$SRC" "$OUT" << 'PY'
import sys, pathlib
from weasyprint import HTML, CSS

src = pathlib.Path(sys.argv[1]).resolve()
out = pathlib.Path(sys.argv[2]).resolve()

# Override the body padding to zero — @page margins handle spacing in PDF.
extra_css = CSS(string="""
  @page { size: A4; margin: 2.2cm 2cm; }
  body  { max-width: none !important; padding: 0 !important; margin: 0 !important; }
""")

HTML(filename=str(src)).write_pdf(str(out), stylesheets=[extra_css])
PY
  echo "Done."
  exit 0
fi

echo "weasyprint not found — trying Chrome headless..."

# ── 2. Google Chrome headless ────────────────────────────────────
CHROME_PATHS=(
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
  "/Applications/Chromium.app/Contents/MacOS/Chromium"
  "google-chrome"
  "google-chrome-stable"
  "chromium"
  "chromium-browser"
)
for CHROME in "${CHROME_PATHS[@]}"; do
  if [ -x "$CHROME" ] || command -v "$CHROME" &>/dev/null 2>&1; then
    echo "Renderer: Chrome headless ($CHROME)"
    "$CHROME" \
      --headless=new \
      --no-sandbox \
      --disable-gpu \
      --disable-extensions \
      --print-to-pdf="$OUT" \
      --print-to-pdf-no-header \
      --no-pdf-header-footer \
      "file://$SRC" 2>/dev/null
    echo "Done."
    exit 0
  fi
done

echo "Chrome not found — trying wkhtmltopdf..."

# ── 3. wkhtmltopdf ───────────────────────────────────────────────
if command -v wkhtmltopdf &>/dev/null; then
  echo "Renderer: wkhtmltopdf"
  wkhtmltopdf \
    --page-size A4 \
    --margin-top 22mm --margin-bottom 25mm \
    --margin-left 20mm --margin-right 20mm \
    --enable-local-file-access \
    --print-media-type \
    "$SRC" "$OUT"
  echo "Done."
  exit 0
fi

# ── Nothing found ─────────────────────────────────────────────────
cat << 'MSG'

ERROR: No PDF renderer found. Install one of the following, then re-run:

  pip install weasyprint            # recommended

  brew install --cask google-chrome # or use existing Chrome

  brew install wkhtmltopdf          # fallback

MSG
exit 1
