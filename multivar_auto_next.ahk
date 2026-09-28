#Requires AutoHotkey v2.0
#SingleInstance Force
SetTitleMatchMode 2

/*
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  다변수 미적분 자동 넘김 — 0강 ~ 41강 (총 42개)
  ★ 재생(강의 보는) 컴에서 실행 ★   배속 1.5배 / 강의 후 대기 50초

  강의 재생시간이 끝나면 50초 뒤 아래 순서로 키를 보냅니다
  {CTRL}W {WAIT:1} {TAB} {WAIT:1} {ENTER} {WAIT:1} {ENTER} {WAIT:6} {ENTER} {WAIT:1} {RIGHT}
  → 마지막 {RIGHT} 가 광고(약 5초) 스킵. 이 순간이 강의 내용 시작점이고,
    녹화 컴도 정확히 이 순간에 녹화를 켭니다.

  [사용법 — 넘김만 할 때]
   1. 브라우저에서 볼 강의를 열고 광고를 넘긴 뒤 1.5배속을 맞춘다
   2. 이 스크립트를 실행하고, 재생과 동시에 F9

  [사용법 — 녹화도 같이 할 때]
   1. 재생 컴: 강의를 열어 광고를 넘긴 뒤 영상 맨 앞에서 일시정지 해둔다
   2. 녹화 컴: OBS 스크립트 실행 → Ctrl+Alt+S → 10초 카운트다운이 뜬다
   3. 카운트가 0 이 되는 순간 재생 + F9
   ※ Speed / BufferSec 는 녹화 컴 스크립트와 반드시 같은 값이어야 합니다.

  [이어서 볼 때]  42강짜리라 며칠에 나눠 보게 됩니다
   아래 StartIndex 를 바꾸세요. 1 = 0강, 2 = 1강, ... 42 = 41강
   또는 실행 후 Ctrl+Alt+↓ 로 키 안 보내고 목록만 원하는 강의까지 이동

  [단축키]
   F9            시작 / 일시정지
   F10           지금 바로 다음 강의로 넘기기 (키시퀀스 전송)
   F11 / F12     이전 강의로 되돌리기 / 현재 강의 타이머 리셋
   Ctrl+Alt+↑↓   키 안 보내고 목록만 이동
   Ctrl+Alt+←→   남은 시간 10초 당기기 / 미루기 (싱크 보정)
   Ctrl+Alt+Q    종료
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
*/

; ══════════════════ 설정 ══════════════════
Speed      := 1.5    ; 배속 — 녹화 컴과 반드시 동일
BufferSec  := 50     ; 강의 종료 후 다음 시퀀스까지 대기(초)
                     ;   녹화 컴이 "30초 더 녹화 + 30초 정지"가 되도록 맞춘 값
                     ;   (50 + 시퀀스 10초 = 60초 = 30 + 30)
StartIndex := 1      ; 목록 몇 번째부터 시작할지 (1 = 0강 OT)
WaitScale  := 1.0    ; 키 사이 대기 배율. 페이지가 전체적으로 느리면 1.5~2.0
TargetWin  := ""     ; 키를 보낼 창. 예) "ahk_exe chrome.exe" / 비우면 활성창
SendOnLast := false  ; 마지막 강의(41강)가 끝났을 때도 다음 강의를 열지 여부

; 키시퀀스 총 대기시간(초) = 1 + 1 + 1 + 6 + 1 = 10
; ★ 이 숫자를 녹화 컴 스크립트의 SeqSec 에 똑같이 넣어야 합니다 (지금 설정이면 10)
SeqSec := Round(10 * WaitScale)

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
idx    := StartIndex
remain := 0
state  := "pause"

MyGui := Gui("+AlwaysOnTop", "다변수 미적분 자동 넘김")
MyGui.MarginX := 14, MyGui.MarginY := 12
MyGui.SetFont("s10", "맑은 고딕")
txtLec := MyGui.AddText("w510 h66", "")
MyGui.SetFont("s22 bold")
txtTime := MyGui.AddText("w510 h40 Center", "00:00:00")
MyGui.SetFont("s9 norm")
txtSub := MyGui.AddText("w510 Center cGray", "")
txtAll := MyGui.AddText("w510 Center cGray", "")
MyGui.AddText("w510 cGray", "F9 시작/정지  F10 다음  F11 이전  F12 리셋  Ctrl+Alt+↑↓ 목록이동  ←→ 10초  Q 종료")
MyGui.OnEvent("Close", (*) => ExitApp())
MyGui.Show("w538")

LoadLecture(StartIndex)
SetTimer Tick, 1000
return

; ══════════════════ 단축키 ══════════════════
F9:: {
    global state
    state := (state = "run") ? "pause" : "run"
    UpdateUI()
}

