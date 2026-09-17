# CHANGES

isucon12q(ISUCON12 予選)を Go 実装のみに削ぎ落としてモノレポに配置した際の変更記録。

## 元リポジトリ

- https://github.com/isucon/isucon12-qualify.git
- ブランチ: main(デフォルト)、commit `95958774bde66d47fd26cc820fd2fbfbece798f1`(--depth=1 で取得)
- `.git` はコピーしていない

## 削除したもの

- `webapp/{java,node,perl,php,python,ruby,rust}/`(Go 以外の言語実装)
- `webapp/docker-compose-{java,node,perl,php,python,ruby,rust}.yml`
- `development/backend-{java,node,perl,php,python,ruby,rust}/`
- `development/docker-compose-{java,node,perl,php,python,ruby,rust}.yml`
- `.github_/workflows/{java,node,perl,php,python,ruby,rust}.yml` と `rust.yaml`(言語別 CI。`go.yml` / `go-bench-test.yml` / `data.yml` / `sync-webapp-diff-branch.yml` は残置)
- `provisioning/mitamae/cookbooks/nginx/isuports-php.conf`(PHP 専用 nginx vhost。sites-available に置かれるだけで enable はされていなかった)

## 参照修正した箇所

- `provisioning/mitamae/cookbooks/nginx/default.rb`: isuports-php.conf を配布する remote_file ブロックを削除
- `provisioning/mitamae/cookbooks/webapp/build.rb`: 言語リストを `%w[go]` に縮小(コメントアウト済みの build ブロック、および `/home/isucon/tmp/<lang>` ディレクトリ作成の両方)

デフォルト実装はもともと Go(`cookbooks/webapp/isuports.service` が `docker-compose-go.yml` を起動、ルート `docker-compose.yml` も `./webapp/go` をビルド)のため、デフォルト切り替えの焼き込みは不要だった。

## isucon12q.cfg の変更点

ベース: matsuu/cloud-init-isucon の isucon12q.cfg。

1. git clone 部分を isucon-go-only モノレポの sparse checkout に置き換え(GITDIR は元の `/tmp/isucon12-qualify` を維持):
   `git clone --depth=1 --filter=blob:none --sparse https://github.com/Lumonde-software/isucon-go-only.git` →
   `sparse-checkout set isucon12q` → `mv` で GITDIR へ
2. 非 x86_64 向けの `sed -i -e "s/mysql-client/default-mysql-client/" ${GITDIR}/webapp/*/Dockerfile` を削除。
   現行の `webapp/go/Dockerfile` は既に `default-mysql-client` を使っており、この sed を残すと
   `default-default-mysql-client` に化けて ARM で docker build が壊れる(上流 cfg にもある潜在バグ)。

その他の sed / コマンドは削ぎ落とし後のツリーに対して成立することを確認済み:

- `cookbooks/users/isucon.rb` の `x86_64`(docker-compose バイナリ URL)あり
- `cookbooks/common/default.rb` の `192.168`(hosts 定義)あり
- `docker-compose.yml` / `frontend/src/views/admin/AdminView.vue` / `frontend/vue.config.js` の `t.isucon.dev` / `powawa.net` あり
- `bench` / `public` / `webapp` / `provisioning` への find+sed 対象ディレクトリあり
- `webapp/sql/admin/*.sql`、`webapp/sql/init.sh`、`bench/Makefile`、`blackauth/`、`cookbooks/nginx/tls/` あり
- `roles/default.rb` / `roles/webapp.rb` が参照する cookbook は全て残存

## 注意点

- `development/` は上流時点でメンテナンス停止と明記されたディレクトリ。Makefile はパターンルール(`up/%` など)のため Go 以外のターゲット定義は残っていないが、README には「各言語実装」への言及が残る(実体は backend-go のみ)
- `README.md`(上流由来)には他言語移植に関する記述が一部残っている(歴史的記述のためそのまま)
- 初期データは cfg が上流 isucon/isucon12-qualify の GitHub Releases から取得する(この参照は意図的に変更していない)
- `README.cloud-init.md` は matsuu/cloud-init-isucon の isucon12q/README.md のコピー
