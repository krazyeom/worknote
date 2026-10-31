---
layout: default
title: "문서 07: 영화 대본 TTS 오디오 파이프라인 및 침묵 탐지 슬라이싱 아키텍처"
---

# 문서 07: 영화 대본 TTS 오디오 파이프라인 및 침묵 탐지 슬라이싱 아키텍처

본 문서는 `subtitle-to-speech` 시스템에서 수천 개에 달하는 영화 대사를 효율적으로 AI 음성으로 합성하고, 브라우저 재생 환경에서 지연 시간과 클릭 노이즈를 0으로 수렴시키기 위해 적용된 오디오 엔지니어링 및 분할 알고리즘을 상세히 기술합니다.

---

## 1. 아키텍처 배경 및 문제 정의

대본 기반의 영어 섀도잉 플레이어는 일반 오디오 스트리밍과 다른 고유한 기술적 요구 사항을 갖습니다:
1. **극도의 낮은 지연 시간**: 사용자가 대사를 클릭하거나 문장이 넘어갈 때 즉시(0~50ms 이내) 음성이 출력되어야 몰입이 유지됩니다.
2. **엄격한 API 할당량(Rate Limit)**: Gemini Flash TTS API는 분당/일당 요청 수(RPM/TPM) 제한이 있으므로, 영화 1편(1,000~2,000대사)을 문장별로 개별 호출하면 즉시 429 에러에 도달합니다.
3. **오디오 끝단 팝 노이즈(DC Offset Pop)**: AI TTS 모델이 토큰 끝에서 오디오를 반환할 때 진폭이 0이 아닌 상태에서 급격히 끊겨, 브라우저/스피커에서 "찌익" 하는 파열음이 발생하는 고질적 문제가 있었습니다.

---

## 2. 오디오 디클릭(De-click) 및 RIFF WAV 인코딩

### A. 신호 처리 원리 및 파형 분석
* Gemini 3.8 Flash TTS 모델은 **16-bit 24,000Hz Mono Linear PCM** 형식의 무압축 오디오를 base64 문자열로 반환합니다.
* 샘플 검사 결과, 마지막 오디오 샘플이 **진폭 24,937** (16비트 최대값 32,767의 76%)에서 아무런 감쇄 없이 절단되어 있었습니다.
* 이 상태로 WAV 헤더를 씌워 재생하면 스피커의 물리적 진동판이 +24,937 위치에서 0으로 순간 이동하면서 강력한 스파이크 파열음(Click/Pop)을 유발합니다.

### B. 2단계 스무딩 알고리즘
```typescript
// 1. 디클릭: 시작 10ms 페이드인, 끝 80ms 쿼드라틱 감쇄 페이드아웃
const fadeInSamples = Math.floor(sampleRate * 0.01);  // 240 samples
const fadeOutSamples = Math.floor(sampleRate * 0.08); // 1,920 samples

for (let i = 0; i < fadeOutSamples; i++) {
  const factor = (fadeOutSamples - i) / fadeOutSamples;
  const smoothFactor = Math.pow(factor, 1.5); // 비선형 부드러운 감쇄
  const sampleIndex = numSamples - fadeOutSamples + i;
  const sample = pcmCopy.readInt16LE(sampleIndex * 2);
  pcmCopy.writeInt16LE(Math.round(sample * smoothFactor), sampleIndex * 2);
}

// 2. 브라우저/사운드카드 디코더 안전을 위한 60ms 완전 무음(Zero-padding) 추가
const silenceSamples = Math.floor(sampleRate * 0.06); // 1,440 samples (2,880 bytes)
const silenceBuffer = Buffer.alloc(silenceSamples * 2, 0);
const smoothedPcm = Buffer.concat([pcmCopy, silenceBuffer]);
```

이 처리를 거친 후 파일의 마지막 30개 샘플은 완전히 `0, 0, 0...`으로 수렴하며, 어떠한 하드웨어 스피커에서도 팝 노이즈가 100% 발생하지 않습니다.

