# go-only 化の変更記録(isucon13)

isucon/isucon13 の main(8f6afdc3)をベースに、Go 実装だけで練習・ベンチ実行できる最小構成へ削ぎ落とした。

## 方針

- 残す: `webapp/{go,sql,img,pdns}`、`bench`、`envcheck`、`frontend`、`scripts`、`validated`、`docs`、development の Go/MySQL/PowerDNS/nginx 構成、provisioning の Go 実行に必要な部分
- 削る: Go 以外の言語実装と、その言語のためだけに存在するセットアップ(ランタイムインストール、systemd unit、php-fpm/nginx 設定、docker-compose サービス、CI)
- isucon13 は元々 `isupipe-go` がデフォルト有効(他言語 unit は enabled:false・stopped で配布されるだけ)のため、デフォルト切り替えの焼き込みは不要だった

## 削除したもの

- `webapp/{node,perl,php,python,ruby,rust}`
- `development/docker-compose-{node,perl,php,python,ruby,rust}.yml`、`development/php/`(php-fpm 用 zz-docker.conf)
- `provisioning/ansible/roles/xbuildwebapp/`(Rust/Node/Perl/Ruby/PHP/Python のランタイムインストール専用ロール。Go は xbuild ロールが go-install するため影響なし。xbuildwebapp が作っていた /opt/xbuild/{var,bin} は他タスクから未使用)
- `provisioning/ansible/roles/webapp/tasks/{node,perl,php,python,ruby,rust}.yaml`
- `provisioning/ansible/roles/webapp/files/isupipe-{node,perl,php,python,ruby,rust}.service`、`isupipe.php-fpm.conf`
- `provisioning/ansible/roles/nginx/files/etc/nginx/sites-available/isupipe-php.conf`
- `.github_/workflows/{node,perl,php,python,ruby,rust}.yml`

## 参照の後始末

- `provisioning/ansible/application.yml` / `application-base.yml`: `xbuildwebapp` ロールを削除
- `provisioning/ansible/roles/webapp/tasks/main.yaml`: 他言語の `include_tasks` を削除(go.yaml のみ残す)
- `provisioning/ansible/roles/nginx/tasks/main.yaml`: `isupipe-php.conf` の配布項目を削除
- `provisioning/ansible/roles/xbuild/files/.local.env`: 他言語の PATH / PERL5LIB 行を削除(golang のみ残す)

## 残置(意図的に触っていないもの)

- `README.md` 86行目の xbuildwebapp への言及、`docs/` 内の他言語への言及(ドキュメントのため)
- `scripts/`(初期データ生成用の Python/Perl スクリプト。webapp 実装ではなく作問ツールのため)
- `validated/`、`frontend/`(言語非依存)
- `.github_/workflows/create-ami.yml` 等の setup-node/setup-python(AMI ビルド用 CI 手順で、webapp 言語とは無関係。`.github_` 自体が無効化済みディレクトリ)
- `provisioning/ansible/roles/apt` のパッケージ一覧(他言語ビルド向けの dev パッケージを含むが、忠実性優先で無変更)
- `provisioning/ansible/roles/nginx/files/etc/nginx/tls/` の鍵・証明書(コンテスト当時の自己署名素材。cfg が isucon.local 用を追加生成する)

## isucon13.cfg(cloud-config)の変更点

ベース: cloud-init-isucon の isucon13.cfg(README は README.cloud-init.md として同梱)。

- 変更は git clone 部分のみ。`https://github.com/isucon/isucon13.git` の clone を、本モノレポ(Lumonde-software/isucon-go-only)の sparse checkout(`isucon13` ディレクトリのみ取得し `${GITDIR}` へ配置)に置き換えた。`GITDIR="/tmp/isucon13"` は元の値を維持
- cfg 内の全 sed・パッチの成立性を削ぎ落とし後のツリーで確認済み:
  - `u.isucon.dev → u.isucon.local` の一括置換、nginx tls ディレクトリへの自己署名証明書生成: 対象パス存在 OK
  - `webapp/pdns/u.isucon.dev.zone` の mv: 存在 OK
  - `InsecureSkipVerify`(bench/cmd/bench/{benchmarker,bench}.go): 各1箇所存在 OK
  - globalip の `enabled: true`、isucon-user env.sh の `{{ ansible_default_ipv4.address }}`: 存在 OK
  - xbuild main.yml の `go-install` 行、bench tasks の `bench_linux_amd64`、webapp/go/Makefile の `$(LINUX_TARGET_ENV)`: 存在 OK
  - bench / frontend / envcheck のビルド対象、`application.yml`・`benchmark.yml` の実行(xbuildwebapp 削除済みでロール解決 OK)

## 注意点

- cfg の `find ... sed u.isucon.dev → u.isucon.local` は VM 内の一時 clone 全体に当たるため、本 CHANGES.md 等も VM 内では置換されるが実害なし
- frontend ビルドに Node 20 が必要だが、cfg が nodesource から一時インストールし完了後に purge する(元 cfg と同じ挙動)。webapp の node ランタイムは削除済みで、実行時に Node は不要
- 動作確認: `webapp/go` で `go build` が成功することを確認済み
