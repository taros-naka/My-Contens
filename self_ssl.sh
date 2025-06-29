#!/bin/bash

# 自己認証（オレオレ証明）を設定


# コンフィグで端末のドメインを宣言
nano /etc/ssl/openssl.cnf
# 最下部に追記
# [ srv.world ]
# subjectAltName = DNS:user-testmachine1.local


# 証明書のフォルダへ移動
cd /etc/ssl/private

# 秘密鍵を発行
openssl ecparam -name prime256v1 -genkey -out server.key

# オレオレ証明書発行
openssl req -new -key server.key -out server.csr

# Country Name (2 letter code) [AU]:JP                            # 国
# State or Province Name (full name) [Some-State]:Hiroshima       # 地域（県）
# Locality Name (eg, city) []:Hiroshima                           # 都市
# Organization Name (eg, company) [Internet Widgits Pty Ltd]:GTS  # 組織名
# Organizational Unit Name (eg, section) []:Server World          # 組織の部門名
# Common Name (e.g. server FQDN or YOUR name) []:dlp.srv.world    # サーバーの FQDN
# Email Address []:root@srv.world                                 # 管理者アドレス
# あとはエンターで省略
# チャレンジパスは更新の

#　期間を変更　365　1年有効
openssl x509 -in server.csr -out server.crt -req -signkey server.key -extfile /etc/ssl/openssl.cnf -extensions srv.world -days 365

#　apacheのSSLエンジン有効
a2enmod ssl
nano /etc/apache2/sites-available/000-default.conf

# 以下を追加

# <VirtualHost *:443>
#     ServerName your.domain.com
#     DocumentRoot /var/lib/redmine/public
#     ErrorLog ${APACHE_LOG_DIR}/error_ssl.log
#     CustomLog ${APACHE_LOG_DIR}/access_ssl.log combined
#     SSLEngine on
#     SSLCertificateFile /etc/ssl/private/server.crt
#     SSLCertificateKeyFile /etc/ssl/private/server.key
# </VirtualHost>

# ssl縛りなら
# Redirect permanent / https://user-testmachine1.local/
# を80ポートの先頭に追加する


