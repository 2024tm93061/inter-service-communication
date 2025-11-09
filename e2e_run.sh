#!/usr/bin/env bash
set -euo pipefail

# Local endpoints (port-forward these first as shown above)
ACC=https://urban-journey-4jp49459rp5q274pr-8000.app.github.dev
CUST=https://urban-journey-4jp49459rp5q274pr-8001.app.github.dev
NOTIFY=https://urban-journey-4jp49459rp5q274pr-8003.app.github.dev
TX=https://urban-journey-4jp49459rp5q274pr-8002.app.github.dev

echo "1) Create customers rakesh and jitesh"
ram_resp=$(curl -s -X POST "$CUST/customers/" -H "Content-Type: application/json" -d '{"name":"rakesh","email":"rakesh@gmail.com@edfred.com","phone":"+15550001","kyc_status":"VERIFIED"}')

shyam_resp=$(curl -s -X POST "$CUST/customers/" -H "Content-Type: application/json" -d '{"name":"jitesh","email":"jitesh@gmail.com","phone":"+15550002","kyc_status":"VERIFIED"}')


shyam_id =
ram_id = 

echo
echo "2) Create accounts for Ram and Shyam (initial balances: Ram=1000, Shyam=100)"
ram_acc=$(curl -s -X POST "$ACC/accounts" -H "Content-Type: application/json" -d "{\"customer_id\": $ram_id, \"account_number\": \"RAM-001\", \"initial_balance\": 1000}")
ram_account_id=$(python - <<PY
import sys,json
print(json.loads(sys.stdin.read())['account_id'])
PY
<<<"$ram_acc")
echo "  -> Ram account_id=$ram_account_id"

shyam_acc=$(curl -s -X POST "$ACC/accounts" -H "Content-Type: application/json" -d "{\"customer_id\": $shyam_id, \"account_number\": \"SHYAM-001\", \"initial_balance\": 100}")
shyam_account_id=$(python - <<PY
import sys,json
print(json.loads(sys.stdin.read())['account_id'])
PY
<<<"$shyam_acc")
echo "  -> Shyam account_id=$shyam_account_id"

echo
echo "3) Notify both users of account creation (calls Notification service)"
curl -s -X POST "$NOTIFY/notify" -H "Content-Type: application/json" -d "{\"email\": \"ram@example.com\", \"message\": \"Hello Ram — your account $ram_account_id was created with balance 1000\"}" | jq -C || true
curl -s -X POST "$NOTIFY/notify" -H "Content-Type: application/json" -d "{\"email\": \"shyam@example.com\", \"message\": \"Hello Shyam — your account $shyam_account_id was created with balance 100\"}" | jq -C || true

echo
echo "4) Check initial balances via Account service"
curl -s "$ACC/accounts/$ram_account_id" | jq -C
curl -s "$ACC/accounts/$shyam_account_id" | jq -C

echo
echo "5) Transfer 250 from Ram -> Shyam using Account service transfer endpoint"
transfer_resp=$(curl -s -X POST "$ACC/transfer" -H "Content-Type: application/json" -d "{\"from_account\": $ram_account_id, \"to_account\": $shyam_account_id, \"amount\": 250}")
echo "  -> transfer response:"
echo "$transfer_resp" | jq -C || true

echo
echo "6) Fetch final balances and notify both parties"
ram_final=$(curl -s "$ACC/accounts/$ram_account_id")
shyam_final=$(curl -s "$ACC/accounts/$shyam_account_id")
echo "Ram final:"
echo "$ram_final" | jq -C
echo "Shyam final:"
echo "$shyam_final" | jq -C

ram_bal=$(python - <<PY
import sys,json
print(json.loads(sys.stdin.read())['balance'])
PY
<<<"$ram_final")
shyam_bal=$(python - <<PY
import sys,json
print(json.loads(sys.stdin.read())['balance'])
PY
<<<"$shyam_final")

echo
echo "E2E script finished. Check Notification service logs to see masked recipients and messages."