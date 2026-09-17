# nri-isucon2022

## Overview

2022年2月に開催したNRI-ISUCON 2022で使用されたプログラムです。

## 競技を実施してみる

- [Vagrantで競技を体験する](./docs/vagrant.md)

## コンテスト実施時のインスタンスタイプ

| # | type | vCPU | Memory(GiB) |
| -- | -- | -- | -- |
| 1 | t3.small | 2 | 2.0 |
| 2 | t2.small | 1 | 2.0 |
| 3 | t2.small | 1 | 2.0 |

## 商標表示

「ISUCON」は、LINE株式会社の商標または登録商標です。
https://isucon.net/

## 免責事項

このレポジトリのファイルは有志の運営メンバーによって提供されています。
株式会社野村総合研究所はあらゆる保証を提供しません。

## Multipassでの利用方法

* [Multipass](https://multipass.run/) 実行環境を用意します
* このリポジトリを手元に用意します

  ```sh
  git clone https://github.com/Lumonde-software/isucon-go-only.git
  cd isucon-go-only
  ```

* cloud-init を使って起動します

  ```sh
  multipass launch --name nri-isucon2022 --cpus 2 --disk 20G --memory 4G --timeout 86400 --cloud-init nri-isucon2022/nri-isucon2022.cfg 18.04
  ```

  * cpus, disk, memory は必要に応じて増減させてください
  * 末尾の `18.04` は Ubuntu のバージョンです
  * cloud-init は時間がかかるため timeout のエラーが表示される場合がありますが、バックグラウンドで構築は継続しています
* 進捗は `/var/log/cloud-init-output.log` で確認できます

  ```sh
  multipass exec nri-isucon2022 -- tail -f /var/log/cloud-init-output.log
  ```

* ログインとIPアドレスの確認

  ```sh
  multipass shell nri-isucon2022
  multipass info nri-isucon2022
  ```

* 環境の停止・再開・削除

  ```sh
  multipass stop nri-isucon2022
  multipass start nri-isucon2022
  multipass delete --purge nri-isucon2022
  ```

ベンチマークの実行方法など詳細は同ディレクトリの README.cloud-init.md を参照してください。

注意: オリジナルの前提は Ubuntu 18.04 ですが、Multipass では 18.04 イメージが入手できない場合があります(`multipass find` で確認)。またベンチマーカーは x86-64 バイナリ配布のため Apple Silicon では動きません。
