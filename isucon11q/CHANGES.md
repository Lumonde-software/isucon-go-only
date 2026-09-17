# go-only ブランチの変更記録

main(1011682c)をベースに、Go 実装だけで練習・ベンチ実行できる最小構成へ削ぎ落とした。

## 方針

- 残す: `webapp/go`・`webapp/sql`・`webapp/public`・`webapp/frontend`・webapp 直下の共通ファイル、`bench`、`docs`、`extra`、development の Go/MySQL/jiaapi-mock 構成、provisioning の Go 実行に必要な部分
- 削る: Go 以外の言語実装と、その言語のためだけに存在するセットアップ(ランタイムインストール、systemd unit、docker-compose サービス、CI)

## 削除したもの(コミット 638bf454, ba26a48e)

- `webapp/{nodejs,perl,php,python,ruby,rust}`
- `development/backend-{nodejs,perl,php,python,ruby,rust}`
- `provisioning/ansible/roles/langs.{nodejs,perl,php,python,ruby,rust}`
- `provisioning/ansible/roles/contestant/tasks/isucondition-{nodejs,perl,php,python,ruby,rust}.yml`
- `provisioning/ansible/roles/contestant/files/etc/systemd/system/isucondition.{nodejs,perl,php,python,ruby,rust}.service`
- `provisioning/ansible/roles/contestant/files/etc/nginx/sites-available/isucondition-php.conf` と `files/home/isucon/local/php`(php-fpm 設定)
- `.github_/workflows/{nodejs,perl,php,python,ruby,rust}.yml`

## 参照の後始末

- `development/Makefile`: 他言語の `up-*` / `test-*` ターゲットを削除
- `development/docker-compose-dev.yml`: backend-go / mysql-backend / jiaapi-mock のみに整理、rust-target volume を削除
- `provisioning/ansible/site.yml`: 各プレイから `langs.<他言語>` ロールを削除(`langs.go` と、Go のインストールに使う xbuild は維持)
- `provisioning/ansible/roles/contestant/tasks/isucondition.yml`: 他言語タスクの include と systemd unit 配布を削除
- `provisioning/ansible/roles/contestant/tasks/nginx.yml`: isucondition-php.conf の配布行を削除
- `.dockerignore`: rust/nodejs/php の ignore 行を削除
- `.github_/label-path-mapping.yml`: 他言語パスの transplant ラベルを削除

## 残置(意図的に触っていないもの)

- `docs/manual.md` 内の言語切替に関する記述(ドキュメントのため)
- `timezone.yml` 等のシェルワンライナーの `perl -pi -e`(システムの perl を使うだけで、言語セットアップとは無関係)
- 各種 `.pem` ファイル(ベンチ用テスト鍵)

## 動作確認

- `webapp/go` で `go build` が成功することを確認済み

## 環境構築まわりの追加変更

- **aarch64 対応**(aeb8eed5): `langs.go` の go-install に OS/アーキテクチャ引数を追加。matsuu/aarch64 ブランチと upstream main の実質的な差分はこの1行のみだったため、これで arm64/x86 両対応
- **cloud-config 追加**(036451c3): `isucon11q.cfg`。go-only ブランチを clone してスタンドアロン練習環境を構築する。初期データ・画像は isucon 公式リリースから取得
- **Ubuntu 22.04 対応**(979b9caf): 22.04 に `mariadb-server-10.3` が存在しないため、パッケージのバージョン指定を撤廃(22.04 では MariaDB 10.6 が入る)
  - 本番当時は 10.3 だが、10.6 のまま進める方針とした。ボトルネック(インデックス・N+1等)の練習価値は変わらない一方、オプティマイザの世代差で EXPLAIN の結果や遅いクエリの「壊れ方」が本番より軽く出る可能性はある
  - 忠実さが必要になった場合は Docker で `mariadb:10.3` コンテナを立てる構成に切り替える
  - `50-server.cnf` の `[mariadb-10.3]` セクションはバージョン不一致時は無視されるため残置。10.3 の mysqldump 形式初期データも 10.6 でそのまま読める
- **isucon-go-only モノレポへの移設**: Lumonde-software/isucon11-qualify の go-only ブランチの内容を `isucon11q/` に取り込み。`isucon11q.cfg` の clone 部分をモノレポの sparse checkout(`isucon11q` ディレクトリのみ取得して `/tmp/isucon11-qualify` へ配置)に変更
