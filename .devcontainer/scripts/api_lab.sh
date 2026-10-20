
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$root_dir"

mkdir -p scripts data logs
LOG_FILE="logs/lab3.log"
touch "$LOG_FILE"

log() {
    printf "%s - %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$1" | tee -a "$LOG_FILE"
}

cleanup() {
    log "LAB3_END"
}
trap cleanup EXIT

log "LAB3_START"

for tool in curl jq; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        log "Error: Missing required tool: $tool"
        exit 1
    fi
done

log "BASH_OK"

# Dad Jokes API
JOKE_STATUS=$(curl -sS \
    -H 'Accept: application/json' \
    -w '%{http_code}' \
    -o data/dad_joke.json \
    https://icanhazdadjoke.com/)

if [[ "$JOKE_STATUS" != "200" ]]; then
    log "CURL_JOKE_FAIL"
    exit 1
fi
log "CURL_JOKE_OK"

jq -r '"ID: \(.id)\nJoke: \(.joke)"' \
    data/dad_joke.json > data/dad_joke.txt
log "JQ_JOKE_OK"

# Create a deck
DECK_STATUS=$(curl -sS \
    -w '%{http_code}' \
    -o data/deck_create.json \
    'https://deckofcardsapi.com/api/deck/new/shuffle/?deck_count=1')

if [[ "$DECK_STATUS" != "200" ]]; then
    log "DECK_CREATE_FAIL"
    exit 1
fi

DECK_ID=$(jq -er '.deck_id' data/deck_create.json)
log "DECK_CREATE_OK"

# Draw two cards
DRAW_STATUS=$(curl -sS \
    -w '%{http_code}' \
    -o data/deck_draw.json \
    "https://deckofcardsapi.com/api/deck/$DECK_ID/draw/?count=2")

if [[ "$DRAW_STATUS" != "200" ]]; then
    log "DECK_DRAW_FAIL"
    exit 1
fi
log "DECK_DRAW_OK"

jq -r '"Cards drawn:", (.cards[] | "\(.value) of \(.suit)"), "Remaining: \(.remaining)"' \
    data/deck_draw.json > data/deck_summary.txt
log "JQ_DECK_OK"

# Check Postman exports
if [[ -s data/postman_curl.txt ]]; then
    log "POSTMAN_EXPORT_CURL_OK"
fi

if [[ -s data/postman_python.py ]]; then
    log "POSTMAN_EXPORT_PY_OK"
fi

# Record Canvas submission only after submitting
if grep -q 'CANVAS_SUBMITTED' "$LOG_FILE"; then
    log "CANVAS_SUBMITTED"
fi
