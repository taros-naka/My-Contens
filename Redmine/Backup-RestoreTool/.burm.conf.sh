#!/bin/bash

#　burmコマンドの設定ファイル

# ###################################################################################
# 変数定義
# ###################################################################################
#バックアップ先親ディレクトリ
BACKUP_DIR=/var/backups/redmine
#バックアップ元(redmineのファイルズディレクトリ)
REDMINE_FILE_DIR=/var/lib/redmine/files
#バックアップ元(redmineのコンフィグディレクトリ)
REDMINE_CONFIG_DIR=/var/lib/redmine/config

#時間の文字列：yyyy-mm-dd_hh:mm:ss
#現在の時間を取得
DATE_DIR=$(date +%Y-%m-%d_%H-%M-%S)

#フォルダを定義：[daily|weekly|monthly]
DAILY_DIR=$BACKUP_DIR/daily
WEEKLY_DIR=$BACKUP_DIR/weekly
MONTHLY_DIR=$BACKUP_DIR/monthly

#データベースの設定
DB_NAME=redmine
DB_USER=redmine
DB_PASS=testpass
DB_HOST=localhost

#ローテーションの設定
#daily（日次）バックアップのローテーション(世代数)
DAILY_ROTATE=4
#weekly（週次）バックアップのローテーション（世代数）
WEEKLY_ROTATE=5
#monthly（月次）バックアップのローテーション（世代数）
MONTHLY_ROTATE=1

#バックアップファイルの取り扱いグループ
CH_BACKUP_OWNER_GROUP=root:user
#バックアップファイルのパーミッション
CH_BACKUP_PERMISSION="755"

#レストアファイルの取り扱いグループ
CH_RESTORE_OWNER_GROUP=root:root
#リストアファイルのパーミッション
CH_RESTORE_PERMISSION=777

RESTOR_DIR="/var/backups/redmine/restore_files"
