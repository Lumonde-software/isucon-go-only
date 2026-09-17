# go-only 化の変更記録

[catatsuy/private-isu](https://github.com/catatsuy/private-isu) のデフォルトブランチ(取り込み時点 77bc87d5)をベースに、Go 実装だけで練習・ベンチ実行できる構成へ削ぎ落として `private-isu/` に配置した。cloud-config(`*.cfg`)は [matsuu/cloud-init-isucon](https://github.com/matsuu/cloud-init-isucon) の private-isu 用 3 ファイルをベースにしている(原本は `README.cloud-init.md` 参照)。

## 方針

- 残す: `webapp/golang`・`webapp/sql`・`webapp/public`・`webapp/etc`(Go で使う nginx 設定)、`benchmarker`、`provisioning`(Go 実行に必要な部分)、ドキュメント類
- 削る: Go 以外の言語実装(Ruby/PHP/Python/Node.js)と、その言語のためだけに存在するセットアップ(ランタイムインストール、systemd unit、nginx/php-fpm 設定、CI、renovate ルール)

## 削除したもの

- `webapp/{ruby,php,python,node}`
- `webapp/etc/nginx/conf.d/php.conf.org`(PHP 用 nginx 設定)
- `provisioning/image/files/etc/systemd/system/isu-{ruby,node,python}.service`
- `provisioning/image/files/etc/php/`(php-fpm の www.conf)
- `provisioning/image/files/etc/nginx/sites-available/isucon-php.conf`
- `.github/CODEOWNERS`(webapp/python の 1 行のみだったためファイルごと削除)

## 参照の後始末(プロビジョニング)

- `provisioning/image/ansible/04_xbuild.yml`: ruby/node/python の xbuild インストールと PHP 8.1/8.3 の 2 プレイを削除。xbuild + go-install 1.27.1 のみ残した
- `provisioning/image/ansible/05_app.yml`: upstream を再 clone するタスクを廃止し、cloud-config が `/tmp/private-isu` に配置した checkout からコピーする方式に変更(`repo_url`/`tmp_dir` 変数を `src_dir: /tmp/private-isu` に置換)
- `provisioning/image/ansible/07_application.yml`: bundle install(Ruby)・composer(PHP)・npm(Node)・venv/uv(Python)の各プレイと isu-ruby/isu-node/isu-python unit 配布、php-fpm への EnvironmentFile 追記を削除。**デフォルト起動サービスを isu-ruby → isu-go に変更**(焼き込み)
- `provisioning/image/ansible/03_nginx.yml`: isucon-php.conf の配布タスクを削除(isucon.conf は port 8080 への proxy なので Go はそのまま動く)
- `provisioning/bench/ansible/03_bench.yml`: upstream の clone を廃止し `/tmp/private-isu` から `/home/isucon/private_isu.git/` へコピーする方式に変更
- `provisioning/image/files/home/isucon/env.sh`: PATH から ruby/node/python3/perl/php/scala を削除(go のみ)
- `provisioning/image/files/etc/profile.d/bashrc`: ruby/node の PATH export を削除(go のみ)

## 参照の後始末(その他)

- `webapp/compose.yml`: app サービスの build context を `ruby/` → `golang/` に変更(焼き込み)
- `.github/workflows/ci.yml`: trigger paths を golang/benchmarker のみに縮小。言語検出と purl による compose.yml 書き換えステップを削除(compose.yml が常に golang をビルドするため不要)
- `.github/workflows/codeql.yml`: language matrix を `["go"]` のみに
- `renovate.json`: ruby/php/node/python の lockFileMaintenance ルール、bundler/composer/npm/pep621 の rangeStrategy ルール、unicorn(bundler)の registryUrls ルールを削除

## cfg の変更点

3 ファイルとも `GITDIR="/tmp/private-isu"` は元の値のまま、git clone 部分を Lumonde-software/isucon-go-only の sparse checkout(`private-isu` ディレクトリのみ取得して `${GITDIR}` へ配置)に変更。

- `app.cfg`: 上記に加え `--skip-tags nodejs` を削除(nodejs タグのタスク自体を削除済みのため)
- `benchmarker.cfg`: clone 部分のみ変更
- `standalone.cfg`: clone 部分の変更と `--skip-tags nodejs` の削除

sed の成立性確認:

- `sed -i 's/isu-app/localhost ansible_connection=local/' hosts`(app/standalone): `provisioning/hosts` は無変更で `isu-app` を含むため成立
- `sed -i 's/isu-bench/localhost ansible_connection=local/' hosts`(benchmarker/standalone): 同上、`isu-bench` を含むため成立
- cfg 中のその他のパッチはなし。playbook のパス(`image/ansible/playbooks.yml`・`bench/ansible/playbooks.yml`)はすべて存在

## 残置(意図的に触っていないもの)

- `portal/`・`ansible_old/`: Ruby 製の運営ポータルと旧提供手順。webapp の言語実装ではなく、cfg のプロビジョニングからも参照されないため残置
- `README.md`・`manual.md`・`public_manual.md`・`CLAUDE.md`・`AGENTS.md` 内の他言語への言及(ドキュメントのため)。特に CLAUDE.md は「5 言語実装がある」前提の記述のままなので注意
- `provisioning/image/ansible/00_base.yml` の apt パッケージ群(他言語ビルド用のライブラリも含むが、ベース構成として忠実に維持)
- 初期データは従来どおり upstream releases から取得(`06_createdb.yml` の dump.sql.bz2、`04_userdata.yml`/`08_userdata.yml` の img.zip、ルート Makefile の `make init`)

## 注意点

- 標準で isu-go(port 8080)が起動し、nginx が proxy する。Ruby 版は存在しない
- `/home/isucon/private_isu.git` と `/home/isucon/private_isu` は git リポジトリではなくなる(sparse checkout から `mv`/コピーした静的ファイルのため)。履歴管理したい場合は各自 `git init` する
- `allinone` 変数付きの実行(README.cloud-init.md にない all-in-one 用 playbook 実行)は upstream 同様に残してあるが、cfg からは使われない(standalone.cfg は bench playbook を別途実行する方式)
- ベンチ実行パスは従来どおり `/home/isucon/private_isu.git/benchmarker`(README.cloud-init.md 記載のまま)

## 動作確認

- `webapp/golang` と `benchmarker` の `go build` が成功することを確認済み
- 変更した全 YAML(playbook・cfg・workflows・compose.yml)と renovate.json のパースが通ることを確認済み
