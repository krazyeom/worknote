# 문서 03: 실시간 오디오 제어 및 다단계 루프 메커니즘

본 문서는 실시간 배속 변경 시 브라우저의 리셋 동작을 방어하는 기법, 3단계 오디오 루프 제어 로직, 레이아웃 진동을 배제한 인라인 단어 하이라이터 설계 명세를 설명합니다.

---

## 1. 실시간 배속 제어 및 리셋 방어

### A. 브라우저 스펙상의 리셋 문제
W3C HTMLMediaElement 표준에 따르면 `audio.src`에 새로운 URL이 할당되면 브라우저 내부 미디어 파이프라인이 재초기화되면서 `playbackRate` 속성이 기본값인 `1.0`으로 자동 복귀합니다. 이로 인해 사용자가 `1.5x` 배속을 지정해 두었더라도 다음 문장으로 넘어갈 때마다 `1.0x`로 강제 초기화되는 현상이 발생했습니다.

### B. 방어 알고리즘 구현
`src` 교체 직후 `defaultPlaybackRate`와 `playbackRate`를 동일한 순서로 강제 재주입하도록 구현했습니다. 재생 중에 사용자가 배속을 바꿀 때도 처음부터 다시 재생하지 않고 즉시 적용합니다.

```typescript
// 1. 새 문장 로드 시 배속 영속화
audio.src = nextAudioUrl;
audio.defaultPlaybackRate = playbackRateRef.current;
audio.playbackRate = playbackRateRef.current;

// 2. 재생 중 배속 변경 처리 (즉각 반영)
const handleRateChange = (newRate: number) => {
  setPlaybackRate(newRate);
  playbackRateRef.current = newRate;
  if (audioRef.current) {
    audioRef.current.playbackRate = newRate;
  }
};
```

지원 배속: `0.5x`, `0.75x`, `0.9x`, `1.0x`, `1.25x`, `1.5x`, `1.75x`, `2.0x` (총 8단계)

---

## 2. 3단계 루프 모드 (Loop Mode)

사용자의 섀도잉 학습 목적(단일 문장 집중 훈련 vs 전체 본문 연속 청취)에 맞추어 3단계 순환 토글 방식을 채택했습니다.

### A. 모드 정의 및 UI 표시
* **`none` (반복 끄기)**:
  * 회색 기본 반복 아이콘.
  * 마지막 문장 발화가 끝나면 재생을 마칩니다.
* **`sentence` (문장 반복)**:
  * 주황색 강조 스타일, 아이콘 우상단에 **`S`** 배지 표기.
  * 현재 문장 발화가 끝나면 180ms 뒤 해당 문장을 다시 재생합니다.
* **`all` (전체 문장 반복)**:
  * 파란색 강조 스타일, 아이콘 우상단에 **`A`** 배지 표기.
  * 마지막 문장 발화가 끝나면 240ms 뒤 1번 문장(index 0)으로 이동하여 처음부터 순환 재생합니다.

### B. 종료 이벤트 핸들러 로직

```typescript
audio.onended = () => {
  if (!isPlayingRef.current) return;
  clearPlaybackTimer();

  const currentLoop = loopModeRef.current;

  if (currentLoop === 'sentence') {
    // 1. 단일 문장 무한 반복
    playbackTimerRef.current = setTimeout(() => {
      if (isPlayingRef.current) playSentence(index);
    }, 180);
  } else if (index + 1 < currentList.length) {
    // 2. 다음 문장으로 진행
    playbackTimerRef.current = setTimeout(() => {
      if (isPlayingRef.current) playSentence(index + 1);
    }, 140);
  } else if (currentLoop === 'all' && currentList.length > 0) {
    // 3. 전체 반복 모드: 첫 문장으로 순환
    playbackTimerRef.current = setTimeout(() => {
      if (isPlayingRef.current) playSentence(0);
    }, 240);
  } else {
    // 4. 재생 완료 및 상태 정리
    stopTTS();
  }
};
```

---

## 3. Zero-Layout-Shift 인라인 단어 하이라이터

### A. 기존 레이아웃 진동(Flicker) 원인
1. 활성 단어에 `font-bold`를 적용하면 글자 너비가 5~10% 증가하여 이후 단어들이 밀려나고, 문장 끝 줄바꿈이 지속해서 떨리는 문제(Layout Shift)가 발생했습니다.
2. 진행률 표시줄이 나타났다 사라질 때마다 카드 세로 높이가 달라지는 흔들림이 있었습니다.

### B. 해결 구조
* **폰트 크기 및 두께 완전 고정**:
  단어가 강조되어도 폰트 두께(`font-normal`)와 여백을 변경하지 않고, 배경색과 글자색만 부드럽게 전환하는 인라인 `<mark>` 방식을 적용했습니다.
* **발화 중심점(`targetMid`) 스냅**:
  현재 발화 진행률(`currentTime / duration`)을 글자 인덱스로 매핑할 때, 단어의 중심점(`(start + end) / 2`)과 일치하는 토큰 1개만 정확하게 켜지도록 하여 공백 경계에서의 깜빡임을 제거했습니다.
* **진행 바 절대 위치 고정**:
  한국어 번역 카드의 진행 표시줄을 바닥선(`absolute bottom-0`)에 부착하여 높이 변화를 원천 차단했습니다.
