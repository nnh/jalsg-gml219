# JALSG-GML219_CSVtoSASDS.sas 修正メモ

作成日：2026-05-04  
対象ファイル：`program/JALSG-GML219_CSVtoSASDS.sas`

---

## 修正済み（6件）

### 修正1：`_root` パスを Windows 用に変更

**行番号**：`%let _root` 行（ファイル先頭部）

| | コード |
|---|---|
| 変更前 | `%let _root = /Users/akiko/Projects/NMC/Stat/JALSG-GML219;` |
| 変更後 | `%let _root = C:/Users/AkikoSaito/Data/NMC/Stat/JALSG-GML219;` |

**理由**：元のコードが Mac 環境のパスで記述されていたため。SAS on Windows はフォワードスラッシュを受け付けるため区切り文字はそのまま使用。

---

### 修正2：`%sasds_sdtm` マクロのインポート先を rawdata 直下に変更

| | コード |
|---|---|
| 変更前 | `datafile= "&_root./input/rawdata/20251205 fixed data/GML219_cdisc_251205_1446/&dsnm..csv"` |
| 変更後 | `datafile= "&_root./input/rawdata/&dsnm..csv"` |

**理由**：データ更新のたびにバージョン付きサブフォルダ名を書き換える必要があり保守性が低かった。

---

### 修正3：`cga_phase` の値にアンダースコアを追加

| | コード |
|---|---|
| 変更前 | `if qsspid = "baseline_cga"  then cga_phase = "bl";` |
| 変更後 | `if qsspid = "baseline_cga"  then cga_phase = "_bl";` |
| 変更前 | `else if qsspid = "consoli1_cga" then cga_phase = "c1";` |
| 変更後 | `else if qsspid = "consoli1_cga" then cga_phase = "_c1";` |

**原因**：SAS 9.4 TS1M7 DBCS3170 では `PROC TRANSPOSE` の `id` に複数変数を指定した際、アンダースコアなしで値が連結される（`CGA1A` + `bl` → `CGA1Abl`）。`cga_phase` の値に先頭アンダースコアを付けることで `CGA1A_bl` を生成する。

---

### 修正4：打ち切り日を固定カットオフ日 → 個別最終追跡日へ変更

**コミット：** `7fd9902`

| | コード |
|---|---|
| 変更前 | `efsdt = &cutdt.` （2025-12-05 固定） |
| 変更後 | `efsdt = dsstdt2` （DS DSSPID="withdrawal" の DSSTDTC） |

OS・RFS の打ち切り日も同様に修正。

**理由**：固定カットオフ日では症例ごとの実際の最終追跡日が反映されない。DS ドメインの `DSSPID="withdrawal"` レコードが各症例の最終追跡日（または死亡日）を示す。

---

### 修正5：EFS 治療不応イベント日を DS 中止日 → RS 評価日へ変更

**コミット：** `ee068f6`

| | コード |
|---|---|
| 変更前 | `if dsterm = "LACK OF EFFICACY" then edt_fail = dsstdt;` |
| 変更後 | eval2 あり → `edt_fail = rsdt_ev2`、eval1 のみ → `edt_fail = rsdt_ev1` |

**理由**：DS 中止日（`DSSPID="discontinuation"` の `DSSTDTC`）は RS 評価日より数日後になることが多い。イベント日は効果判定日（RS ドメインの `RSDTC`）が正しい。

---

### 修正6：EFS 治療不応を DS 中止理由によらず RS 評価から直接判定（根本修正）

**コミット：** `99dfbfc`

```sas
/* 治療不応日：DS中止理由によらずRS評価から直接判定 */
/* CR未達成（crfl ne "Y"）かつRS評価実施済みの場合にEFSイベントを設定 */
if crfl ne "Y" then do;
  if rsdt_ev2 ne . then edt_fail = rsdt_ev2;
  else if rsdt_ev1 ne . then edt_fail = rsdt_ev1;
end;
```

**修正5 が不完全だった理由**：`dsterm = "LACK OF EFFICACY"` の条件に依存していたため、`FAILURE TO MEET CONTINUATION CRITERIA` で中止したが CR 未達成の 4 症例（GML219-0002, 0046, 0120, 0128）が漏れていた。これらは eval2 が実施されずに治療中止になった症例。

**正しい考え方**：EFS 治療不応は**行政的な中止理由（DS）ではなく効果判定結果（RS）から判断する**。RS で CR 未達成（crfl ne "Y"）かつ評価が実施されていれば、それがイベント。

---

## 残存問題（1件・未修正）

### ラベル文字列内の `%` がマクロ呼び出しとして解釈される

```sas
bl_blastle = "Baseline 末梢血芽球比率（%）"
bl_myblale = "Baseline 骨髄芽球比率（%）"
```

**ログのエラー**：`ERROR: 値'）'nは無効なSAS名です。`

**影響**：ラベル設定に失敗するのみ。変数値・データセット作成自体は完了。SAS 終了コードが 1 になる。

**対処法**：
```sas
-- 案1: %str() でエスケープ
bl_blastle = "Baseline 末梢血芽球比率（%str(%)）"

-- 案2: % をラベルから除去
bl_blastle = "Baseline 末梢血芽球比率"
```

---

## EFS/OS/RFS 修正経緯（3回の試行錯誤）