---

## 3. 대용량 배치 호출 및 침묵 기반 슬라이서 (Audio Slicer)

### A. 대량 텍스트 묶음 생성
* 씬/챕터 단위로 남성 화자 대사들과 여성 화자 대사들을 분류합니다.
* 각각 최대 15개 대사(약 1,500자)를 문장 마침표와 줄바꿈(`.\n\n`)으로 결합하여 Gemini API에 단 1번 호출합니다.
* 모델은 문장 간 구두점을 인지하여 약 300~500ms의 자연스러운 휴지기(Pause)를 두고 연속된 롱 오디오 트랙을 생성합니다.

### B. 침묵(Silence) 윈도우 탐색 알고리즘
1. **글자 수 가중치 기반 초기 경계 추정**:
   * 각 대사의 글자 수 $L_i$에 비례하여 전체 PCM 샘플 수 $S_{total}$ 중 예상 경계점 $C_i = \frac{\sum_{k=1}^i L_k}{\sum L} \times S_{total}$을 계산합니다.
2. **국소 윈도우 RMS 에너지 탐색**:
   * 각 예상점 $C_i$ 주변 $\pm 1.5$초(36,000 샘플) 구간을 10ms(240 샘플) 윈도우로 스캔하며 평균 절대 진폭(Energy)을 측정합니다.
   * 에너지가 최솟값을 기록하는 지점을 실제 대사 간 무음 분할점(Split Point)으로 확정합니다.
3. **분할 및 개별 디스크 캐시 저장**:
   * 잘라낸 각 PCM 조각을 개별 WAV 파일로 인코딩하여 `data/audio_cache/audio_${hash}.wav`에 즉각 저장합니다.
   * **효과**: 단 1회의 API 호출로 15개의 개별 대사가 각각 독립된 캐시 파일로 디스크에 구워집니다.

---

## 4. 브라우저 재생 엔진: 단일 인스턴스 재사용 및 소프트 뮤트

WebKit 및 Blink 엔진에서 `new Audio()`를 매번 생성하고 `audio.src = ''`로 버퍼를 플러시할 때 드라이버 충돌로 찌익 소리가 나는 현상을 원천 방어하기 위해 다음 패턴을 준수합니다:

```typescript
// 1. 단일 인스턴스 영구 유지
if (!audioRef.current) {
  audioRef.current = new Audio();
}
const audio = audioRef.current;
audio.pause();
audio.volume = 1.0;
audio.src = audioUrl;
audio.currentTime = 0;

// 2. 대사 종료 80ms 전 소프트 볼륨 감쇄
audio.ontimeupdate = () => {
  const remaining = audio.duration - audio.currentTime;
  if (remaining < 0.08) {
    audio.volume = Math.max(0, remaining / 0.08); // 선형 페이드아웃
  }
};
```

---

## 5. 관리자 자막 수정 제어 및 실시간 캐싱 모니터링

### A. 관리자(ADMIN) 권한 기반 자막 제어
* **보안 환경 변수**: `.env`의 `ADMIN_ID` 및 `ADMIN_PASSWORD`를 통해 인증을 수행하며, HMAC-SHA256 기반 암호화 세션 쿠키(`subtitle_session`, 7일 유효, HttpOnly)를 발급합니다.
* **API 및 UI 보안**: 일반 사용자의 자막 임의 수정을 막기 위해 클라이언트 UI 및 `POST /api/movies` 백엔드 엔드포인트 모두에서 세션 검증을 수행합니다.

### B. 실시간 캐싱 진행도(%) 모니터링
* **진행률 게이지**: 메인 히어로 영역과 영화 카드에 전체 대사 대비 캐시된 대사 비율(`%`)과 프로그레스 바를 노출합니다.
* **반응형 폴링**: 백그라운드 캐싱 작업 실행 시 2.5초 간격으로 진행률을 자동 폴링하여, 페이지 새로고침 없이도 실시간 진행 상태가 시각적으로 업데이트됩니다.
