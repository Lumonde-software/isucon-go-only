# CHANGES (go-only 化の変更記録)

## 元リポジトリ

- https://github.com/matsuu/isucon11-prior.git
- ブランチ: `support-non-amd64-arch`(`--depth=1` で取得、2026-09-17 時点)
- `.git` は含めずファイルツリーのみ配置

## 削除したもの

- `webapp/ruby/`(Ruby 参考実装。オリジナルのデフォルト実装)
- `webapp/nodejs/`, `webapp/perl/`, `webapp/php/`, `webapp/python/`(他言語参考実装)
- `infra/instance/cookbooks/ruby/`(isucon ユーザー用 Ruby 3.0.1 ビルドの cookbook)
- `infra/instance/cookbooks/webapp/files/etc/systemd/system/web-ruby.service`

rust 実装は元リポジトリに存在しない。`webapp/frontend/`(React フロントエンド)と
`infra/instance/cookbooks/nodejs/`(node + yarn)はフロントエンドのビルドに必要なため残した。
`infra/esxi/` と `infra/instance/apply.rb` の `bundle exec itamae` は運用側マシンで使う
ツールなのでそのまま(ターゲット環境の Ruby とは無関係)。

## 参照修正した箇所

- `infra/instance/recipe.rb`: `include_cookbook 'ruby'` を削除
- `infra/instance/cookbooks/webapp/default.rb`: Go デフォルト化
  - web-ruby 関連(service ファイル配布・enable/start・bundle install 群)を削除
  - `service 'web-golang'` を `[:disable, :stop]` → `[:enable, :start]` に変更
  - Go ビルド `execute '/home/isucon/.x make build'` の `only_if 'test -x .../bin/webapp'` を撤去し
    毎回実行に変更(オリジナルはバイナリが既にある時しかビルドせず、Go デフォルトでは初回起動に必要)。
    service 定義より前に実行される
  - `install webapp` の restart 通知先を web-ruby → web-golang に変更
- `infra/instance/cookbooks/repository/default.rb`: clone 元をモノレポに変更(下記)
- `infra/instance/cookbooks/xbuild/files/home/isucon/.local.env`: perl/php/ruby の PATH 行を削除
- `webapp/tools/restart-and-bench`: `systemctl restart web-ruby` → `web-golang`
- `webapp/tools/switch-lang`: golang のみに簡略化
- `webapp/README.md`: 実装一覧を golang のみに更新
- `webapp/doc/MANUAL.md`: 「デフォルトでは Ruby の実装が起動」→ Go に修正

nginx の upstream は 127.0.0.1:9292 のままで変更不要(Go 実装も 9292 で listen する)。

## repository cookbook の変更(重要)

オリジナルはプロビジョニング中に https://github.com/isucon/isucon11-prior.git を
`/home/isuadmin/src/isucon11-prior` へ clone し、`git pull` ベースの
`update repository` で REVISION を生成していた。go-only 版では:

- clone 元を `https://github.com/Lumonde-software/isucon-go-only.git` の sparse checkout
  (`isucon11-prior` サブディレクトリ)に変更し、`mv` で同じパスへ配置
- `mv` 後は git リポジトリでなくなるため `update repository`(git pull / checkout origin/main)を削除。
  代わりに clone 時に `git rev-parse HEAD` で `REVISION` ファイルを生成
  (benchmarker の `-version` 埋め込みと webapp コピーの冪等判定に使用)
- `build frontend` の通知元を `update repository` → `clone repository` に変更

## cfg (isucon11-prior.cfg) の変更点

参考にした cloud-init-isucon の cfg から、git clone 部分のみ以下に変更。GITDIR は元の
`/tmp/isucon11-prior` を維持:

- `git clone --depth=1 -b support-non-amd64-arch matsuu/isucon11-prior` →
  Lumonde-software/isucon-go-only を `--depth=1 --filter=blob:none --sparse` で
  `/tmp/isucon-go-only` に clone し、`sparse-checkout set isucon11-prior` 後に
  `mv` で `${GITDIR}` へ配置

