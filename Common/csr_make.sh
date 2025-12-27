#!/bin/bash
# CSR作成スクリプト
# 作成者: Server World
# https://ja.linux-console.net/?p=30236


sudo apt install openssl
# CSR（証明書署名要求）を作成するスクリプト
# 秘密鍵とCSRファイルを生成し、証明書発行のために使用される
# 証明書発行に必要な情報を入力するプロンプトが表示される

SEC_KEY_NAME="mydomain"
CSR_FILE_NAME="mydomain"


# 秘密キーを生成する
openssl genrsa -out ${SEC_KEY_NAME}.key 2048

# CSRを生成する
openssl req -new -key ${SEC_KEY_NAME}.key -out ${CSR_FILE_NAME}.csr

# プロンプトに従って以下の情報を入力
# Country Name (2 letter code) [AU]:JP                            # 国
# State or Province Name (full name) [Some-State]:Hiroshima       # 地域（県）
# Locality Name (eg, city) []:Hiroshima                           # 都市
# Organization Name (eg, company) [Internet Widgits Pty Ltd]:GTS  # 組織名
# Organizational Unit Name (eg, section) []:Server World          # 組織の部門名
# Common Name (e.g. server FQDN or YOUR name) []:dlp.srv.world    # サーバーの FQDN
# Email Address []: 
# あとはエンターで省略（チャレンジパス設定）


echo "秘密鍵とCSRファイルが生成されました:"
echo "秘密鍵: ${SEC_KEY_NAME}.key"
echo "CSRファイル: ${CSR_FILE_NAME}.csr"
echo "これらのファイルを使用して証明書を発行してください。"
