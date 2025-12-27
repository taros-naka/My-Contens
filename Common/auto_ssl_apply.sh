#!/bin/bash
# SSL自動適用スクリプト
# https://note.com/foai_web/n/nbc0ad5ab5f23

PEM_FILE_PATH="/etc/letsencrypt/live/yourdomain/fullchain.pem"



# 証明書の有効期限を確認
# OpenSSLで確認
sudo openssl x509 -in ${PEM_FILE_PATH} -noout -dates

# Certbotのバージョン確認
sudo certbot certificates

# installされているか確認
which certbot

# Certbotのインストール
sudo apt update
sudo apt install -y certbot certbot python2-certbot-apache


# SSL証明書の自動取得と適用
sudo certbot --apache -d yourdomain -d www.yourdomain --non-interactive --agree-tos -m

# Apacheの再起動
sudo systemctl restart apache2

