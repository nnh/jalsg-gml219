# 臨床試験SAS解析 - Claude Code 利用ナレッジ

作成日: 2026-05-05  
概要: JALSG-GML219 を通じて得た知見。次回 AML・血液腫瘍系試験に流用可能なノウハウ。

---

## 1. 開発環境セットアップ

### 1.1 RTK（トークン節約ツール）のインストール（Windows）

RTK（Rust Token Killer）はコマンド出力をフィルタリングしトークン消費を 60〜90% 削減するプロキシ。

```powershell
# GitHub Releases から Windows バイナリを取得
$url  = "https://github.com/rtk-ai/rtk/releases/latest/download/rtk-x86_64-pc-windows-msvc.zip"
$dest = "$env:LOCALAPPDATA\rtk"
Invoke-WebRequest -Uri $url -OutFile "$env:TEMP\rtk.zip"
Expand-Archive "$env:TEMP\rtk.zip" -DestinationPath $dest -Force

# ユーザー PATH に追加
$p = [System.Environment]::GetEnvironmentVariable("PATH","User")
[System.Environment]::SetEnvironmentVariable("PATH","$p;$dest","User")

# Claude Code に初期化
rtk init      # プロジェクト CLAUDE.md に追記
rtk init -g   # グローバルフック登録（要 settings.json 手動追記）
```

`~/.claude/settings.json` に追加:
```json
"hooks": {
  "PreToolUse": [{"matcher": "Bash",
    "hooks": [{"type": "command", "command": "rtk hook claude"}]}]
}
```

### 1.2 SAS バッチ実行

```powershell
$sas = "C:\Program Files\SASHome\SASFoundation\9.4\sas.exe"
& $sas -sysin "path\to\program.sas" -log "path\to\program.log" -nosplash -nologo
```

---

## 2. ファイル管理・文字コード

### 2.1 SAS ファイルは Shift-JIS（CP932）で読み書き

Claude Code の `Edit` ツールは UTF-8 で書き出すため **SAS ファイルへの使用禁止**。  
PowerShell のみ使用すること。

```powershell
$enc = [System.Text.Encoding]::GetEncoding(932)

# 読み込み
$content = [System.IO.File]::ReadAllText($path, $enc)

# 書き出し
[System.IO.File]::WriteAllText($path, $content, $enc)
```

### 2.2 PowerShell here-string の注意点

**必ずシングルクォート `@'...'@` を使う。**  
ダブルクォート `@"..."@` は SAS フォーマット指定子（`$200.` 等）を PowerShell 変数として展開し空文字に置換する。

```powershell
# NG: $200. が消えて length c1 . になる
$body = @"
length c1 $200. c2-c5 $30.;
"@

# OK
$body = @'
length c1 $200. c2-c5 $30.;
'@
```

可変値を埋め込む場合は `-f` 演算子を使う:
```powershell
$body = ('proc tabulate data={0};' -f $dsname)
```

### 2.3 CRLF の統一

PowerShell here-string は LF のみ。既存ファイルが CRLF の場合は置換後に正規化する。

```powershell
$content = $content -replace "`r?`n", "`r`n"
```

### 2.4 .gitignore 推奨設定（SAS プロジェクト）

```
/input          # 生データ（機密）
/output         # 生成 RTF
/log            # SAS ログ
*.sas7bdat
*.xlsx
*.csv
*.log
*.lst
```

---

## 3. SAS プログラム共通パターン

### 3.1 working_dir マクロ（自動パス解決）

`program/` フォルダ直下のプログラムでプロジェクトルートを自動取得するマクロ。

```sas
%macro working_dir;
    %local _fullpath _path;
    %let _fullpath = ;
    %if %length(%sysfunc(getoption(sysin))) = 0 %then
        %let _fullpath = %sysget(sas_execfilepath);
    %else
        %let _fullpath = %sysfunc(getoption(sysin));
    %let _path = %substr(&_fullpath., 1, %length(&_fullpath.)
                       - %length(%scan(&_fullpath.,-1,'\'))
                       - %length(%scan(&_fullpath.,-2,'\'))
                       - 2 );
    &_path.
%mend working_dir;

%let _wk_path = %working_dir;
```

**注意**: `%scan` の区切り文字は **シングルクォート `'\'`** で囲むこと。  
バッククォート `` `\` `` にするとパスが壊れる（SAS がエスケープ文字として解釈）。

### 3.2 CSVtoSASDS 設計パターン

SDTM ドメイン CSV から解析用データセットを構築するプログラムの推奨構成:

```
§1  ライブラリ・マクロ定義
§2  基本情報（DM: 性別・年齢・登録日）
§3  適格性フラグ（FAS/PPS/SAF）
§4  疾患情報（DS: 診断・中止）
§5  治療（EC/EX: コース別投与）
§6〜§13  検査・評価（LB/RS/AE/CE 等）
§14  後治療（PR/FA/SC/CM）
§15  統合（tmpall への merge）
§16  派生変数計算（エンドポイント）
§17  最終データセット出力
```

### 3.3 AE テーブルマクロパターン

コース別 × グレード別 AE 頻度表の実装パターン:

```sas
%macro ae_row(num, name);
  data ae&num;
    length c1 $200. c2-c6 $30.;
    retain g1-g5 0;
    set tmp_pop end=eof;
    if _gae&num&_cycl_ = 1 then g1 + 1;
    if _gae&num&_cycl_ = 2 then g2 + 1;
    if _gae&num&_cycl_ = 3 then g3 + 1;
    if _gae&num&_cycl_ = 4 then g4 + 1;
    if _gae&num&_cycl_ = 5 then g5 + 1;
    if eof then do;
      any = g1 + g2 + g3 + g4 + g5;
      /* ... n(%) を c2〜c6 に格納 */
      keep c1-c6; output;
    end;
  run;
