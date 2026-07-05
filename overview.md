# JALSG-GML219 — 概要

随時更新（2026-07-05 時点）

## 一文要約

高齢者急性骨髄性白血病(AML)の層別化により化学療法が可能な症例に対して若年成人標準化学療法の近似用量を用いる第II相臨床試験

## 現在の状況

解析フェーズ。2026年5月31日にPIからの照会4件（RFS/EFS-OS/中止理由/CGA7・CCI）への回答を送付済み、6月26日には伊藤先生からの追加照会（データ略号対応表・死亡イベント数不一致の解明）にも対応済み。7月5日、6月26日回答Q2-4で合意した「CR後死亡(再発前)」ラベル訂正をプログラム3本・アウトプット・回答文書（Googleドキュメント）に反映し、さらに先生から要望のあったELN2022（Döhner et al. Blood 2022）リスク分類を`eln2022`変数として追加（既存の`eln2017`はSAP記載のプライマリ分類として維持し並列表示）。Baseline表（Table1）・OS/EFS/RFS生存解析（新規Fig10）ともに`eln2017`→`eln2022`の順で反映済み。データセット項目対応表を更新し、伊藤先生への回答メールを最終化・送付準備完了。詳細な経緯は[`docs/JALSG-GML219_対応履歴.md`](docs/JALSG-GML219_対応履歴.md)を参照。

## GitHub / Box

- GitHubリポジトリ：https://github.com/nnh/jalsg-gml219
- Boxフォルダ：https://nmccrc.app.box.com/folder/336449975048

対応関係の一覧はstat-hubリポジトリの [overview.md](https://github.com/saito-la/stat-hub/blob/main/overview.md) の「対象試験一覧」にも記録する。

## 関連

- 既知の問題：[issues.md](issues.md)
- 次アクション：[next-action.md](next-action.md)
