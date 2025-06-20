# Rubyで記述されたLALR(1)パーサージェネレーター

## ファイル

それぞれのファイルは`$ ruby filename.rb`で動作確認ができる。

- `parsergen.rb`
    - 構造体の定義とLR(1)パーサージェネレーター
- `parsergen_lalr.rb`
    - LR(1)の構文解析表からLALR(1)の構文解析表を作成
- `calc.rb`
    - LR(1)言語で記述された四則演算計算機
- `calc2.rb`
    - 優先順位表を使ってコンフリクトを解消する必要のある言語の構文解析表を作成
- `calc_lex.rb`
    - 四則演算計算機用のレキサー(おまけ)
- `reducereduce.rb`
    - reduce/reduceコンフリクトを起こす構文規則(エラー)
- `json.rb`
    - jsonのパーサー
- `mysterious_conflict.rb`
    - LR(1)であるがLALR(1)ではない構文規則

## Webブラウザーで動くデモ

```sh
$ ruby -run -e httpd
```

[http://localhost:8080/visualize.html](http://localhost:8080/visualize.html)

## 参考文献

- コンパイラ(湯浅太一)
- コンパイラ -第二版-
