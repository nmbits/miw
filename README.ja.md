# MiW: 新しいテキストエディタ
## はじめに

MiWはテキストエディタ(を目指すもの)です。以下の特徴があります。

1. 大半のコードがRubyで書かれています。
2. Rubyで書かれたRuby向けGUIツールキット(を目指すもの)でもあります。
3. Ruby-cairo, Ruby-pangoを2Dレンダリングエンジンに使っているので、高品質な表示ができます。
4. EventMachineをバックエンドに使っているので、ネットワークと高い親和性があります。

## 準備

Ubuntuのケースで説明します。他のディストリビューションでは適宜読み替えてください。

### RubyとBundlerのインストール

    > sudo apt install ruby-full
    > sudo gem install bundler

### 必要なパッケージのインストール

    > sudo apt install libxcb1-dev libxcb-xkb-dev libcairo2-dev libxkbcommon-x11-dev

### 拡張ライブラリのビルド

clone先のディレクトリで以下を実行してください。

    > cd ext
    > ruby extconf.rb
    > make

### gemのインストール

clone先のディレクトリで以下を実行してください。

    > bundle install --path vendor/bundle

## 実行方法

exampleにあるGUIツールキットのサンプルのようなものが実行できます。clone先のディレクトリで以下を実行してください。

    > ruby -I ext -I lib example/scroll_view.rb

または

    > ruby -I ext -I lib example/scrollable_text_view.rb
