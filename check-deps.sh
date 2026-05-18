#!/usr/bin/env bash
# Dependency check script for Vikunja child-project-tasks feature
# Checks all required tools for development and testing on Debian

set -euo pipefail

PASS=0
FAIL=0
WARN=0

ok()   { echo "  ✅ $*"; PASS=$((PASS+1)); }
fail() { echo "  ❌ $*"; FAIL=$((FAIL+1)); }
warn() { echo "  ⚠️  $*"; WARN=$((WARN+1)); }

section() { echo; echo "=== $* ==="; }

# ─── Go ───────────────────────────────────────────────────────────────────────
section "Go"
REQUIRED_GO="1.25"
if command -v go &>/dev/null; then
    GO_VER=$(go version | awk '{print $3}' | sed 's/go//')
    ok "go $GO_VER found"
    # Simple major.minor comparison
    MAJOR=$(echo "$GO_VER" | cut -d. -f1)
    MINOR=$(echo "$GO_VER" | cut -d. -f2)
    REQ_MINOR=$(echo "$REQUIRED_GO" | cut -d. -f2)
    if [[ "$MAJOR" -lt 1 ]] || [[ "$MAJOR" -eq 1 && "$MINOR" -lt "$REQ_MINOR" ]]; then
        fail "Go >= $REQUIRED_GO required (found $GO_VER)"
    else
        ok "Go version $GO_VER meets requirement >= $REQUIRED_GO"
    fi
else
    fail "go not found — install from https://go.dev/dl/ or via devenv"
fi

# ─── Mage ─────────────────────────────────────────────────────────────────────
section "Mage (Go build tool)"
if command -v mage &>/dev/null; then
    ok "mage found at $(command -v mage)"
else
    fail "mage not found — install: go install github.com/magefile/mage@latest"
fi

# ─── golangci-lint ────────────────────────────────────────────────────────────
section "golangci-lint"
if command -v golangci-lint &>/dev/null; then
    LINT_VER=$(golangci-lint --version 2>&1 | head -1)
    ok "golangci-lint found: $LINT_VER"
else
    fail "golangci-lint not found — see https://golangci-lint.run/usage/install/"
fi

# ─── Node.js ──────────────────────────────────────────────────────────────────
section "Node.js (>= 24)"
if command -v node &>/dev/null; then
    NODE_VER=$(node --version | sed 's/v//')
    NODE_MAJOR=$(echo "$NODE_VER" | cut -d. -f1)
    ok "node v$NODE_VER found"
    if [[ "$NODE_MAJOR" -lt 24 ]]; then
        fail "Node.js >= 24 required (found v$NODE_VER) — use nvm or devenv"
    else
        ok "Node.js version meets requirement >= 24"
    fi
else
    fail "node not found — install Node.js >= 24 (https://nodejs.org or nvm)"
fi

# ─── pnpm ─────────────────────────────────────────────────────────────────────
section "pnpm (10.x)"
if command -v pnpm &>/dev/null; then
    PNPM_VER=$(pnpm --version)
    PNPM_MAJOR=$(echo "$PNPM_VER" | cut -d. -f1)
    ok "pnpm $PNPM_VER found"
    if [[ "$PNPM_MAJOR" -lt 10 ]]; then
        fail "pnpm 10.x required (found $PNPM_VER) — run: npm install -g pnpm@10"
    else
        ok "pnpm version meets requirement (10.x)"
    fi
else
    fail "pnpm not found — install: npm install -g pnpm@10"
fi

# ─── Git ──────────────────────────────────────────────────────────────────────
section "Git"
if command -v git &>/dev/null; then
    ok "git $(git --version | awk '{print $3}') found"
else
    fail "git not found — install: sudo apt-get install git"
fi

# ─── SQLite (used by test suite) ──────────────────────────────────────────────
section "SQLite (test database)"
if command -v sqlite3 &>/dev/null; then
    ok "sqlite3 $(sqlite3 --version | awk '{print $1}') found"
else
    warn "sqlite3 CLI not found — tests use SQLite but the Go driver is embedded; CLI is optional"
fi

# ─── gopter (Go property-based testing library) ───────────────────────────────
section "gopter (Go property-based testing)"
GOPTER_PKG="github.com/leanovate/gopter"
if go list "$GOPTER_PKG" &>/dev/null 2>&1; then
    ok "gopter found in Go module cache"
else
    # Check go.mod / go.sum
    if grep -q "leanovate/gopter" /home/dev/git/vikunja/go.mod 2>/dev/null || \
       grep -q "leanovate/gopter" /home/dev/git/vikunja/go.sum 2>/dev/null; then
        ok "gopter listed in go.mod/go.sum"
    else
        warn "gopter not in go.mod — property-based tests (tasks 1.2, 2.4, 2.5, etc.) require it"
        warn "Add with: go get github.com/leanovate/gopter"
    fi
fi

# ─── Frontend node_modules ────────────────────────────────────────────────────
section "Frontend dependencies (node_modules)"
if [[ -d /home/dev/git/vikunja/frontend/node_modules ]]; then
    ok "frontend/node_modules exists"
else
    warn "frontend/node_modules not found — run: cd frontend && pnpm install"
fi

# ─── Build sanity check ───────────────────────────────────────────────────────
section "Go module download check"
if go list ./... &>/dev/null 2>&1; then
    ok "Go modules resolve correctly"
else
    warn "Go module resolution had issues — run: go mod download"
fi

# ─── Summary ──────────────────────────────────────────────────────────────────
echo
echo "════════════════════════════════════════"
echo "  Results: $PASS passed, $WARN warnings, $FAIL failed"
echo "════════════════════════════════════════"

if [[ "$FAIL" -gt 0 ]]; then
    echo
    echo "❌ STOP: $FAIL required dependency/dependencies missing. Fix before proceeding."
    exit 1
elif [[ "$WARN" -gt 0 ]]; then
    echo
    echo "⚠️  All required dependencies present, but $WARN warning(s) noted above."
    exit 0
else
    echo
    echo "✅ All dependencies satisfied. Ready to continue implementation."
    exit 0
fi
