# 걱정마요

`걱정마요`는 감정을 분석하거나 평가하기보다, 손으로 두드리고·띄우고·지워보는 Android-first Flutter 앱입니다.

## 모드

### 고민 노크 · Mind Check

선택한 감정을 화면 어디서든 톡톡 누르며 다루는 모드입니다.

- 감정 추가, 검색, 이름 변경, 삭제
- 감정별 탭 기록을 기기에 로컬 저장
- 탭이 빨라질수록 중앙 원과 감정명이 반응
- 시간/일/주/월 단위 로그 그래프 제공

### 고민 버블 · Troubley-Bubbley

고민을 텍스트로 적어 버블에 담아 흘려보내는 모드입니다.

- 텍스트 입력 후 버블 생성
- 버블이 위로 떠오르다 사라짐
- 긴 문장은 여러 버블로 나누어 표시
- 입력한 고민은 서버에 저장하지 않음

### 고민 싹싹밀기 · trouble truncate

고민을 화면에 흩뿌리고 손가락으로 문질러 지워가는 청소 게임형 모드입니다.

- 상단 `+` 메뉴에서 고민을 쉼표(`,`)로 구분해 한 번에 입력
- 하나만 입력해도 화면을 채울 만큼 여러 고민 조각 생성
- 손가락 브러시, 은은한 glow, 지워지는 텍스트 효과
- 여러 구역을 문질러야 고민 조각이 사라짐
- 완료 시 랜덤 문구와 밝아지는 화면 연출

## 디자인 방향

- 파스텔 핑크·하늘색·크림 계열
- 최소한의 버튼과 부드러운 피드백
- 기록보다 감정 배출과 촉각적 몰입에 초점

## 주요 자산

```text
assets/images/logo/app_logo.png
assets/images/logo/mind_check_logo.png
assets/images/logo/troubley_bubbley_logo.png
assets/images/logo/trouble_truncate_logo.png
```

## 기술 스택

- Flutter
- Android 우선
- SQLite: 고민 노크의 감정/탭 로그 로컬 저장
- 서버 저장 및 계정 기능 없음

## 로컬 실행

```powershell
flutter pub get
flutter run
```

## Debug APK 빌드

```powershell
flutter build apk --debug
```

결과 파일:

```text
build/app/outputs/flutter-apk/app-debug.apk
```