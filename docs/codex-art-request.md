# 삐약푸시 타일셋 아트 의뢰 (codex용)

삐약푸시는 병아리가 알을 밀어 둥지에 넣는 소코반 퍼즐이다. 아래 12장의 PNG를
생성해 달라. 완성본은 `C:\workAndroid\PiyakPush\assets\images\tiles\`에 파일명
그대로 넣고 앱을 다시 빌드하면 자동으로 사용된다 (없으면 코드가 그린 임시
타일로 동작하므로 일부만 넣어도 된다).

## 스타일 가이드 (기존 에셋과 통일)

- 진갈색(#5D4037) 굵은 외곽선 + 파스텔 채움 — `C:\workAndroid\PiyakAssets\chick\chick_idle.png`,
  `C:\workAndroid\PiyakAssets\words\word_egg.png`와 같은 스타일
- 512×512 PNG, 배경 투명, 도형이 캔버스를 거의 꽉 채우게 (여백 5% 이내)
- 타일은 정면 평면(2D 탑다운 보드게임 말판 느낌, 원근 없음)
- 귀엽게: 모서리 둥글게, 필요하면 볼터치·광택 한 방울

## 목록

| 파일명 | 내용 |
|---|---|
| tile_grass.png | 밝은 연두 잔디 타일. 둥근 사각형, 잔디 결 두어 개 |
| tile_wall.png | 갈색 나무 울타리 블록 (통나무 느낌 가로줄 2개) |
| tile_nest.png | 지푸라기 둥지 (가운데 움푹, 도넛형) |
| tile_ice.png | 하늘색 얼음 타일, 광택 사선 2개 |
| tile_portal_purple.png | 보라 테두리의 굴(어두운 구멍) |
| tile_portal_orange.png | 주황 테두리의 굴(어두운 구멍) |
| tile_button_pink.png | 분홍 둥근 단추(눌리는 버튼), 잔디 위에 놓인 느낌 |
| tile_door_pink.png | 분홍 자물쇠 무늬가 있는 울타리 문(닫힘) |
| tile_button_blue.png | 하늘색 둥근 단추 |
| tile_door_blue.png | 하늘색 자물쇠 무늬 울타리 문(닫힘) |
| tile_cracked.png | 잔디 타일에 금이 간 모양 (갈라진 선 3~4개) |
| logo.png | 가로형 타이틀 로고 1024×512: "삐약푸시" 글자 + 병아리 얼굴 장식 |

## 확인 방법

파일을 넣은 뒤:

```powershell
cd C:\workAndroid\PiyakPush
$env:Path = "C:\flutter\bin;$env:Path"; $env:PUB_CACHE = "C:\flutter\.pub-cache"; $env:GRADLE_USER_HOME = "C:\workAndroid\gradle-user-ascii"
flutter build apk --release
```

게임 보드에 그림 타일이, 타이틀에 로고가 나오면 성공.
