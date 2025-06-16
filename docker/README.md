対象のOS　ubuntu24.04

Dockerコンテナ実装の方法
install：ドッカーをインストール

root権限で
docker_install.sh
を実行

ドッカーのバージョン確認
docker --version

ドッカーを常に起動
sudo systemctl enable docker

ドッカーが動作しているか確認
docker info

ドッカーのテスト始動
docker run hello-world

アプリケーション名のフォルダ内のファイルを実行（カレントディレクトリ直下）
docker compose up -d

※　-dはデーモン、ファイルパス指定は-f


アプリケーションの名前のフォルダにヤムルファイルがあるので実行
これでサーバーが構築できる


サンプルのコンフィグなのでパスワードは手元で変更して、使用する。
１枚に複数個の記載をすれば複数の同じアプリケーションが起動することができる
その時は命名と、ポートを変えてください。