# isucon11-qualify

## ディレクトリ構成

```
.
├── webapp       # 各言語の参考実装
├── docs         # 競技用マニュアル
├── bench        # ベンチマーカー
├── provisioning # セットアップ用
├── development  # 開発用資材置場
└── extra        # その他のファイル
```

## JWT で利用する公開鍵・秘密鍵

ISUCON11 予選ではウェブアプリケーションのログインに JWT を利用しています。
JWT を生成・検証するための公開鍵・秘密鍵はそれぞれ以下に配置されています。

* bench/key/ec256-private.pem
* bench/key/ec256-public.pem
* webapp/ec256-public.pem (bench/key/ec256-public.pemのコピー)
* extra/jiaapi-mock/ec256-private.pem (bench/key/ec256-private.pemのコピー)

## ISUCON11 予選のインスタンスタイプ

* 競技者 VM * 3
    * InstanceType: c5.large
    * VolumeType: gp3 (20GB)
* ベンチ VM * 1
    * InstanceType: c4.xlarge
    * VolumeType: gp3 (20GB)

## AWS 上での過去問環境の構築方法

### 用意された AMI を利用する場合

[provisioning/cf-kakomon](./provisioning/cf-kakomon) を参照してください。なお AMI は ISUCON11 運営の解散を目処に公開を停止する予定です。上記イメージが参照不可である場合ひとつ下の手順で構築してください。

### AMI を自前で作成し構築する場合

手順準備中です。

#### git リポジトリに含まれていないファイルの配布

https://github.com/isucon/isucon11-qualify/releases/tag/public から取得できます

## Links

- [ISUCON11 予選レギュレーション](https://isucon.net/archives/55854734.html)
- [ISUCON11 予選当日マニュアル](./docs/manual.md)
- [ISUCON11 予選問題の解説と講評](https://isucon.net/archives/56044867.html)
- [ISUCON11 予選問題実践攻略法](https://isucon.net/archives/56082639.html)

## Multipassでの利用方法

* [Multipass](https://multipass.run/) 実行環境を用意します
* このリポジトリを手元に用意します

  ```sh
  git clone https://github.com/Lumonde-software/isucon-go-only.git
  cd isucon-go-only
  ```

* cloud-init を使って起動します

  ```sh
  multipass launch --name isucon11q --cpus 2 --disk 20G --memory 4G --timeout 86400 --cloud-init isucon11q/isucon11q.cfg 22.04
  ```

  * cpus, disk, memory は必要に応じて増減させてください
  * 末尾の `22.04` は Ubuntu のバージョンです
  * cloud-init は時間がかかるため timeout のエラーが表示される場合がありますが、バックグラウンドで構築は継続しています
* 進捗は `/var/log/cloud-init-output.log` で確認できます

  ```sh
  multipass exec isucon11q -- tail -f /var/log/cloud-init-output.log
  ```

* ログインとIPアドレスの確認

  ```sh
  multipass shell isucon11q
  multipass info isucon11q
  ```

* 環境の停止・再開・削除

  ```sh
  multipass stop isucon11q
  multipass start isucon11q
  multipass delete --purge isucon11q
  ```

ベンチマークの実行方法など詳細は同ディレクトリの README.cloud-init.md を参照してください。

注意: この go-only 版は Ubuntu 22.04 対応済みです(MariaDB のバージョン指定を撤廃済み。オリジナルの推奨は 20.04)。
