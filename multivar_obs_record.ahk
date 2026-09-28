#Requires AutoHotkey v2.0
#SingleInstance Force

/*
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  다변수 미적분 자동 녹화 — 0강 ~ 41강 (총 42개)
  ★ 녹화 컴에서 실행 ★   배속 1.5배

  강의 한 개마다 OBS 녹화를 켜고 끕니다.
  → 강의별로 파일이 따로 저장되고, 강의 사이 30초는 녹화되지 않습니다.

  [실행 순서]
   1. OBS 실행 → 아래 KeyStart / KeyStop 과 똑같은 핫키를 지정
   2. 재생 컴: 강의를 열어 광고를 넘긴 뒤 영상 맨 앞에서 일시정지 해둔다
   3. 이 스크립트 실행 → Ctrl+Alt+S → 10초 카운트다운
   4. 카운트가 0 이 되는 순간 재생 컴에서 재생 + F9

  ※ Speed / BufferSec / SeqSec 는 재생 컴 스크립트와 반드시 같은 값이어야 합니다.

  [싱크 구조]  강의 1개당 두 컴퓨터가 도는 주기가 정확히 같습니다
   재생 컴 :  재생(1.5배속) + 대기 50초 + 키시퀀스 10초
   녹화 컴 :  재생 + 뒤여유 30초 + 녹화정지 30초
   → 둘 다 (재생시간 + 60)초.
   → 두 번째 강의부터는 재생 컴이 {RIGHT} 로 광고를 넘기는 바로 그 순간에
     녹화가 켜집니다. 앞여유가 0이라 OBS 인코더 뜨는 1~2초는 잘릴 수 있습니다.

  [이어서 볼 때]  아래 StartIndex 를 재생 컴과 똑같이 맞추세요 (1 = 0강)

  [단축키]  ※ OBS 핫키와 겹치지 않게 조합키만 씁니다
   Ctrl+Alt+S      시작 / 일시정지
   Ctrl+Alt+N      지금 바로 다음 단계로
   Ctrl+Alt+←/→    남은 시간 10초 당기기 / 미루기 (싱크 보정)
   Ctrl+Alt+Q      녹화 중지 후 종료
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
*/

; ══════════════════ 설정 ══════════════════
KeyStart   := "{Pause}"      ; OBS 녹화 시작 핫키 (단일키 권장. 조합키는 잘 씹힘)
KeyStop    := "{ScrollLock}" ; OBS 녹화 중지 핫키 (토글 하나만 쓰면 "" 로 비워두세요)

Speed      := 1.5      ; 배속 ─┐
BufferSec  := 50       ; 대기   ├─ 재생 컴 스크립트와 반드시 같은 값
SeqSec     := 10       ; 시퀀스 ┘ ★ 재생 컴의 {WAIT:6} 을 바꾸면 이 값도 같이 바꿀 것

StartDelay := 10       ; Ctrl+Alt+S 누르고 몇 초 뒤에 첫 녹화를 켤지 (카운트다운)
PreRoll    := 0        ; {RIGHT} 누르는 순간에 맞춰 녹화 시작 (앞여유 없음)
                       ;   OBS 인코더 뜨는 1~2초가 잘릴 수 있습니다.
                       ;   손실이 싫으면 2 로 올리세요 (대신 정지시간이 28초로 줄어듦)
PostRoll   := 30       ; 강의 끝나고 30초 더 녹화
                       ; → 강의 사이 녹화 정지 = 50 + 10 - 0 - 30 = 30초

StartIndex := 9        ; 목록 몇 번째부터 시작할지 (1 = 0강 OT) — 재생 컴과 동일하게
RecDir     := "D:\수학\다변수미적분학  White"       ; OBS 녹화 저장 폴더. 채우면 파일명을 강의명으로 자동 변경
                       ; 예) RecDir := "D:\인강녹화\다변수 미적분"

