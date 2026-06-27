#!/usr/bin/env bash
# Automated API smoke tests for the Filhos parents/professors auth flows.
# Usage: bash scripts/test_auth_api.sh
# Requires the local backend running at http://localhost:8000.
#
# Tests:
#   1. Parents  registration OTP send  -> "error":false
#   2. Teachers registration OTP send  -> "error":false
#   3. Parents  login (email+password) -> access_token
#   4. Teachers login (email+password) -> access_token
#   5. Config API                      -> "config"
#
# NOTE: registration OTP-send requires a FREE email, so tests 1/2 use fresh
# unique aliases (appaabar+...@gmail.com) that deliver to the same real inbox.
# Login tests use the existing seeded accounts (password: Ahmed@123).

BASE="${BASE:-http://localhost:8000/api/v1}"
PARENT_EMAIL="${PARENT_EMAIL:-an8778508@gmail.com}"
TEACHER_EMAIL="${TEACHER_EMAIL:-appaabar@gmail.com}"
PASSWORD="${PASSWORD:-Ahmed@123}"
pass=0; fail=0

check() {
  local name="$1" expect="$2" resp="$3"
  if echo "$resp" | grep -q "$expect"; then
    echo "✅ PASS — $name"; pass=$((pass+1))
  else
    echo "❌ FAIL — $name   (expected to contain: $expect)"; fail=$((fail+1))
  fi
  echo "   → $resp"; echo
}

echo "============================================================"
echo " FILHOS AUTH TEST SUITE   ($BASE)"
echo "============================================================"; echo

FRESH_P="appaabar+p${RANDOM}@gmail.com"
FRESH_T="appaabar+t${RANDOM}@gmail.com"

r=$(curl -s -X POST "$BASE/auth/email-otp/send" -H "Content-Type: application/json" \
  -d "{\"email\":\"$FRESH_P\",\"purpose\":\"register\",\"role\":\"parent\"}" --max-time 60)
check "TEST 1 — Parents Registration OTP send ($FRESH_P)" '"error":false' "$r"

r=$(curl -s -X POST "$BASE/auth/email-otp/send" -H "Content-Type: application/json" \
  -d "{\"email\":\"$FRESH_T\",\"purpose\":\"register\",\"role\":\"teacher\"}" --max-time 60)
check "TEST 2 — Teachers Registration OTP send ($FRESH_T)" '"error":false' "$r"

r=$(curl -s -X POST "$BASE/auth/login-with-email" -H "Content-Type: application/json" \
  -d "{\"email\":\"$PARENT_EMAIL\",\"password\":\"$PASSWORD\",\"role\":\"parent\"}" --max-time 60)
check "TEST 3 — Parents Login (email+password)" 'access_token' "$r"

r=$(curl -s -X POST "$BASE/auth/login-with-email" -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEACHER_EMAIL\",\"password\":\"$PASSWORD\",\"role\":\"teacher\"}" --max-time 60)
check "TEST 4 — Teachers Login (email+password)" 'access_token' "$r"

r=$(curl -s "$BASE/config" --max-time 60 | head -c 120)
check "TEST 5 — Config API" '"config"' "$r"

echo "============================================================"
echo " RESULT: $pass passed, $fail failed"
echo "============================================================"
[ "$fail" -eq 0 ]
