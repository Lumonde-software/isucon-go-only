# CHANGES (Go-only 化の変更記録)

## 元リポジトリ

- https://github.com/matsuu/isucon10-qualify.git
- ブランチ: `fixed-aarch64`(--depth=1 で取得)
- `.git` はコピーしていない

## 削除したもの

Go 以外の言語実装と、その言語専用セットアップのみ削除。

- `webapp/deno`, `webapp/nodejs`, `webapp/perl`, `webapp/php`, `webapp/python`, `webapp/ruby`, `webapp/rust`
- `webapp/docker-compose/{deno,nodejs,perl,ruby,rust}.yaml`(`go.yaml` のみ残置。php 用は元々存在しない)
- ansible ロール: `provisioning/ansible/roles/web-{deno,node,perl,php,python,ruby,rust}`(各言語の systemd unit `isuumo.<lang>.service` 含む)
- `provisioning/ansible/roles/langs/tasks/main.yaml` から Rust / Deno / PHP / Ruby / Perl のインストールタスクを削除
  - Node.js は `webapp/frontend` のビルド(npm ci / build / export)に、Python は初期データ生成(`initial-data`、pip/Faker)に必要なため残した。Go / xbuild も残した
- CI・cloudbuild 相当は元ブランチに存在しないため削除対象なし(`.github/` は PR テンプレートのみでそのまま残置)

## 参照修正した箇所

- `provisioning/ansible/allinone.yaml`, `provisioning/ansible/competitor.yaml`:
  削除した `web-node/web-ruby/web-rust/web-php/web-perl/web-python`(および注釈の web-deno)のロール参照を削除。`web-go` → `web-prepare` の順は維持
  (`bench.yaml` は元々 Go 関連ロールのみで修正不要)
- `provisioning/ansible/roles/web-bootstrap/tasks/main.yaml` の「Clone isucon10-qualify」タスク:
  元は `matsuu/isucon10-qualify.git`(branch: `fixed`)を git モジュールで /tmp に clone していたが、
  本モノレポ(`Lumonde-software/isucon-go-only.git` の `isucon10q/`)の sparse clone に置き換え。
  後続タスク(chgroup → mv /tmp/isucon10-qualify → /home/isucon/isuumo)は無変更で成立する
- `provisioning/ansible/roles/remove/tasks/main.yaml`: 削除済み言語ディレクトリ配下
  (`webapp/{deno,nodejs,python,perl,rust,php,ruby}/Dockerfile`, `webapp/php/docker-compose.override.yml`)のエントリを削除
- `webapp/README.md`, ルート `README.md`: 「各言語の参考実装」の記述を Go のみに更新

## デフォルトサービスについて

元々 `web-prepare` ロールが有効化するのは `isuumo.go.service` のみ(Go がデフォルト)。
そのため切り替えの焼き込みは不要で、変更していない。

## cfg (isucon10q.cfg) の変更点

- 参考 cfg(cloud-init-isucon/isucon10q)からの変更は git clone 部分のみ:
  `matsuu/isucon10-qualify.git`(-b fixed-aarch64)の clone を、
  `Lumonde-software/isucon-go-only.git` の sparse clone + `isucon10q` サブディレクトリの mv に置き換え
- `GITDIR="${HOME}/isucon10-qualify"` は元の値を維持
- 元 cfg に sed やパッチは存在しない。cfg が依存するパスは
  `${GITDIR}/provisioning/ansible/allinone.yaml` のみで、削ぎ落とし後も存在することを確認済み

## 注意点

- **git バージョン**: `--filter=blob:none` / `git sparse-checkout` は新しめの git が必要
  (sparse-checkout サブコマンドは 2.25+)。README の想定どおり Ubuntu 18.04(git 2.17)で
  実行すると cfg の clone および web-bootstrap 内の clone は失敗する可能性が高い。
  その場合は通常の `git clone --depth=1` + サブディレクトリ mv への変更が必要
- **デプロイされる webapp のブランチ差**: 元の web-bootstrap は branch `fixed` を clone して
  /home/isucon/isuumo に配置していたが、本モノレポの内容は `fixed-aarch64` 由来。
  webapp 本体はほぼ同一の想定だが、厳密には元の `fixed` と差がある可能性がある
- 各ロールの `environment.PATH` に残る `/home/isucon/local/{perl,php,ruby}` 等や
  `web-bootstrap` の env アンカー内のパスは、実在しなくても無害なため未修正
- `webapp/docker-compose/go.yaml` が参照する
  `provisioning/ansible/roles/web-bootstrap/files/slow-mysqld.cnf` は元リポジトリにも存在しない
  (upstream 由来の欠落。今回の削ぎ落としによるものではない)
