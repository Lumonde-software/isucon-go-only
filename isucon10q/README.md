# isucon10-qualify

## ディレクトリ構成

```
.
├── bench           # ベンチマーカー
├── initial-data    # 初期データの生成
├── provisioning    # セットアップ用
└── webapp          # Go の参考実装(Go-only 版)
```

## 問題の起動方法

1. `initial-data` で初期データを生成する
2. `webapp` で Docker を用いて問題サーバーを立ち上げる
3. `bench` で問題サーバーへのベンチマークを実行する

実際のコマンド例については、各ディレクトリの README を参照してください。


## 使用データの取得元

- [Faker](https://faker.readthedocs.io/)
- [いらすとや](https://www.irasutoya.com/)

## ISUCON10 予選のインフラ構成について

- 問題用 (3台)
    - CPU: 1 Core (AMD EPYC 7352)
    - Memory: 2 GiB
    - IO throughput: 100 Mbps
    - IOPS limit: 200 (Read / Write)
    - Interface: 1 Gbps
- ベンチマーカ用 (1台)
    - CPU: 1 Core  (AMD EPYC 7352)
    - Memory: 16 GiB
    - IO throughput: 100 Mbps
    - IOPS limit: 200 (Read / Write)
    - Interface: 100 Mbps

## Links

- [ISUCON10 予選レギュレーション](http://isucon.net/archives/54753430.html)
- [ISUCON10 予選当日マニュアル](https://gist.github.com/progfay/25edb2a9ede4ca478cb3e2422f1f12f6)

## Multipassでの利用方法

* [Multipass](https://multipass.run/) 実行環境を用意します
* このリポジトリを手元に用意します

  ```sh
  git clone https://github.com/Lumonde-software/isucon-go-only.git
  cd isucon-go-only
  ```

* cloud-init を使って起動します

  ```sh
  multipass launch --name isucon10q --cpus 2 --disk 20G --memory 4G --timeout 86400 --cloud-init isucon10q/isucon10q.cfg 22.04
  ```

  * cpus, disk, memory は必要に応じて増減させてください
  * 末尾の `22.04` は Ubuntu のバージョンです
  * cloud-init は時間がかかるため timeout のエラーが表示される場合がありますが、バックグラウンドで構築は継続しています
* 進捗は `/var/log/cloud-init-output.log` で確認できます

  ```sh
  multipass exec isucon10q -- tail -f /var/log/cloud-init-output.log
  ```

* ログインとIPアドレスの確認

  ```sh
  multipass shell isucon10q
  multipass info isucon10q
  ```

* 環境の停止・再開・削除

  ```sh
  multipass stop isucon10q
  multipass start isucon10q
  multipass delete --purge isucon10q
  ```

ベンチマークの実行方法など詳細は同ディレクトリの README.cloud-init.md を参照してください。
