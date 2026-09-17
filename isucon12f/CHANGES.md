# CHANGES.md — isucon12f (Go実装のみへの削ぎ落とし)

## 元リポジトリ

- https://github.com/isucon/isucon12-final.git
- ブランチ: main(デフォルト)、コミット: d31d92c7f0df9fa1559270ffb9481ec8a610edf0(2026-09-17 に --depth=1 で取得)
- `.git` はコピーしていない

## 削除したもの

### webapp 配下の他言語実装

- `webapp/node/`
- `webapp/perl/`
- `webapp/php/`
- `webapp/ruby/`
- `webapp/rust/`

`webapp/admin/`(管理画面のビルド済み dist。nginx が `/home/isucon/webapp/admin/dist` を配信するため必須)、`webapp/frontend/`(Unity クライアント)、`webapp/sql/` は残した。

### ansible(provisioning/packer/ansible)

- `roles/xbuildwebapp/` 全体(Rust/Node.js/Perl/Ruby/PHP のランタイムインストール role)
- `roles/webapp/files/etc/systemd/system/isuconquest.{nodejs,perl,php,ruby,rust}.service`
- `roles/webapp/files/etc/nginx/sites-available/isuconquest-php.conf`
- `roles/webapp/files/home/isucon/local/`(php-fpm 設定 `isuconquest.php-fpm.conf` のみだったためディレクトリごと)

### 削除しなかったもの(判断メモ)

- `roles/apt/` のパッケージ一覧: libonig/libtidy 等 PHP/Ruby ビルド向けの依存を多く含むが、汎用ビルドパッケージと混在しており削って壊すリスクを避けるためそのまま残した(余分に入るだけで無害)
- `docs/`, `isucon12-portal/`, `benchmarker/`, `dev/`: 言語実装ではないためそのまま
- ルート `README.md` 内の他言語への言及: ドキュメントのため未修正
- docker-compose・CI(.github)は元リポジトリに存在しない

## 参照修正した箇所

- `provisioning/packer/ansible/base.yml`: `xbuildwebapp` role の import を削除
- `provisioning/packer/ansible/roles/webapp/tasks/main.yml`:
  - Copy files の with_items から削除済みファイル(他言語 systemd unit・isuconquest-php.conf・php-fpm conf)を除去
  - Build rust application / Clone ext-apfd / ext-apfd build / composer install(php)/ npm install(node)/ cpm permission・cpm install(perl)/ bundle install(ruby)の各タスクを削除
  - 「Enable isuconquest.go.service」はもともと Go を有効化する内容のためそのまま(デフォルトが Go なので切り替えの焼き込みは不要)
- `provisioning/packer/ansible/roles/repository/tasks/main.yml`: `/home/isucon/isucon12-final` への clone 元を isucon/isucon12-final から本モノレポ(Lumonde-software/isucon-go-only の isucon12f を sparse-checkout して mv)に変更。ansible の git モジュールは sparse 非対応のため shell タスク化
- `provisioning/packer/ansible/roles/xbuild/files/home/isucon/.local.env`: golang の PATH 行のみ残し、node/cargo/php/ruby/perl の PATH 行を削除
- `provisioning/packer/ansible/roles/xbuild/files/home/isucon/env`: `PERL5LIB=...` 行を削除

## isucon12f.cfg の変更点

元 cfg(cloud-init-isucon/isucon12f/isucon12f.cfg)からの差分は git clone 部分のみ:

- `git clone --depth=1 https://github.com/isucon/isucon12-final.git ${GITDIR}` を、Lumonde-software/isucon-go-only を `--depth=1 --filter=blob:none --sparse` で clone → `sparse-checkout set isucon12f` → `mv` で `${GITDIR}` に配置する形に変更
- `GITDIR="/tmp/isucon12-final"` は元の値のまま維持
- それ以外(make initial-data、sed、ansible-playbook、ansible purge、サービス再起動)は元のまま

### cfg 内の sed・パッチの成立確認

- `sed -i -e "/go-install/s/$/ <os> <arch>/" roles/xbuild/tasks/main.yml`: 削ぎ落とし後の `roles/xbuild/tasks/main.yml` に `go-install` 行(`cmd: /opt/xbuild/go-install 1.19 /home/isucon/local/golang`)が 1 箇所存在し、適用確認済み
- cfg 内の sed はこの 1 つのみ。他のパッチはなし

## 注意点

- `dev/make initial-data` は元リポジトリの GitHub Releases(isucon/isucon12-final の initial_data_20220912)から初期データを wget する。この参照は意図的に元のまま
- ansible の repository role は application.yml と benchmarker.yml の双方から import され 2 回実行されるが、毎回 rm -rf → clone し直すため冪等(元リポジトリと同じ挙動)
- README.cloud-init.md の FAQ に記載の drawGacha 404 バグ(gacha_masters の end_at 条件)は元コードのまま残している(アプリコードの改変はしない方針)。必要なら FAQ 記載の Go 向けパッチを手で適用すること
- `webapp/admin/.env` が含まれる(Vite 用のビルド設定ファイル。内容は未確認のままコピー)