### なぜ3回の修正が必要だったか

EFS イベント定義の実装において、「DS ドメインの中止理由から治療不応を判定する」という誤った前提から出発したため、段階的な修正が必要になった。

| 回 | 修正内容 | 残存問題 |
|---|---|---|
| **第1回** | 打ち切り日を個別最終追跡日へ変更 | FTMCC の取り扱いが不明確 |
| **第2回** | LACK OF EFFICACY のイベント日を RS 評価日へ変更 | FTMCC+CR=N の 4 例が漏れ |
| **第3回** | DS 中止理由に依存しない RS ベースのロジックに全面変更 | ― |

### 各修正で判明した事実

**第1回修正（GML219-0006 の確認から）**
- `efsdt` が `2025-12-05`（固定値）になっており個別の最終追跡日ではなかった
- GML219-0006 は FTMCC で中止だが寛解を維持 → EFS イベントにならない

**第2回修正（GML219-0022 等の確認から）**
- LACK OF EFFICACY のイベント日は DS 中止日ではなく RS 評価日が正しい
- DS 中止日は RS 評価日の数日後になることが多い（評価日に結果が出てから中止手続きが入力される）
- `crfl` の判定は `rsspid in ("evaluation1","evaluation2")` に限定すべき（AML 寛解導入は2コースまで）

**第3回修正（GML219-0002 等の確認から）**
- `dsterm = "LACK OF EFFICACY"` に依存していたため、FTMCC+CR=N の 4 例が漏れた
- これらは eval2 が実施されず eval1 のみ（= induction1 後に治療中止）の症例
- **根本的な解決策：** DS 中止理由を見るのではなく、RS で CR 未達成（crfl ne "Y"）であることを直接判定する

---

## 次回プロジェクトへの申し送り事項

### SDTMデータセットから解析用データセットを作成する際の重要確認点

次回の AML（または類似の造血器腫瘍）試験の解析開始前に、以下の情報を統計担当者から確認・共有しておくこと。これらが最初から明確であれば、EFS イベント定義の試行錯誤が不要になる。

---

#### 1. DS ドメインの構造と意味

「DS ドメインに何レコード存在するか」「各 DSSPID の意味は何か」を確認する。

本試験の例：
- `DSSPID="discontinuation"` + `EPOCH="TREATMENT"` → 治療中止理由（DSTERM）と中止日
- `DSSPID="withdrawal"` + `EPOCH="FOLLOW-UP"` → 最終追跡日 / 死亡（DSTERM="DEATH"）

**打ち切り日として使用するのは `withdrawal` レコードの `DSSTDTC`**。`discontinuation` レコードの日付は治療終了日であり、打ち切り日ではない。

---

#### 2. EFS イベント「治療不応」の判定根拠

「治療不応をどのドメインから判断するか」を明確にする。

- **RS ドメイン（効果判定）から判断するのが原則。DS 中止理由は参考にとどめる**
- AML の場合：induction 1〜2 コース後の評価（RSSPID="evaluation1/2"）で OVRLRESP=CR が得られなければ治療不応
- `FAILURE TO MEET CONTINUATION CRITERIA` は行政的・毒性的中止であり、治療不応とは別概念。**EFS イベントにならない**
- `LACK OF EFFICACY` は RS 評価結果と一致することが多いが、**イベント日は DS 中止日ではなく RS 評価日**を使用する

---

#### 3. CR（Complete Remission）の判定ルール

「何回目の評価までを CR 判定に含めるか」を確認する。

AML の標準：
- **寛解導入期（induction 1〜2 コース）の評価のみ** を CR 判定に使用
- 地固め療法後の評価（evaluation3 以降）は CR 判定に含めない
- これを SAS で実現：`where rsspid in ("evaluation1","evaluation2")`

---

#### 4. RFS の起算日

- OS・EFS の起算日 = 登録日（`rfstdt`）
- **RFS の起算日 = CR 達成日（`crdt`）**。登録日ではない

---

#### 5. 打ち切り日の根拠

- **固定カットオフ日（データカット日）ではなく個別の最終追跡日を使用する**
- 個別最終追跡日 = DS `DSSPID="withdrawal"` の `DSSTDTC`
- データカット日は SAS ログ確認等の目的には使えるが、解析の打ち切り日として使用してはいけない

---

#### 6. eval1 のみ実施で治療中止となった症例の扱い

eval2（induction 2 コース後評価）が実施されずに治療が中止された症例が存在する場合：

- CR 未達成（crfl ne "Y"）かつ eval1 のみ実施 → **eval1 の RS 評価日をイベント日とする**
- DS 中止理由が FTMCC であっても、RS で CR 未達成なら EFS イベントとして扱う

---

## SAS 実行結果サマリー

| 項目 | 第1回実行 | 最終実行後 |
|------|------|------|
| 実行日 | 2026-05-04 | 再実行要 |
| SAS バージョン | 9.4 TS1M7 DBCS3170 | — |
| 終了コード | 1（ラベル文 ERROR） | — |
| 最終データセット | 128 obs × 369 vars | 再実行後に確認要（406 vars 見込み） |
| Excel 出力 | 正常作成 | 再実行要 |
| EFS/OS/RFS 変数 | 誤り | 修正6適用済み・再実行後に確認要 |