; ══════════ 강의 목록 [강번호, 제목, 원본 분] ══════════
lectures := [
    [ 0, "다변수 미적분 OT",                      10],
    [ 1, "[1-1] 이변수 함수의 극한 및 연속",           85],
    [ 2, "[1-2] 편도함수의 정의",                  91],
    [ 3, "[2-1] 고계 편도함수 및 동차 함수",           95],
    [ 4, "[2-2] 파동 방정식 및 전미분",              78],
    [ 5, "[3-1] 합성함수 및 음함수 미분법",            62],
    [ 6, "[3-2] 경도 및 방향도함수",                98],
    [ 7, "[4-1] T급수 및 M급수 / 1단원 유형별 플러스",   88],
    [ 8, "[4-2] 1단원 유형별 플러스 및 단단",          86],
    [ 9, "[5-1] 벡터함수의 공간도형의 방정식 및 경도",      84],
    [10, "[5-2] 공간도형의 방정식 및 곡률",            81],
    [11, "[6-1] 곡률원 및 T, N, B",             99],
    [12, "[6-2] 접촉평면 및 열률 / 2단원 유형별 플러스",   63],
    [13, "[7-1] 2단원 유형별 플러스 및 단단",          80],
    [14, "[7-2] 극대, 극소 및 최대, 최소",           76],
    [15, "[8-1] 이변수함수의 최대 및 최소 / 라그랑주",     90],
    [16, "[8-2] 멀티 라그랑주 및 3단원 유형별 플러스",     85],
    [17, "[9-1] 3단원 유형별 플러스 및 단단",         101],
    [18, "[9-2] 이차곡면",                     101],
    [19, "[9-3] 이중적분",                      57],
    [20, "[10-1] 적분순서 변경 및 변수변환 (1)",       95],
    [21, "[10-2] 적분순서 변경 및 변수변환 (2)",       71],
    [22, "[11-1] 극좌표를 이용한 이중적분",            86],
    [23, "[11-2] 이중적분 및 4단원 유형별 플러스 (1)",   48],
    [24, "[12-1] 4단원 유형별 플러스 (2)",          90],
    [25, "[12-2] 4단원 유형별 플러스 (3) 및 단단",     81],
    [26, "[13-1] 4단원별 단단",                  76],
    [27, "[13-2] 이중적분을 이용한 부피",             77],
    [28, "[14-1] 이중적분을 이용한 부피 및 곡면적",      102],
    [29, "[14-2] 곡면적 및 삼중적분",               70],
    [30, "[15-1] 원주좌표계 및 구면좌표계",            90],
    [31, "[15-2] 구면좌표계 및 중심좌표",             88],
    [32, "[16-1] 중심좌표 및 5단원 유형별 플러스",      113],
    [33, "[16-2] 5단원 유형별 플러스",             107],
    [34, "[16-3] 토러스 및 5단원 단단",             85],
    [35, "[17-1] 벡터함수",                     72],
    [36, "[17-2] 스칼라 함수의 선적분 및 벡터함수의 선적분",  92],
    [37, "[18-1] 벡터함수의 선적분",               108],
    [38, "[18-2] 특이한 벡터장 및 스칼라 선적분",        61],
    [39, "[19-1] 벡터함수의 면적분 (유량)",           85],
    [40, "[19-2] 스톡스 정리",                  101],
    [41, "[20-1] 6단원 유형별 플러스",              97]
]

; ══════════════════ 초기화 ══════════════════
idx       := StartIndex
remain    := 0
phase     := "idle"     ; "count" = 시작 카운트다운 / "rec" = 녹화 중 / "idle" = 녹화 정지
state     := "pause"
recording := false
started   := false      ; 첫 강의를 시작했는지 (일시정지 후 재개와 구분)