- README.cloud-init.md 記載のとおり Deno は元々構築対象外(allinone.yaml でもコメントアウトされていた)

## Ubuntu 22.04対応

Ubuntu 20.04 前提だったプロビジョニングを Ubuntu 22.04 (jammy) で動くように修正した(静的確認のみ。VM 実行での検証は未実施)。

### 修正した箇所

- `provisioning/ansible/roles/web-bootstrap/tasks/main.yaml`
  - MySQL パッケージ: `mysql-server-5.7` / `mysql-server-core-5.7` / `mysql-client-5.7` /
    `mysql-client-core-5.7` は 22.04 に存在しないため、バージョン無指定の
    `mysql-server` / `mysql-client` / `mysql-common` の3つに変更(22.04 では MySQL 8.0 が入る。
    isucon11q の mariadb 対応と同方針)
  - `libmysqld-dev`(embedded server、MySQL 8.0 で廃止されたパッケージ)を削除。
    ビルドに必要な `default-libmysqlclient-dev` は common ロールで導入済み
  - isucon ユーザー作成: `GRANT ... IDENTIFIED BY` 構文は MySQL 8.0 で廃止のため、
    `CREATE USER IF NOT EXISTS` + `GRANT`(+ FLUSH PRIVILEGES)に分離
- `provisioning/ansible/roles/web-bootstrap/files/mysqld.cnf`
  - `query_cache_limit` / `query_cache_size` をコメントアウト
    (query cache は MySQL 8.0 で廃止。残すと mysqld が unknown variable で起動失敗する)
  - `lc-messages-dir = /usr/share/mysql` をコメントアウト
    (22.04 の MySQL 8.0 は `/usr/share/mysql-8.0` 配下のため、デフォルトに任せる)
  - `disable-log-bin` を追加(MySQL 8.0 はデフォルトで binlog 有効。5.7 時代の挙動・負荷特性に合わせて無効化)
- `provisioning/ansible/roles/langs/tasks/main.yaml`
  - xbuild で入れる Python を 3.8.5 → 3.11.9 に変更。Python 3.8/3.9 は OpenSSL 3.0(22.04)に
    非対応でソースビルド時に ssl モジュールが欠落し、後続の pip タスク(pip 更新・Faker 導入)が失敗する
- `provisioning/ansible/roles/common/tasks/main.yaml`
  - `liblzma-dev` を追加(Python 3.11 ビルド時の _lzma モジュール欠落を防ぐ)
- `README.md`: Multipass 起動例を `20.04` → `22.04` に変更

### 修正不要と判断した箇所

- PPA・外部リポジトリ追加・`apt_key`・nodesource・python2 前提の処理は存在しない
- Node v14.9.0 / Go 1.14.7 は xbuild によるバイナリ導入のため 22.04 (glibc 2.35) でもそのまま動く
- `isuumo.go.service`(systemd unit)、nginx 設定(nginx 1.18)は 22.04 互換
- go-sql-driver/mysql v1.5.0 は MySQL 8.0 デフォルトの caching_sha2_password 認証に対応済み
  (v1.4.0 でサポート追加)のため、認証プラグインの変更は不要
- `mysql -uroot -proot` は 22.04 でも root が auth_socket 認証のため sudo 経由の
  ソケット接続で成功する(パスワードは無視される)

### 注意点(未修正の互換性リスク)

- **MySQL 5.7 → 8.0 の挙動差**: デフォルト sql_mode、オプティマイザ、照合順序デフォルト
  (utf8mb4_general_ci → utf8mb4_0900_ai_ci。本構成は character-set のみ指定)などが変わる。
  スキーマ(`webapp/mysql/db/0_Schema.sql`)や生成 SQL は単純なため動作する想定だが、
  ベンチスコアや検索結果の順序に差が出る可能性は否定できない
- `mysqld.cnf` の `expire_logs_days` は 8.0 では非推奨(起動時に警告が出るが動作はする)
- 初期データ生成(Faker は pip で最新版を導入)は Python 3.11 でも動く想定だが、
  Faker のバージョン差により生成データが元環境と厳密には一致しない可能性がある
  (これは 20.04 時代から同様。`requirements.txt` の Faker==4.1.1 は ansible からは未使用)
- `provisioning/ansible/Vagrantfile`(ubuntu/bionic64)は cfg → allinone.yaml の経路では
  使われないため未修正
- `README.cloud-init.md` の 18.04 記載は upstream 由来のまま(本モノレポの起動手順は
  ルート README.md の Multipass 手順を正とする)
