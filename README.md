# 걱정하지마요

불안하거나 머릿속이 복잡할 때, 감정을 “기록/분석”하기보다 손으로 다루며 흘려보내는 Android-first Flutter 앱입니다.

현재 앱은 두 가지 모드를 제공합니다.

## 1. 마인드 체커

특정 감정을 선택하고 화면을 톡톡 누르면서 감정의 강도와 빈도를 몸으로 풀어내는 모드입니다.

- 감정 추가, 검색, 선택, 이름 변경, 삭제
- 선택한 감정별 탭 기록 저장
- 화면 어디든 탭하면 카운트 기록
- 탭이 많아질수록 중앙 원과 감정명이 커지고 반응
- 감정별 로그 화면 제공
- 시간/일/주/월 단위 빈도 그래프 확인

## 2. Troubley Bubbley

고민을 텍스트로 적고 버블에 담아 띄워 보내는 모드입니다.

- 텍스트 입력 기반 고민 버블 생성
- 고민 텍스트는 서버 저장 없이 앱 안에서 버블처럼 사라짐
- 버블은 위로 떠오르다가 터지는 느낌으로 제거
- 긴 문장은 여러 버블로 나누어 표현
- 버블 안 글자 크기는 문장 길이에 따라 자동 조절

## 디자인 방향

- 파스텔톤
- 가벼운 핑크/하늘색 계열
- 부드러운 카드형 UI
- 감정 관리보다는 감정 배출에 가까운 경험

## 주요 자산

앱 로고와 모드별 로고는 아래 경로에 있습니다.

```text
assets/images/logo/app_logo.png
assets/images/logo/mind_check_logo.png
assets/images/logo/troubley_bubbley_logo.png
```

## 기술 스택

- Flutter
- Android 우선
- SQLite: 감정/탭 로그 로컬 저장
- 서버 저장 없음

## 로컬 실행

Flutter SDK가 설치되어 있어야 합니다.

```powershell
flutter pub get
flutter run
```

## APK 빌드

```powershell
flutter build apk --debug
```

빌드 결과:

```text
build/app/outputs/flutter-apk/app-debug.apk
```