%mend;

/* macro parameter に = を含む場合は必ず %str() で囲む */
%ae_table(i1, %str(fasfl="Y"), 寛解導入1)
```

**重要**: `proc report` の `column` 文に全列を明示すること。  
`define c6` を書いても `column` 文に `c6` がなければ表示されない。

```sas
column c1 ("Grade" c2 c3 c4 c5 c6);   /* <-- 追加した列を忘れずに */
define c6 / style(header)=[width=2.2cm];
```

---

## 4. よくあるエラーと解決策

| エラー内容 | 原因 | 解決策 |
|---|---|---|
| `length c1 . c2-c5 .;` になっている | PowerShell `@"..."@` が `$200.` を展開 | `@'...'@` に変更 |
| `working_dir` が誤ったパスを返す | `%scan` 区切り文字がバッククォート | `'\'` にシングルクォートで変更 |
| `proc report` で列が表示されない | `column` 文に列名が抜けている | `column` 文に全列を追加 |
| `定位置パラメータはすべてキーワードパラメータより前` | `%macro(arg, cond="Y")` に `=` が含まれる | `%str(cond="Y")` でラップ |
| `c1 の幅が 1 と 120 の範囲にありません` | `ls=120` が短すぎる | `ls=200` に変更 |
| `ERROR: 値'%'は無効な SAS 名` | label 文に `%` が含まれる | label から `%` を除去または `%str(%)` でエスケープ |
| `Invalid numeric data 'Baseline'` | `length timepoint ord 8.` で文字変数が数値宣言 | `length timepoint $40. ord 8. wt1 8.` と明示的に型を分ける |

---

## 5. エンドポイント計算パターン（CDISC 準拠）

### 5.1 DS ドメインの構造（AML 系試験）

DS ドメインには 1 症例につき通常 **2 レコード** が存在する:

| DSSPID | EPOCH | 内容 | DSSTDTC の意味 |
|---|---|---|---|
| `"discontinuation"` | `"TREATMENT"` | 治療中止・完了 | 治療終了日 |
| `"withdrawal"` | `"FOLLOW-UP"` | 最終追跡・死亡 | **最終追跡日 / 死亡日** |

打ち切り日・死亡日は `withdrawal` レコードの `DSSTDTC` を使用する。  
`discontinuation` の日付は治療終了日であり打ち切り日ではない。

### 5.2 EFS/OS/RFS 計算ロジック

```sas
/* EFS 治療不応のイベント日: DS 中止日ではなく RS 評価日を使う */
if crfl ne "Y" then do;
  if rsdt_ev2 ne . then edt_fail = rsdt_ev2;     /* eval2 完了 → eval2 RSDTC */
  else if rsdt_ev1 ne . then edt_fail = rsdt_ev1; /* eval1 のみ → eval1 RSDTC */
end;

/* RFS 起算日: 登録日ではなく CR（または LFS）到達日 */
/* PRT に lfsdt が規定されている場合は lfsdt を使うこと */
rfs_d = rfsdt - lfsdt + 1;
```

### 5.3 CR 判定ルール（AML）

```sas
/* AML の CR は寛解導入コース後の評価のみ対象 */
/* 地固め以降の評価は CR 判定に含めない */
where rstestcd = "OVRLRESP"
  and rsorres = "CR"
  and rsspid in ("evaluation1", "evaluation2");
```

`FAILURE TO MEET CONTINUATION CRITERIA`（FTMCC）は**行政的中止であり治療不応ではない**。  
EFS イベントには含めず、CR の有無を RS ドメインで確認すること。

### 5.4 LFS（Leukemia-free Survival）の扱い

LFS = CR より緩い基準（骨髄芽球 < 5% かつ髄外病変なし）。  
RS ドメインに CRi/LFS の専用値がない場合は **CR ≈ LFS の保守的近似**を使用:

```sas
lfsfl = crfl;   /* TODO: LB+FA による厳密判定に将来変更 */
lfsdt = crdt;
```

RFS 起算日は PRT の規定に従い、`crdt` ではなく `lfsdt` を使うこと（PRT v2.4 §8.1.1 等）。

---

## 6. プロジェクトフォルダ構成（推奨テンプレート）

```
PROJECT_NAME/
├── input/
│   ├── rawdata/       # SDTM ドメイン別 CSV
│   ├── ads/           # 解析用データセット（*.sas7bdat）
│   └── ext/           # 外部データ（施設一覧等）
├── program/
│   ├── macro/         # 共通マクロ（km_pt.sas 等）
│   └── vX_旧版/       # 旧バージョン（参照のみ・編集禁止）
├── output/            # RTF 出力
├── log/               # SAS ログ
├── docs/              # 記録類（本ファイル等）
├── TMF/               # PRT・SAP・aCRF
└── CLAUDE.md
```
