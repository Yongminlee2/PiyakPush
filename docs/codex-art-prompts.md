# codex 병렬 실행용 프롬프트 4개

창 4개에 하나씩 붙여넣어 동시에 돌리면 된다. 전부 끝나면 맨 아래 "적용" 참고.

---

## 창 1 — 지형 타일 4장

```
이미지 생성 작업이야. 소코반 퍼즐 게임 "삐약푸시"의 보드 타일 4장을 만들어서
C:\workAndroid\PiyakPush\assets\images\tiles\ 에 정확히 아래 파일명으로 저장해줘.

스타일 (반드시 통일):
- C:\workAndroid\PiyakAssets\chick\chick_idle.png 와
  C:\workAndroid\PiyakAssets\words\word_egg.png 를 먼저 보고 같은 화풍으로.
- 진갈색(#5D4037) 굵은 외곽선 + 파스텔 채움, 카와이 플랫 스타일
- 512×512 PNG, 배경 투명, 도형이 캔버스를 거의 꽉 채우게(여백 5% 이내)
- 정면 평면(2D 탑다운 보드게임 말판 느낌, 원근 없음), 모서리 둥글게

1. tile_grass.png — 밝은 연두색 잔디 타일. 둥근 사각형 한 장, 잔디 결 두어 개
2. tile_wall.png — 갈색 나무 울타리 블록. 통나무 느낌 가로줄 2개
3. tile_nest.png — 지푸라기 둥지. 가운데가 움푹한 도넛형, 지푸라기 결
4. tile_ice.png — 하늘색 얼음 타일. 광택 사선 2개, 반짝이는 느낌
```

## 창 2 — 굴·균열 타일 3장

```
이미지 생성 작업이야. 소코반 퍼즐 게임 "삐약푸시"의 보드 타일 3장을 만들어서
C:\workAndroid\PiyakPush\assets\images\tiles\ 에 정확히 아래 파일명으로 저장해줘.

스타일 (반드시 통일):
- C:\workAndroid\PiyakAssets\chick\chick_idle.png 와
  C:\workAndroid\PiyakAssets\words\word_egg.png 를 먼저 보고 같은 화풍으로.
- 진갈색(#5D4037) 굵은 외곽선 + 파스텔 채움, 카와이 플랫 스타일
- 512×512 PNG, 배경 투명, 도형이 캔버스를 거의 꽉 채우게(여백 5% 이내)
- 정면 평면(2D 탑다운 보드게임 말판 느낌, 원근 없음), 모서리 둥글게

1. tile_portal_purple.png — 땅에 뚫린 동그란 굴. 어두운 구멍 + 보라색 둘레 테두리
2. tile_portal_orange.png — 같은 굴인데 둘레 테두리만 주황색
3. tile_cracked.png — 연두 잔디 타일에 금이 간 모양. 갈라진 선 3~4개가 또렷하게
```

## 창 3 — 단추·문 타일 4장

```
이미지 생성 작업이야. 소코반 퍼즐 게임 "삐약푸시"의 보드 타일 4장을 만들어서
C:\workAndroid\PiyakPush\assets\images\tiles\ 에 정확히 아래 파일명으로 저장해줘.

스타일 (반드시 통일):
- C:\workAndroid\PiyakAssets\chick\chick_idle.png 와
  C:\workAndroid\PiyakAssets\words\word_egg.png 를 먼저 보고 같은 화풍으로.
- 진갈색(#5D4037) 굵은 외곽선 + 파스텔 채움, 카와이 플랫 스타일
- 512×512 PNG, 배경 투명, 도형이 캔버스를 거의 꽉 채우게(여백 5% 이내)
- 정면 평면(2D 탑다운 보드게임 말판 느낌, 원근 없음), 모서리 둥글게

1. tile_button_pink.png — 분홍색 크고 둥근 단추(누르는 버튼). 살짝 볼록한 느낌의 광택
2. tile_door_pink.png — 닫힌 나무 울타리 문. 가운데에 분홍색 자물쇠 장식
3. tile_button_blue.png — 하늘색 크고 둥근 단추. 분홍 단추와 같은 모양, 색만 다르게
4. tile_door_blue.png — 닫힌 나무 울타리 문. 가운데에 하늘색 자물쇠 장식
```

## 창 4 — 타이틀 로고 1장

```
이미지 생성 작업이야. 소코반 퍼즐 게임 "삐약푸시"의 타이틀 로고를 만들어서
C:\workAndroid\PiyakPush\assets\images\tiles\logo.png 로 저장해줘.

스타일:
- C:\workAndroid\PiyakAssets\chick\chick_cheer.png 를 먼저 보고 같은 화풍으로.
- 1024×512 가로형 PNG, 배경 투명
- "삐약푸시" 네 글자를 통통하고 둥근 손글씨 느낌으로, 노란색 채움 +
  진갈색(#5D4037) 굵은 외곽선
- 글자 옆이나 위에 병아리 얼굴(볼터치 있는 노란 병아리) 장식 하나
- 글자가 또렷하게 읽혀야 한다 — 장식이 글자를 가리지 않게
```

---

## 적용 (전부 끝난 뒤)

```powershell
cd C:\workAndroid\PiyakPush
$env:Path = "C:\flutter\bin;$env:Path"; $env:PUB_CACHE = "C:\flutter\.pub-cache"; $env:GRADLE_USER_HOME = "C:\workAndroid\gradle-user-ascii"
flutter build apk --release
C:\workAndroid\android-sdk-ascii\platform-tools\adb.exe install -r build\app\outputs\flutter-apk\app-release.apk
```

일부만 완성돼도 괜찮다 — 파일이 있는 타일만 그림으로 바뀌고 나머지는 기존 그대로 나온다.
