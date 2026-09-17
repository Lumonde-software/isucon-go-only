# CHANGES

isucon/isucon14 を Go 実装のみに削ぎ落としてモノレポに配置した際の変更記録。

## 元リポジトリ

- https://github.com/isucon/isucon14.git
- ブランチ: main（デフォルト）
- コミット: 53f8b627e040c30ebec600457c6c97da008b84b0（2026-09-17 に --depth=1 で取得）

## 削除したもの

### webapp の他言語実装

- `webapp/nodejs`
- `webapp/perl`
- `webapp/php`
- `webapp/python`
- `webapp/ruby`
- `webapp/rust`

### Ansible（provisioning/ansible）

- `roles/xbuildwebapp/` 全体（Rust/Node.js/Perl/Ruby/PHP/uv のランタイムインストール役。Go は `roles/xbuild` が担当するため不要）
- `roles/webapp/tasks/{node,perl,php,python,ruby,rust}.yaml`
- `roles/webapp/files/isuride-{node,perl,php,python,ruby,rust}.service`
- `roles/webapp/files/isuride.php-fpm.conf`
- `roles/nginx/files/etc/nginx/sites-available/isuride-php.conf`

### development（docker compose）

- `development/compose-{node,perl,php,python,ruby,rust}.yml`
- `development/dockerfiles/Dockerfile.{node,perl,php,python,ruby,rust}`
- `development/php/`（php 用 nginx / php-fpm 設定）

### CI・その他

- `.github/disabled-workflows/{node,perl,php,python,ruby,rust}.yml`
- `.perltidyrc`
- `.git`（コピーせず）

## 参照修正した箇所

- `provisioning/ansible/roles/webapp/tasks/main.yaml`: node/perl/php/python/ruby/rust の `include_tasks` を削除（go/matcher/payment_mock は残置）
- `provisioning/ansible/application-base.yml`: roles から `xbuildwebapp` を削除
- `provisioning/ansible/roles/nginx/tasks/main.yaml`: `isuride-php.conf` のデプロイ項目を削除
- `provisioning/ansible/roles/webapp/files/isuride-matcher.service`: `After=isuride-{node,perl,php,python,ruby,rust}.service` を削除(`After=isuride-go.service` のみ残置)
- `provisioning/ansible/roles/xbuild/files/.local.env`: golang の PATH のみ残し、node/cargo/php/ruby/perl/python の PATH と PERL5LIB を削除
- `Taskfile.yml`: `perl:run` タスクを削除
- `.vscode/settings.json`: `perlnavigator.includePaths` を削除
- `README.md`: 「対象言語の絞り込み」節を Go 専用リポジトリである旨に書き換え、「docker compose での環境構築（Go/Perl言語のみ）」を「（Go言語のみ）」に変更

## サービスのデフォルト

元リポジトリの時点で `isuride-go` がデフォルト有効（`roles/webapp/tasks/go.yaml` で enabled: true / restarted、他言語は enabled: false / stopped）。切り替えの焼き込みは不要で、他言語タスクの削除のみ行った。

## isucon14.cfg の変更点

cloud-init-isucon の isucon14.cfg をベースに配置。変更は git clone 部分のみ:

- 変更前: `rm -rf ${GITDIR}` + `git clone --depth=1 https://github.com/isucon/isucon14.git ${GITDIR}`
- 変更後: Lumonde-software/isucon-go-only を sparse checkout して `isucon14/` サブディレクトリを `${GITDIR}` に移動する方式（`GITDIR="/tmp/isucon14"` は元の値のまま）

cfg 内の sed・パッチの成立性を削ぎ落とし後のツリーに対して確認済み:

- `/go-install/` への sed → `roles/xbuild/tasks/main.yml` に `go-install` 行あり。成立
- `s/_linux_amd64//` → `roles/bench/tasks/main.yaml` に `bench_linux_amd64` あり。成立
- `/isuadmin-user/d` `/envcheck/d` → `application.yml` に両行を残置してあるため成立(この sed が前提のため、isuadmin-user / envcheck の各 role はあえて削除していない)
- TLS 差し替え → `roles/nginx/files/etc/nginx/tls/` 残置。成立
- frontend make / bench go build / webapp tar → 各ディレクトリ残置。成立

## 注意点

- `docs/manual.md`(当日マニュアル)には他言語への切り替え手順(isuride-php.conf のシンボリックリンク等)が歴史的記述として残っているが、ドキュメントのため修正していない
- `webapp/openapi.yaml` の言語 enum(perl/ruby/rust 等)は API 仕様のため残置
- `development/matching.js`(ローカル開発用マッチャーの Node.js 実装例)は webapp の言語実装ではないため残置。compose は curl イメージを使用しており依存しない
- `.github/workflows/image.yml` の setup-node はフロントエンドビルド用のため残置
- アプリコードのチューニングは一切していない(忠実な go-only 化のみ)
