#!/usr/bin/env bash
#
# SwiftX Browser - GitHub yayinlama yardimcisi
#
# gh (GitHub CLI) GEREKTIRMEZ. Bir Personal Access Token ile calisir:
#   https://github.com/settings/tokens/new?scopes=repo,workflow  (scope: repo + workflow)
#   'workflow' scope'u .github/workflows dosyasini push edebilmek icin gereklidir.
#
# Kullanim:
#   GITHUB_TOKEN=ghp_xxxxxxxx ./setup.sh
#
# Ortam degiskenleri (opsiyonel):
#   GITHUB_TOKEN    GitHub Personal Access Token (zorunlu, gh yoksa)
#   GITHUB_USER     GitHub kullanici adi (verilmezse API'den alinir)
#   REPO_NAME       GitHub repo adi            (varsayilan: SwiftX)
#   VISIBILITY      public | private           (varsayilan: public)
#   TAG             Surum etiketi              (varsayilan: v0.3.0)
#   REMOTE          Git remote adi             (varsayilan: origin)
#   DEFAULT_BRANCH  Varsayilan dal             (varsayilan: main)
#   GIT_NAME        Commit yazari adi          (varsayilan: Stegizm)
#   GIT_EMAIL       Commit yazari e-postasi    (varsayilan: Stegizm@users.noreply.github.com)
#   FORCE_TAG       Ayni etiketi zorla guncelle (varsayilan: 0)
#
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

REPO_NAME="${REPO_NAME:-SwiftX-Rust}"
VISIBILITY="${VISIBILITY:-public}"
TAG="${TAG:-v0.3.0}"
REMOTE="${REMOTE:-origin}"
DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"
GIT_NAME="${GIT_NAME:-Stegizm}"
GIT_EMAIL="${GIT_EMAIL:-Stegizm@users.noreply.github.com}"
TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-}}"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31mHata:\033[0m %s\n' "$*" >&2; exit 1; }

# ── 0. On kosullar ──────────────────────────────────────────────────────────
command -v git >/dev/null 2>&1 || fail "git bulunamadi."
command -v curl >/dev/null 2>&1 || fail "curl bulunamadi."

# ── 1. Rust ─────────────────────────────────────────────────────────────────
if ! command -v cargo >/dev/null 2>&1 && [ -f "$HOME/.cargo/env" ]; then
  # shellcheck disable=SC1091
  . "$HOME/.cargo/env"
fi
if ! command -v cargo >/dev/null 2>&1; then
  info "Rust kurulu degil, rustup ile kuruluyor..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
  # shellcheck disable=SC1091
  . "$HOME/.cargo/env"
fi
ok "cargo: $(cargo --version)"

# ── 2. Derleme dogrulamasi ──────────────────────────────────────────────────
info "Release derlemesi aliniyor..."
( cd rust && cargo build --release )
ok "Derleme tamam."

# ── 3. Git deposu + commit ──────────────────────────────────────────────────
if [ ! -d .git ]; then
  info "Git deposu baslatiliyor..."
  git init >/dev/null
  git checkout -b "$DEFAULT_BRANCH" >/dev/null 2>&1 || true
fi

if [ -z "$(git config user.email || true)" ]; then
  git config user.email "$GIT_EMAIL"
fi
if [ -z "$(git config user.name || true)" ]; then
  git config user.name "$GIT_NAME"
fi

git add -A
if git diff --cached --quiet; then
  info "Commit edilecek degisiklik yok."
else
  git commit -m "SwiftX Browser $TAG - Rust portu" >/dev/null
  ok "Commit atildi."
fi

