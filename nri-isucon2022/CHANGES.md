# CHANGES

nri-isucon2022 を Go 実装のみに削ぎ落としてモノレポ(isucon-go-only)に配置した際の変更記録。

## 元リポジトリ

- https://github.com/nri-isucon/nri-isucon2022.git
- ブランチ: main(デフォルト)、commit `b2c199dcfb8c3a4941eabe14ed970a407b8cfe43`
- `--depth=1` で取得し `.git` を除いてコピー

## 削除したもの

- `webapp/backend/java/`(Java 実装一式)
- `webapp/backend/python/`(Python 実装一式)
- `provisioning/ansible/roles/web-java/`(Java ビルド + isubnb.java.service)
- `provisioning/ansible/roles/web-python/`(poetry install + isubnb.python.service)

## 参照修正箇所

- `provisioning/ansible/standalone.yaml`: roles から `web-python` / `web-java` を削除
- `provisioning/ansible/roles/langs/tasks/main.yaml`: Python 3.8.6 のインストール(`python-install`)と .bashrc への python PATH 追記タスクを削除(Go のインストールのみ残置)
- `provisioning/ansible/roles/common/tasks/package.yaml`: `openjdk-11-jdk` を apt パッケージ一覧から削除
- `provisioning/ansible/roles/web-bootstrap/tasks/main.yaml`:
  - `Git Clone` タスクを、ansible git モジュールによる元リポジトリ(nri-isucon/nri-isucon2022)clone から、isucon-go-only モノレポの sparse clone(`git clone --depth=1 --filter=blob:none --sparse` → `sparse-checkout set nri-isucon2022` → `/home/isucon/isubnb` へ mv)の shell タスクに置換
  - `Upgrade pip` / `Install poetry` タスクを削除(Python 実装専用のため)。これに伴い `&env` アンカーが消えるので、`Setup MySQL` の `environment` を PATH 直書きに変更(python の PATH 要素は除去)
- `provisioning/ansible/roles/web-go/tasks/main.yaml`: environment PATH から `/home/isucon/local/python/bin` を除去
- `provisioning/ansible/roles/remove/tasks/main.yaml`: 削除対象一覧から `webapp/backend/java/.gitignore` / `webapp/backend/python/.gitignore` を除去

デフォルトで起動するサービスは元々 Go(`web-prepare` が `isubnb.go.service` を start/enable)のため、切り替えの焼き込みは不要だった。

## cfg(nri-isucon2022.cfg)の変更点

参考元: matsuu/cloud-init-isucon の nri-isucon2022.cfg。

- git clone 部分を isucon-go-only モノレポの sparse clone パターンに置換(GITDIR は元の値 `/tmp/nri-isucon2022` を維持)
- `sed -i -e 's/poetry install/poetry update/' roles/web-python/tasks/main.yaml` を削除(対象ファイルごと削除済みで、残すと `set -e` により失敗するため)
- 残した sed 2 つは削ぎ落とし後のファイルで成立することを実行確認済み:
  - `/timezone/d`(roles/common/tasks/main.yaml): timezone.yaml の include 2 行を削除 → OK
  - `/go-install/s/command:.../shell:... uname/dpkg 引数追加`(roles/langs/tasks/main.yaml): `command: /tmp/xbuild/go-install 1.15.6 ...` 行に適用 → OK

## 注意点

- provisioning は Ubuntu 18.04(mysql-server-5.7 前提)向け。README.cloud-init.md の要件どおり
- ベンチマーカーはバイナリ配布(benchmark/linux-amd64 は x86-64 用)。macos/windows 用バイナリは参考としてそのまま残した
- `webapp/frontend/`(ビルド済み静的ファイル)は nginx 配信に必要なため残した
- ansible 側の clone 先(`/home/isucon/isubnb`)は sparse clone 後の mv になるため、以後 `.git` を持たない(remove ロールの `.git` 削除は no-op になるが害はない)
- docs/(regulation.md, manual.md)と README.md は元リポジトリのまま。Java/Python 実装への言及が残るが、ドキュメントのため未修正
