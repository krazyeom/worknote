# Universal Worknote Rule (업무 일지 및 기술 문서 공통 규칙)

본 규칙은 **Claude, Codex, Antigravity, Gemini, Cursor** 등 어떤 LLM AI 환경에서도 업무 일지와 기술 문서를 작성할 때 일관된 품질과 보안을 보장하기 위한 범용 지침입니다.

---

## 1. 핵심 행동 원칙
* **보안 최우선 (Security Zero-Leak)**: API Key, 비밀번호, 사설 IP, PII(개인식별정보)는 1글자도 노출하지 않습니다.
* **한국어 휴머나이징**: 번역투(`~에 대해`, `~를 통해`, `~에 있어`, `~되어진다`)와 기계적 관용구(`결론적으로`, `시사하는 바가 크다`)를 배제하고 담백한 기술 격식체로 서술합니다.
* **재현 가능한 기술 기록**: 나중에 다시 보거나 다른 엔지니어가 읽어도 맥락을 이해할 수 있도록 배경, 구현 로직, 트러블슈팅, 아키텍처 결정 사항(ADR)을 체계적으로 구조화합니다.

---

## 2. 각 AI 도구별 임포트 방법
* **Antigravity CLI**: 프로젝트 루트의 `.agents/rules/` 또는 `GEMINI.md`로 심볼릭 링크/복사
* **Anthropic Claude Code**: 프로젝트 루트의 `CLAUDE.md`로 심볼릭 링크/복사
* **OpenAI Codex / ChatGPT Workspace**: 프로젝트 루트의 `AGENTS.md`로 배치
* **Cursor IDE**: `.cursorrules` 또는 `.cursor/rules/worknote.mdc`로 배치
* **Google Gemini CLI**: `~/.gemini/GEMINI.md` 또는 프로젝트 루트 `GEMINI.md`로 배치

상세 임포트 및 서브모듈 연결 방법은 [docs/05-universal-ai-rule-import-guide.md](../docs/05-universal-ai-rule-import-guide.md)를 참조하십시오.
