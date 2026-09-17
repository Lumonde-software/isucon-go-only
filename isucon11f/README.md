# ISUCHOLAR - isucon11-final

## ディレクトリ構成

競技用サーバーにはwebapp以下が配布されます。

```
.
├── benchmarker   # ベンチマーカー
├── dev           # 開発用設定ファイル等
├── docs          # 当日マニュアル等
├── provisioning  # デプロイスクリプト
└── webapp        # 各参考実装
```

## ISUCON11 本選の競技環境について

### マシンスペック

+ ベンチマーカー
  + インスタンスタイプ: c5.xlarge
  +  EBS: gp3 20GB
+ 競技用サーバー 3台
  + インスタンスタイプ: c5.large
  +  EBS: gp3 30GB

ただし、競技用サーバーのメモリは元の 4GB から 2GB に制限されています。

### Prerequirements

+ ベンチマーカー
  + Go
+ webapp
  + 各種実装言語
  + zip コマンド

### 負荷走行の実行

```
cd benchmarker
make
./bin/benchmarker -target {対象 IP アドレス}
```

## Multipassでの利用方法

* [Multipass](https://multipass.run/) 実行環境を用意します
* このリポジトリを手元に用意します

  ```sh
  git clone https://github.com/Lumonde-software/isucon-go-only.git
  cd isucon-go-only
  ```

* cloud-init を使って起動します

  ```sh
  multipass launch --name isucon11f --cpus 2 --disk 20G --memory 4G --timeout 86400 --cloud-init isucon11f/isucon11f.cfg 20.04
  ```

  * cpus, disk, memory は必要に応じて増減させてください
  * 末尾の `20.04` は Ubuntu のバージョンです
  * cloud-init は時間がかかるため timeout のエラーが表示される場合がありますが、バックグラウンドで構築は継続しています
* 進捗は `/var/log/cloud-init-output.log` で確認できます

  ```sh
  multipass exec isucon11f -- tail -f /var/log/cloud-init-output.log
  ```

* ログインとIPアドレスの確認

  ```sh
  multipass shell isucon11f
  multipass info isucon11f
  ```

* 環境の停止・再開・削除

  ```sh
  multipass stop isucon11f
  multipass start isucon11f
  multipass delete --purge isucon11f
  ```

ベンチマークの実行方法など詳細は同ディレクトリの README.cloud-init.md を参照してください。