# ── 4a. Token ile yayinlama (gh gerekmez) ───────────────────────────────────
publish_with_token() {
  [ -n "$TOKEN" ] || fail "GITHUB_TOKEN bos."

  local api="https://api.github.com"
  local auth_hdr=(-H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github+json")

  if [ -z "${GITHUB_USER:-}" ]; then
    info "GitHub kullanici adi aliniyor..."
    local resp
    resp="$(curl -fsSL "${auth_hdr[@]}" "$api/user")" \
      || fail "Token dogrulanamadi (kullanici bilgisi alinamadi)."
    GITHUB_USER="$(printf '%s' "$resp" | grep -o '"login":[^,}]*' | head -1 | sed 's/.*"login":[[:space:]]*"//;s/"//')"
    [ -n "$GITHUB_USER" ] || fail "Kullanici adi cozumlenemedi."
  fi
  ok "GitHub kullanici: $GITHUB_USER"

  local private="false"
  [ "$VISIBILITY" = "private" ] && private="true"

  info "Depo olusturuluyor/kontrol ediliyor: $GITHUB_USER/$REPO_NAME"
  local code
  code="$(curl -s -o /tmp/swiftx-gh-resp.json -w '%{http_code}' \
      -X POST "${auth_hdr[@]}" \
      -d "{\"name\":\"$REPO_NAME\",\"private\":$private,\"description\":\"SwiftX Browser - Rust (tao + wry)\"}" \
      "$api/user/repos")"
  case "$code" in
    201) ok "Depo olusturuldu." ;;
    422) warn "Depo zaten var, mevcut depoya push edilecek." ;;
    *)   cat /tmp/swiftx-gh-resp.json >&2 2>/dev/null || true
         fail "Depo olusturulamadi (HTTP $code). Token 'repo' yetkisine sahip mi?" ;;
  esac

  # Temiz remote (token'siz)
  git remote remove "$REMOTE" >/dev/null 2>&1 || true
  git remote add "$REMOTE" "https://github.com/$GITHUB_USER/$REPO_NAME.git"

  # Token'i URL'de yalnizca push aninda kullan (config'te saklanmaz)
  local push_url="https://x-access-token:${TOKEN}@github.com/${GITHUB_USER}/${REPO_NAME}.git"

  info "Dal push ediliyor: $DEFAULT_BRANCH"
  git push "$push_url" "$DEFAULT_BRANCH:$DEFAULT_BRANCH"
  git config "branch.$DEFAULT_BRANCH.remote" "$REMOTE"
  git config "branch.$DEFAULT_BRANCH.merge" "refs/heads/$DEFAULT_BRANCH"
  ok "Dal gonderildi."

  if git rev-parse "$TAG" >/dev/null 2>&1; then
    if [ "${FORCE_TAG:-0}" = "1" ]; then
      git -c user.name="$GIT_NAME" -c user.email="$GIT_EMAIL" tag -f -a "$TAG" -m "SwiftX Browser $TAG"
      ok "Etiket guncellendi (force): $TAG"
    else
      warn "Etiket zaten var: $TAG (guncellemek icin FORCE_TAG=1 kullanin)"
    fi
  else
    git -c user.name="$GIT_NAME" -c user.email="$GIT_EMAIL" tag -a "$TAG" -m "SwiftX Browser $TAG"
    ok "Etiket olusturuldu: $TAG"
  fi
  info "Etiket push ediliyor..."
  if [ "${FORCE_TAG:-0}" = "1" ]; then
    git push --force "$push_url" "$TAG"
  else
    git push "$push_url" "$TAG"
  fi
  ok "Etiket gonderildi -> GitHub Actions release tetiklendi."

  REPO_URL="https://github.com/$GITHUB_USER/$REPO_NAME"
}

# ── 4b. gh ile yayinlama (token yoksa ve gh varsa) ──────────────────────────
publish_with_gh() {
  command -v gh >/dev/null 2>&1 || return 1
  gh auth status >/dev/null 2>&1 || return 1
  info "gh ile yayinlaniyor..."
  if ! git remote get-url "$REMOTE" >/dev/null 2>&1; then
    gh repo create "$REPO_NAME" "--$VISIBILITY" --source=. --remote="$REMOTE" --push
  else
    git push -u "$REMOTE" "$DEFAULT_BRANCH"
  fi
  if git rev-parse "$TAG" >/dev/null 2>&1; then
    if [ "${FORCE_TAG:-0}" = "1" ]; then
      git -c user.name="$GIT_NAME" -c user.email="$GIT_EMAIL" tag -f -a "$TAG" -m "SwiftX Browser $TAG"
    else
      warn "Etiket zaten var: $TAG (guncellemek icin FORCE_TAG=1 kullanin)"
    fi
  else
    git -c user.name="$GIT_NAME" -c user.email="$GIT_EMAIL" tag -a "$TAG" -m "SwiftX Browser $TAG"
  fi
  if [ "${FORCE_TAG:-0}" = "1" ]; then
    git push --force "$REMOTE" "$TAG"
  else
    git push "$REMOTE" "$TAG"
  fi
  REPO_URL="$(gh repo view --json url -q .url 2>/dev/null || true)"
}

REPO_URL=""
if [ -n "$TOKEN" ]; then
  publish_with_token
elif publish_with_gh; then
  :
else
  fail "GitHub token bulunamadi. Bir token olusturup soyle calistirin:
       https://github.com/settings/tokens/new?scopes=repo,workflow
       GITHUB_TOKEN=ghp_xxxxxxxx ./setup.sh"
fi

# ── Ozet ────────────────────────────────────────────────────────────────────
printf '\n'
ok "Yayin tamamlandi!"
[ -n "$REPO_URL" ] && info "Repo:     $REPO_URL"
[ -n "$REPO_URL" ] && info "Actions:  $REPO_URL/actions"
[ -n "$REPO_URL" ] && info "Releases: $REPO_URL/releases"