MyGui := Gui("+AlwaysOnTop", "OBS 자동 녹화 · 다변수 미적분")
MyGui.MarginX := 14, MyGui.MarginY := 12
MyGui.SetFont("s10", "맑은 고딕")
txtLec := MyGui.AddText("w510 h66", "")
MyGui.SetFont("s14 bold")
txtPhase := MyGui.AddText("w510 Center", "")
MyGui.SetFont("s22 bold")
txtTime := MyGui.AddText("w510 h40 Center", "00:00:00")
MyGui.SetFont("s9 norm")
txtSub := MyGui.AddText("w510 Center cGray", "")
txtAll := MyGui.AddText("w510 Center cGray", "")
MyGui.AddText("w510 cGray", "Ctrl+Alt+S 시작/정지   N 다음   ←→ 10초 보정   Q 종료")
MyGui.OnEvent("Close", (*) => SafeExit())
MyGui.Show("w538")

UpdateUI()
SetTimer Tick, 1000
return

; ══════════════════ 단축키 ══════════════════
^!s:: {
    global state, phase, remain, started, StartDelay
    if (state = "run") {
        state := "pause"
    } else {
        state := "run"
        if (!started) {
            started := true
            phase   := "count"      ; 10초 카운트다운 시작
            remain  := StartDelay
        }
    }
    UpdateUI()
}

^!n:: {
    global phase, idx
    if (phase = "count")
        BeginLecture(idx)
    else if (phase = "rec")
        EndRecPhase()
    else
        BeginLecture(idx + 1)
}

^!Left::ShiftTime(-10)
^!Right::ShiftTime(10)
^!q::SafeExit()

; ══════════════════ 기능 ══════════════════
PlaySec(i) {                ; i번째 강의의 실제 재생시간(초)
    global lectures, Speed
    return Round(lectures[i][3] * 60 / Speed)
}

GapSec() {                  ; 강의 사이 녹화가 꺼져 있는 시간(초)
    global BufferSec, SeqSec, PreRoll, PostRoll
    g := BufferSec + SeqSec - PreRoll - PostRoll
    return (g < 5) ? 5 : g
}

ShiftTime(sec) {
    global remain
    remain := Max(remain + sec, 1)
    UpdateUI()
}

Tick() {
    global state, remain, phase, idx
    if (state != "run")
        return
    remain--
    if (remain <= 0) {
        if (phase = "count")
            BeginLecture(idx)       ; 카운트다운 끝 → 첫 녹화 시작
        else if (phase = "rec")
            EndRecPhase()
        else
            BeginLecture(idx + 1)
        return
    }
    UpdateUI()
}

; 강의 시작 → 녹화 ON, (앞여유 + 재생시간 + 뒤여유) 만큼 녹화
BeginLecture(i) {
    global idx, lectures, phase, remain, PreRoll, PostRoll, started
    if (i > lectures.Length) {
        Finish()
        return
    }
    idx := i
    started := true
    RecStart()
    phase := "rec"
    remain := PreRoll + PlaySec(idx) + PostRoll
    UpdateUI()
}

; 강의 종료 → 녹화 OFF, 다음 강의 시작 전까지 대기
EndRecPhase() {
    global phase, remain, idx, lectures, RecDir
    RecStop()
    if (RecDir != "")
        SetTimer(RenameNewest.Bind(lectures[idx][1] "강 " lectures[idx][2]), -8000)
    if (idx >= lectures.Length) {
        Finish()
        return
    }
    phase := "idle"
    remain := GapSec()
    UpdateUI()
}

RecStart() {
    global KeyStart, recording
    if (recording)
        return
    SendToOBS(KeyStart)
    recording := true
}

RecStop() {
    global KeyStart, KeyStop, recording
    if (!recording)
        return
    SendToOBS(KeyStop = "" ? KeyStart : KeyStop)
    recording := false
}

; OBS 는 키를 순간적으로 보내면 놓칠 때가 있어서 80ms 동안 누르고 있게 함
SendToOBS(k) {
    SetKeyDelay 80, 80
    SendEvent(k)
    Sleep 300
}

