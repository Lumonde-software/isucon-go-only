# CHANGES

isucon11f(ISUCON11 本選)を Go 実装のみに削ぎ落としてモノレポ配置した際の変更記録。

## 元リポジトリ

- https://github.com/isucon/isucon11-final.git
- ブランチ: main(デフォルト)
- コミット: 7f9477d5c844e9772e865fc7e89ef2acbc8f1c3c(--depth=1 clone 時点)

## 削除したもの(Go 以外の言語実装とその専用セットアップ)

- `webapp/nodejs/`, `webapp/php/`, `webapp/ruby/`, `webapp/rust/`
- `dev/nodejs/`, `dev/php/`, `dev/ruby/`, `dev/rust/`
- `dev/docker-compose-nodejs.yaml`, `dev/docker-compose-php.yaml`, `dev/docker-compose-ruby.yaml`, `dev/docker-compose-rust.yaml`
- `provisioning/ansible/roles/langs.nodejs/`, `langs.php/`, `langs.ruby/`, `langs.rust/`
- `provisioning/ansible/roles/contestant/tasks/isucholar-nodejs.yml`, `isucholar-php.yml`, `isucholar-ruby.yml`, `isucholar-rust.yml`
- `provisioning/ansible/roles/contestant/files/etc/systemd/system/isucholar.nodejs.service`, `isucholar.php.service`, `isucholar.ruby.service`, `isucholar.rust.service`
- `provisioning/ansible/roles/contestant/files/etc/nginx/sites-available/isucholar-php.conf`
- `provisioning/ansible/roles/contestant/files/home/isucon/local/php/`(php-fpm 設定)
- `.github_/workflows/nodejs.yaml`, `php.yaml`, `ruby.yaml`, `rust.yaml`(CI。上流でも `.github_` にリネーム済みで無効)
- `.git`(コピーせず)

## 参照修正した箇所

- `provisioning/ansible/site.yml`: contestant roles から `langs.rust` / `langs.nodejs` / `langs.ruby` / `langs.php` を削除(`langs.go` のみ残す)
- `provisioning/ansible/roles/contestant/tasks/isucholar.yml`: `isucholar-nodejs.yml` / `isucholar-rust.yml` / `isucholar-php.yml` / `isucholar-ruby.yml` の include を削除(`isucholar-go.yml` のみ残す)
- `provisioning/ansible/roles/contestant/tasks/nginx.yml`: デプロイ対象から `etc/nginx/sites-available/isucholar-php.conf` を削除
- `.github_/label-path-mapping.yaml`: `transplant` ラベル(webapp/{nodejs,php,ruby,rust} へのパスマッピング)を削除

デフォルト実装は元々 Go(`isucholar.go.service` を enable、nginx も isucholar.conf のみ有効)のため、切り替えの焼き込みは不要。

## 意図的に残したもの

- `docs/manual.md` 等のドキュメント内の他言語への言及(当日マニュアルの忠実性を優先)
- `benchmarker/tools/gen_user_data.rb`(ベンチマーカー付属のデータ生成ツールで webapp 実装ではない)
- `provisioning/terraform-dev/contestant.tf` 内の "ruby" 等の文字列(開発環境のインスタンス名で言語セットアップではない)
- `provisioning/packer`, `terraform-*`(cloud-init 構築では未使用だが忠実性のため残置)

## isucon11f.cfg の変更点(元: cloud-init-isucon/isucon11f/isucon11f.cfg)

1. git clone 部分を isucon-go-only モノレポの sparse-checkout 方式に書き換え(GITDIR=`/tmp/isucon11-final` は元のまま):
   clone → `sparse-checkout set isucon11f` → `mv` で GITDIR へ配置 → clone 元を削除
2. REVISION 生成の移動: 元 cfg はサブシェル内で `git rev-parse HEAD > /dev/shm/files-generated/REVISION` を実行していたが、mv 後の GITDIR は git リポジトリではなくなるため `set -e` で構築が失敗する。`rm -rf /tmp/isucon-go-only` の直前(clone 元がまだある時点)で `git -C /tmp/isucon-go-only rev-parse HEAD` を実行する形に移動し、`mkdir -p /dev/shm/files-generated` も併せて移動。REVISION にはモノレポのコミットハッシュが入る
3. それ以外(sed 群・openssl・ansible-playbook・CA 登録・`systemctl restart isucholar.go`)は元のまま

### sed / パッチの成立性確認(削ぎ落とし後のツリーに対して)

| 対象 | パターン | 結果 |
|---|---|---|
| `roles/common/tasks/main.yml` | `Unarchive` ブロック削除、`Create /tmp/isucon11-final` への recurse 追加 | 成立(ファイル無改変) |
| `benchmarker/main.go` | `InsecureSkipVerify` 行(L66)を true に | 成立(ファイル無改変) |
| `roles/bench/tasks/bench.yml` | `Deploy isucon11-final benchmarker"` の前に make ビルド挿入、`/dev/shm/files-generated` → `/tmp/isucon11-final/benchmarker/bin` 置換 | 成立(ファイル無改変、マッチは1箇所のみ) |
| `roles/langs.go/tasks/main.yml` | `go-install` 行に OS/arch 追記 | 成立(ファイル無改変) |
| `roles/contestant/files/etc/nginx/certificates/` | openssl による証明書生成先 | ディレクトリ存置を確認 |
| `systemctl restart isucholar.go` | サービス | `isucholar.go.service` 存置・isucholar.yml で enable を確認 |

## 注意点

- `benchmarker/Makefile` の `DIRTY=$(shell git diff --quiet || echo '+dirty')` は、構築先の `/tmp/isucon11-final` が git リポジトリでないため常に `+dirty` になる(バージョン表示のみの cosmetic な差分。COMMIT 自体は `/etc/REVISION` から取得され正常)
- `.github_/` は上流時点で無効化(リネーム)されている CI 設定。go/frontend/bench/packer 分のみ残した
- 動作要件(Ubuntu 20.04、メモリ 2GB 以上等)は `README.cloud-init.md` を参照
