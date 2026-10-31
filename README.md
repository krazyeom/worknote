# Engineering Worknotes

기술 설계, 구현 내역, 아키텍처 결정 사항(ADR)을 기록하는 작업 노트 저장소입니다.

상세 목차와 문서는 [index.md](index.md) 또는 GitHub Pages에서 확인하실 수 있습니다.

---

## ⚡ 빠른 시작: 다른 프로젝트에서 AI 작업 일지 룰 적용하기

어떤 신규 프로젝트나 사내 저장소에서도 아래 명령어 한 줄로 **Claude, Codex, Antigravity, Gemini, Cursor** 지원 룰과 스킬을 즉시 마운트할 수 있습니다:

```bash
curl -fsSL https://raw.githubusercontent.com/krazyeom/worknote/main/scripts/setup-worknote.sh | bash
```

설치 후 AI에게 평어로 지시하면 자동으로 보안 검수를 거쳐 작업 일지를 생성합니다:
> *"오늘 작업한 내용을 worknote로 정리해서 커밋해줘."*

자세한 임포트 가이드는 [docs/05-universal-ai-rule-import-guide.md](docs/05-universal-ai-rule-import-guide.md)를 참고하십시오.

---

## 📚 최근 작업 내역
* **2026-10-31**: [aWord 영한 대조 학습 엔진 및 블로그 다국어 시스템 구축](notes/2026-10-31-aword-tts-shadowing-and-blog-i18n.md)
  * Gemini Flash 기반 1:1 문장 정합 번역 파이프라인
  * 24kHz Studio AI 음성 합성 및 0ms 프리페치
  * 실시간 배속(0.5x~2.0x) 및 3단계 루프 모드(S/A/Off)
  * Zero-Layout-Shift 인라인 하이라이터
  * 블로그 다국어(EN/KO) 실시간 동기화 스위처
