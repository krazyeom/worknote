---
layout: default
title: "문서 02: 오디오 엔진 비교 및 iOS Safari 환경 분석"
---

# 문서 02: 오디오 엔진 비교 및 iOS Safari 환경 분석

본 문서는 브라우저 내장 Web Speech API와 클라우드 24kHz Studio AI 오디오 엔진의 기술적 특성을 비교하고, iOS Safari의 미디어 정책 제약을 극복한 설계 방식을 정리합니다.

---

## 1. 오디오 엔진 특성 비교

| 평가 항목 | Google Studio 24kHz AI 성우 | iOS Web Speech API (`SpeechSynthesis`) |
| :--- | :--- | :--- |
| **샘플 레이트** | **24kHz (고해상도)** | 8kHz ~ 16kHz (저해상도 압축) |
| **음성 자연스러움** | 원어민 호흡, 억양, 문맥 휴지기 완벽 재현 | 단조롭고 기계적인 로봇 합성음 |
| **Siri 음성 접근성** | 해당 없음 (Kore, Puck 등 전문 AI 성우) | **WebKit 보안 정책상 접근 불가** (Samantha 등 기본 음성만 노출) |
| **플랫폼 일관성** | iOS, Android, macOS, Windows 동일 음질 | 브라우저 및 OS 버전에 따라 음질 편차 극심 |
| **무음 모드 스피커 출력** | 측면 무음 스위치를 켜면 스피커 출력 차단됨 | 시스템 접근성 채널로 동작하여 무음 모드 무시 |

### 기술적 결정 배경 (ADR)
iOS Safari의 `window.speechSynthesis`는 Apple의 내부 정책상 뉴럴 엔진 기반의 고품질 Siri 음성이나 향상된 음성을 웹 컨텍스트에 노출하지 않습니다. 그 결과 10여 년 전의 8kHz 구형 기계식 음성(`Samantha Compact`)만 노출되어 정밀한 섀도잉 학습에 적합하지 않았습니다.  
이에 따라 로컬 Web Speech 엔진 옵션을 배제하고, 모든 기기에서 스튜디오 품질을 보장하는 **Google 24kHz Studio AI 성우**(`gemini-audio.ts`)로 단일화했습니다.

---

## 2. iOS Safari WebKit 미디어 제약과 해결책

### A. 사용자 인터랙션 보호 정책 (Autoplay Restriction)
* **문제점**:
  iOS Safari는 사용자의 직접적인 터치 이벤트(`click`, `touchend`) 컨텍스트 외부에서 생성된 `new Audio()`의 자동 재생을 엄격히 차단하며 `NotAllowedError` 예외를 발생시킵니다.
  문장이 끝날 때마다 새로운 `Audio` 인스턴스를 동적으로 생성하면, 비동기 `ended` 콜백에서 호출된 `audio.play()`가 즉시 차단되어 연속 재생이 중단됩니다.
* **해결책 (단일 Audio 인스턴스 영구 유지)**:
  모달 컴포넌트 생명주기 전체에 걸쳐 단 1개의 `HTMLAudioElement`(`audioRef.current`)만 생성합니다. 문장이 전환될 때는 오디오 객체를 새로 만들지 않고 기존 객체의 `src` 속성만 교체하여 재생합니다. 최초 재생 시 획득한 사용자 터치 승인 세션이 유지되어 끊김 없는 연속 재생이 가능합니다.

```typescript
// 단일 오디오 인스턴스 보장 패턴
if (!audioRef.current && typeof window !== 'undefined') {
  const audio = new Audio();
  audio.preload = 'auto';
  audio.crossOrigin = 'anonymous';
  audioRef.current = audio;
}

const audio = audioRef.current;
audio.src = audioUrl;
audio.defaultPlaybackRate = playbackRateRef.current;
audio.playbackRate = playbackRateRef.current;
audio.play();
```

---

### B. 페이지 전환 시 백그라운드 오디오 누수 차단
* **문제점**:
  사용자가 음성 재생 중에 모달을 닫지 않고 브라우저 뒤로가기(`popstate`)를 누르거나 다른 페이지로 이동할 경우, 컴포넌트는 언마운트되었으나 오디오 태스크가 백그라운드에서 계속 재생되어 다른 페이지 음성과 겹쳐 나오는 문제가 발생했습니다.
* **해결책 (전역 오디오 레지스트리)**:
  브라우저 전역 객체(`window.__aword_active_audio`)에 현재 재생 중인 단일 미디어 인스턴스를 등록했습니다.

```typescript
// 전역 레지스트리를 통한 즉시 차단
export function stopGlobalAudio() {
  if (typeof window !== 'undefined' && window.__aword_active_audio) {
    try {
      window.__aword_active_audio.pause();
      window.__aword_active_audio.currentTime = 0;
      window.__aword_active_audio.src = '';
    } catch (_) {}
    window.__aword_active_audio = null;
  }
}
```

* `pagehide`, `beforeunload`, 라우트 변경, 컴포넌트 정리 시점에 `stopGlobalAudio()`와 `clearPlaybackTimer()`를 강제 실행하여 백그라운드 누수를 차단했습니다.

---

### C. Web Speech 폴백 완전 소거 및 키 라운드로빈 쿨다운
* **중간 음성 변조 문제 원인**:
  네트워크 지연이나 일시적 Gemini API 429 Rate Limit 발생 시, 프론트엔드에 남아있던 예외 처리기가 브라우저 Web Speech로 자동 폴백되면서 캐시된 24kHz 음성 이후 기계식 합성음(`Samantha Compact`)으로 음색이 갑자기 바뀌는 문제가 있었습니다.
* **해결책**:
  1. 기계식 Web Speech 폴백 경로를 완전히 소거하고, 에러 시 잠시 대기 후 원본 음원 자동 재시도하도록 단일화했습니다.
  2. `gemini-audio.ts`에 키 라운드로빈 및 429 쿨다운(45초) 회피를 탑재하여 특정 키 쿼터 소진 시 정상 키로 즉각 우회하도록 개선했습니다.
