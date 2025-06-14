#!/bin/bash
# dockerのインストールスクリプト
# 参考: https://qiita.com/ryome/items/29b3241d32cf63849f63
# 参考: https://docs.docker.com/engine/install/ubuntu/

# このスクリプトはroot権限で実行する必要があります
[[ $EUID -eq 0 ]] || { echo "root で実行してください"; exit 1; }


# dockerの競合する可能性のあるパッケージを削除
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Dockerのリポジトリを追加
# Ubuntuのバージョンに応じてリポジトリを設定:
echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

#　ドッカーのインストール
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# dockerの起動
sudo docker run hello-world