F10::NextLecture()

F11:: {
    global idx
    if (idx > 1)
        LoadLecture(idx - 1)
}

F12:: {
    global idx
    LoadLecture(idx)
}

^!Up:: {
    global idx
    if (idx > 1)
        LoadLecture(idx - 1)
}

^!Down:: {
    global idx, lectures
    if (idx < lectures.Length)
        LoadLecture(idx + 1)
}

^!Left::ShiftTime(-10)
^!Right::ShiftTime(10)
^!q::ExitApp()

; ══════════════════ 기능 ══════════════════
PlaySec(i) {                ; i번째 강의의 실제 재생시간(초)
    global lectures, Speed
    return Round(lectures[i][3] * 60 / Speed)
}

LoadLecture(i) {
    global idx, remain, BufferSec
    idx := i
    remain := PlaySec(idx) + BufferSec
    UpdateUI()
}

ShiftTime(sec) {
    global remain
    remain := Max(remain + sec, 1)
    UpdateUI()
}

Tick() {
    global state, remain
    if (state != "run")
        return
    remain--
    if (remain <= 0) {
        NextLecture()
        return
    }
    UpdateUI()
}

NextLecture() {
    global idx, remain, lectures, state, SendOnLast
    last := (idx >= lectures.Length)
    if (!last || SendOnLast)
        SendSequence()
    if (last) {
        state := "pause"
        remain := 0
        UpdateUI()
        MsgBox("마지막 41강 [20-1] 6단원 유형별 플러스 까지 끝났습니다. 수고하셨습니다!", "완료", "Iconi")
        return
    }
    LoadLecture(idx + 1)
}

; ────────────────────────────────────────────────────────────
;  실제로 보내는 키. 순서를 바꾸려면 여기만 고치면 됩니다.
;  {CTRL}W{WAIT:1}{TAB}{WAIT:1}{ENTER}{WAIT:1}{ENTER}{WAIT:6}{ENTER}{WAIT:1}{RIGHT}
;  ※ W() 값을 바꾸면 SeqSec 과 녹화 컴 SeqSec 도 같이 바꿔야 합니다.
; ────────────────────────────────────────────────────────────
SendSequence() {
    global TargetWin
    if (TargetWin != "") {
        try {
            WinActivate(TargetWin)
            WinWaitActive(TargetWin, , 3)
        }
        Sleep 500
    }
    Send("^w")          ; {CTRL}W  - 탭 닫기
    W(1)
    Send("{Tab}")       ; {TAB}
    W(1)
    Send("{Enter}")     ; {ENTER}
    W(1)
    Send("{Enter}")     ; {ENTER}
    W(6)                ; {WAIT:6}  - 페이지·플레이어 로딩 대기
    Send("{Enter}")     ; {ENTER}   - 영상 재생 시작 (광고 0:00)
    W(1)
    Send("{Right}")     ; {RIGHT}   - 광고 스킵 ← 녹화 컴이 이 순간에 녹화 ON
}

W(sec) {                ; 초 단위 대기 (WaitScale 배율 적용)
    global WaitScale
    Sleep Round(sec * 1000 * WaitScale)
}

RemainTotal() {         ; 지금부터 41강까지 남은 총 시간(초)
    global idx, remain, lectures, BufferSec, SeqSec
    t := remain
    i := idx + 1
    while (i <= lectures.Length) {
        t += SeqSec + PlaySec(i) + BufferSec
        i++
    }
    return t
}

UpdateUI() {
    global lectures, idx, remain, state, Speed, SeqSec
    global txtLec, txtTime, txtSub, txtAll
    lec := lectures[idx]
    mark := (state = "run") ? "▶ 진행 중" : "⏸ 정지됨"
    txtLec.Value := mark "   " lec[1] "강  (" idx " / " lectures.Length " · 원본 " lec[3] "분 · " Speed "배속 → " FmtTime(PlaySec(idx)) ")`n" lec[2]
    txtTime.Value := FmtTime(remain)
    txtSub.Value := FormatTime(DateAdd(A_Now, remain, "Seconds"), "HH:mm:ss") " 에 다음 강의로 넘어감   ·   녹화 컴 SeqSec = " SeqSec
    tot := RemainTotal()
    txtAll.Value := "남은 강의 전체 " FmtTime(tot) "  →  쉬지 않고 돌리면 " FormatTime(DateAdd(A_Now, tot, "Seconds"), "MM/dd HH:mm") " 종료"
}

FmtTime(s) {
    if (s < 0)
        s := 0
    return Format("{:02}:{:02}:{:02}", s // 3600, Mod(s, 3600) // 60, Mod(s, 60))
}