Finish() {
    global state, phase, remain
    state := "pause"
    phase := "idle"
    remain := 0
    UpdateUI()
    MsgBox("마지막 41강 [20-1] 6단원 유형별 플러스 까지 녹화가 끝났습니다.", "완료", "Iconi")
}

SafeExit() {
    RecStop()
    Sleep 500
    ExitApp()
}

; 녹화 끝난 뒤 폴더에서 가장 최근 파일을 강의명으로 변경
RenameNewest(title) {
    global RecDir
    newest := "", newestT := ""
    Loop Files, RecDir "\*.*" {
        if (newestT = "" || A_LoopFileTimeModified > newestT) {
            newestT := A_LoopFileTimeModified
            newest  := A_LoopFilePath
        }
    }
    if (newest = "")
        return
    SplitPath(newest, , &dir, &ext)
    try FileMove(newest, dir "\" Sanitize(title) "." ext)
}

Sanitize(s) {
    for ch in ["\", "/", ":", "*", "?", '"', "<", ">", "|"]
        s := StrReplace(s, ch, "-")
    return Trim(s)
}

RemainTotal() {         ; 지금부터 41강 녹화 종료까지 남은 총 시간(초)
    global idx, remain, lectures, phase, started, PreRoll, PostRoll
    gap := GapSec()
    if (!started || phase = "count")
        t := remain + PreRoll + PlaySec(idx) + PostRoll + ((idx < lectures.Length) ? gap : 0)
    else if (phase = "rec")
        t := remain + ((idx < lectures.Length) ? gap : 0)
    else
        t := remain
    i := idx + 1
    while (i <= lectures.Length) {
        t += PreRoll + PlaySec(i) + PostRoll
        if (i < lectures.Length)
            t += gap
        i++
    }
    return t
}

UpdateUI() {
    global lectures, idx, remain, state, phase, recording, started, Speed
    global txtLec, txtPhase, txtTime, txtSub, txtAll
    lec := lectures[idx]
    txtLec.Value := lec[1] "강   (" idx " / " lectures.Length " · 원본 " lec[3] "분 · " Speed "배속 → " FmtTime(PlaySec(idx)) ")`n" lec[2]

    if (state != "run" && !started) {
        txtPhase.Value := "◇ 대기 — Ctrl+Alt+S 로 시작"
    } else if (state != "run") {
        extra := recording ? " (녹화는 계속 중)" : ""
        txtPhase.Value := "⏸ 일시정지" extra
    } else if (phase = "count") {
        txtPhase.Value := "▶ " remain "초 후 녹화 시작 — 카운트 0 에 재생 + F9"
    } else if (phase = "rec") {
        txtPhase.Value := "● 녹화 중"
    } else {
        txtPhase.Value := "○ 녹화 정지 — 다음 강의 대기"
    }

    txtTime.Value := FmtTime(remain)
    if (!started)
        txtSub.Value := "Ctrl+Alt+S 를 누르면 10초 카운트다운이 시작됩니다"
    else if (phase = "count")
        txtSub.Value := "재생 컴: 광고 넘긴 상태로 일시정지 → 카운트 0 에 재생 + F9"
    else
        txtSub.Value := FormatTime(DateAdd(A_Now, remain, "Seconds"), "HH:mm:ss") " 에 " ((phase = "rec") ? "녹화 중지" : "녹화 시작")

    tot := RemainTotal()
    txtAll.Value := "남은 강의 전체 " FmtTime(tot) "  →  쉬지 않고 돌리면 " FormatTime(DateAdd(A_Now, tot, "Seconds"), "MM/dd HH:mm") " 종료"
}

FmtTime(s) {
    if (s < 0)
        s := 0
    return Format("{:02}:{:02}:{:02}", s // 3600, Mod(s, 3600) // 60, Mod(s, 60))
}
