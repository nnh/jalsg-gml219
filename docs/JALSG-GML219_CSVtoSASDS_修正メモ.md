# JALSG-GML219_CSVtoSASDS.sas 修正メモ

作成日：2026-05-04  
対象ファイル：`program/JALSG-GML219_CSVtoSASDS.sas`

---

## 修正済み（3件）

### 修正1：`_root` パスを Windows 用に変更

**行番号**：`%let _root` 行（ファイル先頭部）

| | コード |
|---|---|
| 変更前 | `%let _root = /Users/akiko/Projects/NMC/Stat/JALSG-GML219;` |
| 変更後 | `%let _root = C:/Users/AkikoSaito/Data/NMC/Stat/JALSG-GML219;` |

**理由**：元のコードが Mac 環境のパスで記述されていたため。SAS on Windows はフォワードスラッシュを受け付けるため区切り文字はそのまま使用。  
**波及範囲**：`_root` を参照するすべての箇所（ログ出力先・libname・`%sasds_ext`・Excel出力先）が自動的に Windows パスに切り替わる。

---

### 修正2：`%sasds_sdtm` マクロのインポート先を rawdata 直下に変更

**行番号**：`%macro sasds_sdtm` 内の `datafile=` 行

| | コード |
|---|---|
| 変更前 | `datafile= "&_root./input/rawdata/20251205 fixed data/GML219_cdisc_251205_1446/&dsnm..csv"` |
| 変更後 | `datafile= "&_root./input/rawdata/&dsnm..csv"` |

**理由**：データ更新のたびにバージョン付きサブフォルダ名を書き換える必要があり保守性が低かった。`input/rawdata/` 直下に最新の SDTM ドメイン CSV（AE, CE, CM, DD, DM, DS, EC, EG, FA, LB, MH, PE, QS, RS, SC, VS 等）が配置されているため、そちらを参照する。

---

### 修正3：`cga_phase` の値にアンダースコアを追加

**行番号**：セクション6（CGA 処理）の `data tmp6_cga;` ステップ内

| | コード |
|---|---|
| 変更前 | `if qsspid = "baseline_cga"  then cga_phase = "bl";` |
| 変更後 | `if qsspid = "baseline_cga"  then cga_phase = "_bl";` |
| 変更前 | `else if qsspid = "consoli1_cga" then cga_phase = "c1";` |
| 変更後 | `else if qsspid = "consoli1_cga" then cga_phase = "_c1";` |

**原因究明の経緯**：

SAS 実行後のログに以下の WARNING が 28 件発生していた。

```
WARNING: DROP、KEEPまたはRENAMEリスト内の変数CGA1A_blは参照されませんでした。
WARNING: 変数CGA1A_BLはデータセットWORK.TMP6_CGA_FINALにありません。
```

診断プログラムで `PROC TRANSPOSE` 後の変数名を確認したところ、実際に生成された変数名は以下の通りだった。

```
CGA1Abl, CGA1Ac1, CGA2Abl, CGA2Ac1, ... （アンダースコアなし）
```

`PROC TRANSPOSE` の `id qstestcd cga_phase;` において、この環境（SAS 9.4 TS1M7 DBCS3170）では ID 変数値をアンダースコアなしで連結することが判明。  
後続の `rename CGA1A_bl=cga1a_bl` が機能しておらず、最終データセットで CGA 変数がすべて欠損していた。

**対処**：`cga_phase` の値をあらかじめ `"_bl"` / `"_c1"` とすることで、連結後の変数名が `CGA1A_bl` / `CGA1A_c1` になり RENAME が正常に機能する。

---

## 残存問題（1件・未修正）

### ラベル文字列内の `%` がマクロ呼び出しとして解釈される

**行番号**：L387–388 付近の `label` 文

```sas
bl_blastle = "Baseline 末梢血芽球比率（%）"
bl_myblale = "Baseline 骨髄芽球比率（%）"
```

**ログのエラー**：

```
ERROR: 値'）'nは無効なSAS名です。
WARNING: マクロ）の呼び出しを解決できません。
```

**原因**：SAS マクロプロセッサはダブルクォート文字列内の `%` もマクロ呼び出しとして解釈する。`%）`（`%` + 全角閉じ括弧）が `%マクロ名(...)` の形として認識され、`）` が無効な SAS 名とみなされてエラーになる。

**影響**：このエラーはラベル設定に失敗するのみで、変数値・データセット作成自体は完了している。ただし SAS の終了コードが 1 になるため、エラーなし実行を達成するには修正が必要。

**対処法（いずれか）**：

```sas
-- 案1: %str() でエスケープ
bl_blastle = "Baseline 末梢血芽球比率（%str(%)）"
bl_myblale = "Baseline 骨髄芽球比率（%str(%)）"

-- 案2: % をラベルから除去
bl_blastle = "Baseline 末梢血芽球比率"
bl_myblale = "Baseline 骨髄芽球比率"
```

---

## SAS 実行結果サマリー

| 項目 | 内容 |
|---|---|
| 実行日 | 2026-05-04 |
| SAS バージョン | 9.4 TS1M7 DBCS3170 |
| 終了コード | 1（残存 ERROR のため） |
| ログ | `log/JALSG-GML219_CSVtoSASDS.log` |
| 最終データセット | `ADSLIB.GML219`：**128 obs × 369 vars** — 正常作成 |
| Excel 出力 | `input/ads/202512 data/gml219_new.xlsx` — 正常作成 |
| ERROR 件数 | 2件（ラベル文の `%）` × 2行） |
| WARNING 件数 | 多数（CGA RENAME 28件 → 修正3で解消予定） |

> **修正3 適用後の再実行が必要**：cga_phase 修正は本ファイル作成時点で SAS ファイルに書き込み済みだが、SAS の再実行はまだ行っていない。
