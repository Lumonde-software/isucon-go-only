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

## Ubuntu 22.04対応(MySQL 5.7→8.0)

元は Ubuntu 18.04 + MySQL 5.7 前提だった provisioning を Ubuntu 22.04(MySQL 8.0)で動くよう静的修正した。

- `provisioning/ansible/roles/web-bootstrap/tasks/main.yaml`(Install Package(MYSQL)):
  - `mysql-server-5.7` / `mysql-server-core-5.7` / `mysql-client-5.7` / `mysql-client-core-5.7` をバージョン無指定の `mysql-server` / `mysql-client` に変更(22.04 では MySQL 8.0 が入る。core パッケージは依存で入る)
  - `libmysqld-dev`(組み込みサーバー用。MySQL 8.0 で廃止され 22.04 に存在しない)→ `libmysqlclient-dev` に変更
- `provisioning/ansible/roles/web-bootstrap/files/mysqld.cnf`:
  - `query_cache_limit` / `query_cache_size` を削除(query cache は MySQL 8.0 で削除済み。残すと mysqld が起動しない)
  - `disable-log-bin` を追加(8.0 はバイナリログがデフォルト有効。5.7 時代の挙動・ディスク消費に合わせて無効化)。あわせて `expire_logs_days`(8.0 で非推奨)をコメントアウト
- `provisioning/ansible/roles/web-bootstrap/files/my.cnf` と `webapp/backend/mysql/my.cnf`(同内容の2ファイル):
  - `[mysqld] local_infile=1` と `[mysql] local-infile=1` を追加。8.0 ではサーバー・クライアントとも local_infile がデフォルト無効で、初期データ投入(`1_CsvDataImport.sql` の `LOAD DATA LOCAL INFILE`、/initialize からも実行)が失敗するため
- `README.md`: Multipass 起動例を `18.04` → `22.04` に変更、「18.04 イメージが入手できない場合がある」注記を削除(Apple Silicon 不可の注記は残置)
- `README.cloud-init.md`: Requirements を Ubuntu 18.04 → 22.04 に変更

### 修正不要と判断したもの

- `GRANT ... IDENTIFIED BY` 構文(8.0 で廃止)は元々使われておらず、`CREATE USER` + `GRANT` に分離済みだった
- MySQL root は Ubuntu パッケージだと auth_socket 認証(5.7/8.0 とも同じ)のため、`/root/.my.cnf` 経由の root 接続はそのまま動く
- isucon ユーザーは 8.0 デフォルトの caching_sha2_password になるが、mysql CLI(8.0)および go-sql-driver/mysql v1.5.0 は対応済み(`default_authentication_plugin` の変更は不要)
- スキーマ・アプリ内 SQL に 5.7 専用構文や 8.0 の新規予約語との衝突は見当たらなかった
- cfg 内の sed 2 つ(timezone 削除、go-install の command→shell 変換)は修正後のファイルでも従来どおりマッチする
- 18.04 向け PPA・apt-key・python2 依存は provisioning 内に存在しない。22.04 の apt ansible(2.10 系、python3)で使用モジュールはすべて利用可能(`include:` は非推奨警告のみ)

### 注意(未修正の互換性リスク)

- MySQL 5.7 → 8.0 でオプティマイザ・デフォルト値(temptable エンジン等)が変わるため、ベンチマークスコアや実行計画は 18.04 当時と一致しない可能性がある
- 8.0 は 5.7 よりメモリ消費が大きい。メモリ 2GB だと構築・ベンチ中に不足する場合があるため、Multipass では README の例どおり 4GB 以上を推奨
- `provisioning/Vagrantfile` は `ubuntu/bionic64` のまま(Vagrant 経路は 22.04 対応の対象外。使う場合は box 変更と同様の見直しが必要)
- Go は xbuild による 1.15.6 のバイナリ導入のままで 22.04 でも動作する想定だが、実機での動作確認は未実施(本対応は静的修正のみ)

## 注意点

- provisioning は Ubuntu 22.04(MySQL 8.0)向けに修正済み(上記「Ubuntu 22.04対応」参照。元は Ubuntu 18.04 + mysql-server-5.7 前提)
- ベンチマーカーはバイナリ配布(benchmark/linux-amd64 は x86-64 用)。macos/windows 用バイナリは参考としてそのまま残した
- `webapp/frontend/`(ビルド済み静的ファイル)は nginx 配信に必要なため残した
- ansible 側の clone 先(`/home/isucon/isubnb`)は sparse clone 後の mv になるため、以後 `.git` を持たない(remove ロールの `.git` 削除は no-op になるが害はない)
- docs/(regulation.md, manual.md)と README.md は元リポジトリのまま。Java/Python 実装への言及が残るが、ドキュメントのため未修正