cfg 内の sed 2 箇所は削ぎ落とし後も成立することを確認済み:

- `sed -i 's/apt upgrade -y/true/' cookbooks/apt/default.rb` → 対象行あり(default.rb:5)
- `sed -i "s/include_cookbook 'systemd-timesyncd'//" recipe.rb` → 対象行あり(recipe.rb:20)

## Ubuntu 22.04対応

Ubuntu 22.04 (jammy) でプロビジョニングできるよう以下を修正(静的確認のみ、実機検証は未実施):

- `infra/instance/cookbooks/redis/default.rb`: `add-apt-repository -y ppa:redislabs/redis` を削除し、
  ディストリ標準の `package 'redis'` のみに変更(isucon11q の mariadb バージョン無指定化と同じ方針)
  - 理由: PPA 追加の冪等判定が `redislabs-ubuntu-redis-focal.list` と focal 決め打ちで、
    22.04 では毎回 PPA 追加が走る上、PPA の jammy 対応も保証できない
  - jammy の universe に redis 6.0.16 があり(20.04 でも redis 5.0 が入るので後方互換)、
    redis は webapp からは未使用(netdata の監視対象のみ)のためバージョン差の影響なし
- `isucon11-prior.cfg`: `ln -s /usr/share/keyrings /etc/apt/keyrings` を
  `[ -e /etc/apt/keyrings ] || ln -s ...` に変更
  - `/etc/apt/keyrings` が既に存在する環境(新しめの image)では `ln -s` が失敗し
    `set -e` で runcmd 全体が中断するため
- `README.md`: Multipass 起動例を `20.04` → `22.04` に変更
  (README.cloud-init.md の Requirements の 20.04 記述は参考資料のためそのまま)

修正不要と確認した箇所:

- itamae: cfg は apt パッケージ `itamae` でインストールしており、jammy universe に 1.12.5 が存在
- MySQL: パッケージ名は既に `mysql-server-8.0` 系で jammy に存在。ユーザー作成も
  `CREATE USER ... IDENTIFIED WITH mysql_native_password` + `GRANT` 分離形式
  (8.0 で廃止された `GRANT ... IDENTIFIED BY` は未使用)。mysql/netdata 両 cookbook とも同形式。
  jammy の MySQL 8.0 では mysql_native_password プラグインは利用可能
- nodejs: nodesource ではなく xbuild による node v16.3.0 バイナリ導入で、jammy の glibc 要件を満たす
- python2 前提・apt-key 使用箇所: なし
- netdata / python3-mysqldb / dstat / libmysqlclient-dev: jammy に存在
- speedtest: Ookla の install.deb.sh はディストリを自動判定し jammy に対応

22.04 で未修正の注意点:

- `cookbooks/alp/default.rb` は `alp_linux_amd64.zip` 決め打ち。arm64 環境(Apple Silicon の
  Multipass 等)ではプロビジョニング自体は成功するが alp バイナリが動作しない(20.04 でも同様の
  既存問題で、22.04 固有ではないため未修正)
- `cookbooks/nodejs/default.rb` の yarn インストールは `https://yarnpkg.com/install.sh` を実行する
  外部スクリプト依存(classic yarn)。OS バージョンに依存しないが、将来の提供終了リスクあり
- `cookbooks/resolv/` の netplan 設定は `ens160`(ESXi 向け NIC 名)決め打ち。Multipass では
  該当 NIC が無くても netplan apply は失敗しない(既存挙動のまま)

## 注意点

- `webapp/golang/public` は `../frontend/dist` へのシンボリックリンク。コミット時に
  シンボリックリンクとして保持されること(dist 自体は .gitignore 対象で、プロビジョニング時に
  yarn build で生成される)
- `webapp/golang/bin` は .gitignore 対象。Go バイナリはプロビジョニング時に
  `make build` でビルドされる
- ベンチ実行は `sudo su - isucon` 後 `./bin/benchmarker`(README.cloud-init.md 参照)
- sparse checkout は git 2.25(Ubuntu 20.04 標準)以上が必要
- アプリコードのチューニングは行っていない(忠実な go-only 化のみ)
