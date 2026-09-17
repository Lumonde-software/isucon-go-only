# webapp

Go の参考実装のみが用意されています(Go-only 版)。

```
.
├── fixture     # 問題に使用されるデータ
├── frontend    # フロントエンドのソースコード
├── mysql       # MySQL のテーブルデータ
├── nginx       # Nginx の設定ファイル
└── go          # Go の参考実装
```

## 起動方法

```sh
make isuumo/go
```

ベンチマーカーはフロントエンド側へのリクエストを行わないため、以下のコマンドでも計測は可能です。

```sh
make api-server/go
```

