#!/bin/bash
# ==========================================================
# 🦴 BITHOG — Bitbucket Secret Scanner
# Author: KullaiSec / https://github.com/kullaisec
# Version: 1.0
# Description:
#   A macOS-compatible Bitbucket OAuth + TruffleHog scanner
#   that finds and reports verified secrets in clean text format.
# ==========================================================

set -e
IFS=$'\n\t'

# === BANNER ===
clear
echo ""
echo -e "\033[1;35m ███████████   ███   █████    █████                       \033[0m"
echo -e "\033[1;35m░░███░░░░░███ ░░░   ░░███    ░░███                        \033[0m"
echo -e "\033[1;35m ░███    ░███ ████  ███████   ░███████    ██████   ███████\033[0m"
echo -e "\033[1;35m ░██████████ ░░███ ░░░███░    ░███░░███  ███░░███ ███░░███\033[0m"
echo -e "\033[1;35m ░███░░░░░███ ░███   ░███     ░███ ░███ ░███ ░███░███ ░███\033[0m"
echo -e "\033[1;35m ░███    ░███ ░███   ░███ ███ ░███ ░███ ░███ ░███░███ ░███\033[0m"
echo -e "\033[1;35m ███████████  █████  ░░█████  ████ █████░░██████ ░░███████\033[0m"
echo -e "\033[1;35m░░░░░░░░░░░  ░░░░░    ░░░░░  ░░░░ ░░░░░  ░░░░░░   ░░░░░███\033[0m"
echo -e "\033[1;35m                                                  ███ ░███\033[0m"
echo -e "\033[1;35m                                                 ░░██████ \033[0m"
echo -e "\033[1;35m                                                  ░░░░░░  \033[0m"
echo ""
echo -e "\033[1;36m                   🦴 BITHOG v1.0\033[0m"
echo -e "\033[1;36m         Bitbucket Secret Leak Scanner by Kullaisec\033[0m"
echo "----------------------------------------------------------"
echo ""

# === HARD-CODED TESTING VALUES ===
CLIENT_ID="Replace your ID"
CLIENT_SECRET="Replace your secret"

# Ask for workspace interactively
read -p "Enter your Bitbucket workspace/org name (e.g. getsentry, kullaisec): " WORKSPACE

# === SAFETY CHECK ===
if [[ "$CLIENT_ID" == "PASTE_YOUR_CLIENT_ID_HERE" || "$CLIENT_SECRET" == "PASTE_YOUR_CLIENT_SECRET_HERE" ]]; then
  echo "❌ Please replace CLIENT_ID and CLIENT_SECRET in the script before running."
  exit 1
fi

# === CHECK DEPENDENCIES ===
for cmd in curl jq trufflehog; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "❌ Missing $cmd. Install with: brew install $cmd"
    exit 1
  fi
done

# === FETCH ACCESS TOKEN ===
echo "🔑 Requesting OAuth access token..."
TOKEN_RESPONSE=$(curl -s -X POST -u "${CLIENT_ID}:${CLIENT_SECRET}" \
  https://bitbucket.org/site/oauth2/access_token \
  -d grant_type=client_credentials)
ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token')

if [[ -z "$ACCESS_TOKEN" || "$ACCESS_TOKEN" == "null" ]]; then
  echo "❌ Failed to fetch access token."
  echo "$TOKEN_RESPONSE"
  exit 1
fi
echo "✅ Access token retrieved."

# === ENUMERATE REPOSITORIES ===
OUTDIR="bitbucket_scan_${WORKSPACE}_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTDIR"
TEXT_REPORT="${OUTDIR}/bitbucket_secret_scan_report.txt"
TMP_SUMMARY="${OUTDIR}/summary_tmp.txt"
> "$TEXT_REPORT"
> "$TMP_SUMMARY"

{
  echo "==================== Bitbucket Secret Scan Report ===================="
  echo "Workspace: ${WORKSPACE}"
  echo "Scan started: $(date)"
  echo "---------------------------------------------------------------------"
} >> "$TEXT_REPORT"

PAGE=1
REPOS=()
while true; do
  RESP=$(curl -s -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    "https://api.bitbucket.org/2.0/repositories/${WORKSPACE}?pagelen=100&page=${PAGE}")
  while IFS= read -r url; do
    REPOS+=("$url")
  done < <(echo "$RESP" | jq -r '.values[]?.links.clone[]? | select(.name=="https") | .href')
  NEXT=$(echo "$RESP" | jq -r '.next // empty')
  [[ -z "$NEXT" ]] && break
  ((PAGE++))
done

if [[ ${#REPOS[@]} -eq 0 ]]; then
  echo "❌ No repositories found for workspace '${WORKSPACE}'."
  exit 1
fi
echo "✅ Found ${#REPOS[@]} repositories to scan."

# === SCAN EACH REPO ===
for REPO in "${REPOS[@]}"; do
  NAME=$(basename "$REPO" .git)
  echo "🚀 Scanning: $NAME ..."
  AUTH_REPO=$(echo "$REPO" | sed -E "s#https://#https://x-token-auth:${ACCESS_TOKEN}@#")

  {
    echo ""
    echo "========== [Repository: $NAME] =========="
    echo "Repo URL: $REPO"
    echo "-----------------------------------------------------------------"
    trufflehog git "$AUTH_REPO" --results=verified 2>&1 | \
      grep -E -v '🐷🔑🐷|info-|finished scanning|running source|scanning repo' || true
  } >> "$TEXT_REPORT"

  FOUND=$(grep -c "✅ Found verified result" "$TEXT_REPORT" || echo "0")
  echo "${NAME} : ${FOUND} findings" >> "$TMP_SUMMARY"
done

# === SUMMARY ===
{
  echo ""
  echo "==================== Scan Summary ===================="
  echo "Total Repositories Scanned: ${#REPOS[@]}"
  echo ""
  cat "$TMP_SUMMARY"
  echo "-------------------------------------------------------"
  echo "Scan completed at: $(date)"
} >> "$TEXT_REPORT"

rm -f "$TMP_SUMMARY"

echo ""
echo "✅ Scan finished successfully."
echo "📄 Clean text report: $TEXT_REPORT"
echo "🧹 All noisy log lines filtered out."
echo ""
echo "----------------------------------------------------------"
echo "   Thank you for using 🦴 BITHOG — by KullaiSec"
echo "----------------------------------------------------------"
