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

## 注意点

- `webapp/golang/public` は `../frontend/dist` へのシンボリックリンク。コミット時に
  シンボリックリンクとして保持されること(dist 自体は .gitignore 対象で、プロビジョニング時に
  yarn build で生成される)
- `webapp/golang/bin` は .gitignore 対象。Go バイナリはプロビジョニング時に
  `make build` でビルドされる
- ベンチ実行は `sudo su - isucon` 後 `./bin/benchmarker`(README.cloud-init.md 参照)
- sparse checkout は git 2.25(Ubuntu 20.04 標準)以上が必要
- アプリコードのチューニングは行っていない(忠実な go-only 化のみ)
