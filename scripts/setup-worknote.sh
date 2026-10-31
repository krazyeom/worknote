#!/usr/bin/env bash
# ==============================================================================
# setup-worknote.sh: Universal Worknote Rule & Skill Installer
# Claude, Codex, Antigravity, Gemini, Cursor 등 모든 AI 환경을 위한 원클릭 설정기
# ==============================================================================

set -e

WORKNOTE_REPO="https://github.com/krazyeom/worknote.git"
TARGET_DIR="${1:-.worknote}"

echo "🚀 [Worknote Setup] 작업 일지 룰 및 스킬 설정을 시작합니다..."

# 1. worknote 서브모듈 또는 클론
if [ -d "$TARGET_DIR" ]; then
  echo "ℹ️  기존 $TARGET_DIR 디렉터리가 이미 존재합니다. 최신 버전을 풀(pull)합니다."
  (cd "$TARGET_DIR" && git pull origin main 2>/dev/null || true)
else
  if [ -d ".git" ]; then
    echo "📦 Git 프로젝트 감지: 서브모듈로 추가합니다."
    git submodule add "$WORKNOTE_REPO" "$TARGET_DIR" 2>/dev/null || git clone "$WORKNOTE_REPO" "$TARGET_DIR"
  else
    echo "📥 Git 저장소 외 환경: 단순 클론으로 내려받습니다."
    git clone "$WORKNOTE_REPO" "$TARGET_DIR"
  fi
fi

# 2. 모든 LLM 공통 규칙 심볼릭 링크 연결
echo "🔗 각 LLM 환경별 규칙 심볼릭 링크를 생성합니다..."

# Antigravity & OpenAI Codex 표준
ln -sf "$TARGET_DIR/rules/AGENTS.md" AGENTS.md

# Anthropic Claude Code 표준
ln -sf "$TARGET_DIR/rules/AGENTS.md" CLAUDE.md

# Google Gemini / Antigravity CLI 표준
ln -sf "$TARGET_DIR/rules/AGENTS.md" GEMINI.md

# Cursor IDE 표준
ln -sf "$TARGET_DIR/rules/AGENTS.md" .cursorrules

# 3. Antigravity / Claude 스킬 폴더 마운트
mkdir -p .agents/skills
ln -sfn "../../$TARGET_DIR/skills/daily-worknote" .agents/skills/daily-worknote

echo "================================================================================"
echo "✅ [설치 완료] 모든 LLM에서 바로 사용할 수 있도록 설정되었습니다!"
echo "   - AGENTS.md     -> Codex / Antigravity 공용"
echo "   - CLAUDE.md     -> Anthropic Claude Code"
echo "   - GEMINI.md     -> Google Gemini"
echo "   - .cursorrules  -> Cursor IDE"
echo "   - .agents/skills/daily-worknote -> Antigravity Skill"
echo "================================================================================"
echo "💡 사용 예시: AI에게 '오늘 작업한 내용을 worknote로 정리해줘'라고 요청하세요."
