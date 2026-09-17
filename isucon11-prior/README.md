# isucon11-prior (go-only)

ISUCON11事前講習の問題を Go 実装のみに削ぎ落としたもの。元は [isucon/isucon11-prior](https://github.com/isucon/isucon11-prior)([matsuu/isucon11-prior](https://github.com/matsuu/isucon11-prior) の support-non-amd64-arch ブランチ由来)。変更内容は CHANGES.md を参照。

## Multipassでの利用方法

* [Multipass](https://multipass.run/) 実行環境を用意します
* このリポジトリを手元に用意します

  ```sh
  git clone https://github.com/Lumonde-software/isucon-go-only.git
  cd isucon-go-only
  ```

* cloud-init を使って起動します

  ```sh
  multipass launch --name isucon11-prior --cpus 2 --disk 20G --memory 4G --timeout 86400 --cloud-init isucon11-prior/isucon11-prior.cfg 20.04
  ```

  * cpus, disk, memory は必要に応じて増減させてください
  * 末尾の `20.04` は Ubuntu のバージョンです
  * cloud-init は時間がかかるため timeout のエラーが表示される場合がありますが、バックグラウンドで構築は継続しています
* 進捗は `/var/log/cloud-init-output.log` で確認できます

  ```sh
  multipass exec isucon11-prior -- tail -f /var/log/cloud-init-output.log
  ```

* ログインとIPアドレスの確認

  ```sh
  multipass shell isucon11-prior
  multipass info isucon11-prior
  ```

* 環境の停止・再開・削除

  ```sh
  multipass stop isucon11-prior
  multipass start isucon11-prior
  multipass delete --purge isucon11-prior
  ```

ベンチマークの実行方法など詳細は同ディレクトリの README.cloud-init.md を参照してください。
