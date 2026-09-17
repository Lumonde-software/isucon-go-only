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
