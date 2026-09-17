# ISUCON14 問題

## 当日に公開したマニュアルおよびアプリケーションについての説明

- [ISUCON14 当日マニュアル](./docs/manual.md)
- [ISUCON14 アプリケーションマニュアル](./docs/ISURIDE.md)

## ディレクトリ構成

```
.
+- bench          # ベンチマーカー
+- browsercheck   # ブラウザチェック用スクリプト
+- development    # 開発環境用のdocker compose
+- docs           # ドキュメント類
+- envcheck       # 競技環境の確認用プログラム
+- frontend       # 問題アプリケーションのフロントエンド
+- provisioning   # Ansible および Packer
+- webapp         # リファレンス実装
```

## TLS証明書について

ISUCON14で使用したTLS証明書は`provisioning/ansible/roles/nginx/files/etc/nginx/tls`以下にあります。

本証明書は有効期限が切れている可能性があります。定期的な更新については予定しておりません。

## ISUCON14で使用した競技環境

- 競技者 VM 3台
  - InstanceType: c5.large (2vCPU, 4GiB Mem)
  - VolumeType: gp3 20GB
- ベンチマーカー VM 1台
  - ECS Fargate (8vCPU, 8GB Mem)

## AWS上での過去問環境の構築方法

### 用意されたAMIを利用する場合

以下の設定で起動してください。このAMIは予告なく利用できなくなる可能性があります。
- リージョン: `ap-northeast-1`
- AMI-ID: `ami-0e334c50145a3ee41`

### 自分でAMIをビルドする場合

上記AMIが利用できなくなった場合は、`provisioning/packer`以下で`make build`を実行するとAMIをビルドできます。`hasicorp/packer`が必要です。(運営時に検証したバージョンはv1.11.2)
上記スクリプトではAnsibleを利用して環境構築を行っています。デフォルトでは、初期状態に含まれるすべての言語環境をビルドするため、時間がかかります。下記の[Ansibleでの環境構築 - 対象言語の絞り込み](#)の項目も確認してください。

### AMIからEC2を起動する場合の注意事項

- 起動に必要なEBSのサイズは最低16GBですが、ベンチマーク中にログなどが増えると溢れる可能性があるため、大きめに設定することをお勧めします(競技環境では20GiB)
- セキュリティグループは`TCP/443`、`TCP/22`を開放してください
- 適切なインスタンスプロファイルを設定することで、セッションマネージャーによる接続が可能です
- 起動時に指定したキーペアを使って`ubuntu`ユーザーでSSH接続することが可能です
  - その後`sudo su - isucon`で`isucon`ユーザーに切り替えてください

## Ansibleでの環境構築

ubuntu 24.04 の環境に対して Ansible を実行することで環境構築が可能です。

`make_latest_files.sh`ではフロントエンドおよび、ベンチマーカーのビルドが行われます。 Node.JSと、Go言語のランタイムが必要となることに注意してください。

### 競技者環境の構築

使用したいサーバーに本リポジトリを`git clone`して、以下のコマンドを実行してください。

```sh
$ cd provisioning/ansible
$ ./make_latest_files.sh # 各種ビルド
$ ansible-playbook -i inventory/localhost application.yml
```

### ベンチマーカー環境の構築

使用したいサーバーに本リポジトリを`git clone`して、以下のコマンドを実行してください。

```sh
$ cd provisioning/ansible
$ ./make_latest_files.sh # 各種ビルド
$ ansible-playbook -i inventory/localhost benchmark.yml
```

### 対象言語の絞り込み

このリポジトリはGo実装のみを含むように削ぎ落としてあります（他言語の実装・ランタイムセットアップは削除済み。詳細は`CHANGES.md`を参照）。

## docker compose での環境構築（Go言語のみ）

作問時に利用した docker compose で環境を構築することもできます。ただし、スペックやTLS証明書の有無など競技環境とは異なります。

[Task](https://taskfile.dev/)を使用するので、事前にインストールしておいてください。

### アプリケーションの起動
```
$ task up
$ task go:run
```

### 負荷走行の実行

同一サーバー内でアプリケーションを起動している場合は、以下のコマンドで負荷走行を実行できます。
```
$ cd bench
$ task run-local
```

異なるホストに向けて負荷走行を行う場合は、以下のようなコマンドで負荷走行を実行できます。
```
$ cd bench
$ go run . run --target http://{{ 対象のIPアドレス }}:{{ 対象のポート番号 }} --payment-url http://{{ 対象のホストから見たベンチマーカーのIPアドレス }}:{{ 決済サーバーのポート番号 デフォルト:12345 }} -t 60
```

ベンチマーカーは負荷走行の実行中に決済サーバーとしても動作します。`--payment-url` は問題アプリケーションへ決済サーバーのURLを通知するためのオプションです。

ベンチマーカーを競技インスタンス上で動作させる場合は、競技インスタンス上で動作しているモックサーバーのポートと被ってしまうため `--payment-bind-port` オプションを指定してポートを変更してください。

静的ファイルのチェックに失敗する場合は `--skip-static-sanity-check` オプションを追加して実行することで、チェックをスキップできます。
（ただし、静的ファイル取得のリクエストもスキップされるため本番での負荷とは厳密には一致しなくなることに注意してください。）

## Links

- [ISUCON14 まとめ](https://isucon.net/archives/58818382.html)

## Multipassでの利用方法

* [Multipass](https://multipass.run/) 実行環境を用意します
* このリポジトリを手元に用意します

  ```sh
  git clone https://github.com/Lumonde-software/isucon-go-only.git
  cd isucon-go-only
  ```

* cloud-init を使って起動します

  ```sh
  multipass launch --name isucon14 --cpus 2 --disk 20G --memory 4G --timeout 86400 --cloud-init isucon14/isucon14.cfg 24.04
  ```

  * cpus, disk, memory は必要に応じて増減させてください
  * 末尾の `24.04` は Ubuntu のバージョンです
  * cloud-init は時間がかかるため timeout のエラーが表示される場合がありますが、バックグラウンドで構築は継続しています
* 進捗は `/var/log/cloud-init-output.log` で確認できます

  ```sh
  multipass exec isucon14 -- tail -f /var/log/cloud-init-output.log
  ```

* ログインとIPアドレスの確認

  ```sh
  multipass shell isucon14
  multipass info isucon14
  ```

* 環境の停止・再開・削除

  ```sh
  multipass stop isucon14
  multipass start isucon14
  multipass delete --purge isucon14
  ```

ベンチマークの実行方法など詳細は同ディレクトリの README.cloud-init.md を参照してください。
