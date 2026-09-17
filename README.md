# isucon-go-only

歴代 ISUCON 問題を **Go 実装のみ**に削ぎ落とし、cloud-init 一発で練習環境を構築できるようにしたモノレポ。

- ディレクトリ構成は [matsuu/cloud-init-isucon](https://github.com/matsuu/cloud-init-isucon) を踏襲
- 各問題ディレクトリに cloud-config(`*.cfg`)と、その問題リポジトリの go-only 版一式(webapp / bench / provisioning 等)を同居させている
- 各 cfg は起動時にこのリポジトリを sparse checkout し、該当問題ディレクトリだけを従来のパスに配置して matsuu 版と同じ手順でプロビジョニングする
- 各問題ディレクトリの `CHANGES.md` に、元リポジトリからの変更内容(削除した言語実装・参照修正・cfg の変更点)を記録している

| ディレクトリ | 問題 | 元リポジトリ |
|---|---|---|
| isucon10q | ISUCON10 予選 | matsuu/isucon10-qualify (fixed-aarch64) |
| isucon11-prior | ISUCON11 事前講習 | matsuu/isucon11-prior (support-non-amd64-arch) |
| isucon11q | ISUCON11 予選 | Lumonde-software/isucon11-qualify (go-only) |
| isucon11f | ISUCON11 本選 | isucon/isucon11-final |
| isucon12q | ISUCON12 予選 | isucon/isucon12-qualify |
| isucon12f | ISUCON12 本選 | isucon/isucon12-final |
| isucon13 | ISUCON13 | isucon/isucon13 |
| isucon14 | ISUCON14 | isucon/isucon14 |
| nri-isucon2022 | NRI-ISUCON2022 | nri-isucon/nri-isucon2022 |
| private-isu | private-isu | catatsuy/private-isu |

## 使い方

インスタンス作成時の user data に、対象問題ディレクトリの `*.cfg` の内容を指定する。
