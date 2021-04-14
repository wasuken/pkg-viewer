# pkg-viewer

名前が足りてない。

正しくはパッケージ管理システムから取得してきたデータのビューワ。

## 動作環境

* ruby: 2.7

* linux

	ほかは知らん。多分動くんじゃね。

## 使い方

```shell
$ git clone https://github.com/wasuken/pkg-viewer
$ cd pkg-viewer
$ bundle install
```

以下、config.jsonはクライアントデータ取得のために必須なので先に作る。

### config.json作成

config.json.sampleに習って書く。

### クライアントデータの作成

```shell
$ bundle exec ruby client.rb
```

### CVEデータ挿入

cve圧縮csvファイルを持ってきて解凍。

```shell
$ wget http://cve.mitre.org/data/downloads/allitems.csv.gz
$ gzip -d allitems.csv.gz
$ bundle exec ruby cve.rb <解凍したcveのcsvファイルパス>
```

## 課題

* **遅い**

* Dockerに閉じ込めたい。

	* ならMySQLに変えたい。

	* 選択させたい。
