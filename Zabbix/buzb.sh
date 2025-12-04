#!/bin/bash
# zabbixバックアップシェルスクリプト
# zabbixのコンテナをバックアップを行うためのシェルスクリプト

#　バックアップに必要なパス
# フルバックアップ
# /docker/zabbix-docker
# /docker/volumes/
# /var/lib/docker/volumes/zabbix-docker_snmptraps

# メインバックアップ
# /docker/zabbix-docker/zbx_env/
# /docker/zabbix-docker/env_vars/
# /docker/volumes/
# /var/lib/docker/volumes/zabbix-docker_snmptraps



#　安全措置
set -euo pipefail
#　sudo権限のみ許可
[[ $EUID -eq 0 ]] || { echo "root で実行してください"; exit 1; }


#　フルバックアップ
#　git cloneのファイル一式
#  匿名２つのドッカーヴォリューム
#　snmpのドッカーヴォリューム

#　部分バックアップする一覧
#　１　.env
#　２　.env_vars
#  ３　sources
#  ４　docker-compose.yml

########################################################################################
#
#　定　義
#
########################################################################################

#compose upに使うファイルパス（バックアップとは別）
#/docker/zabbix-docker
ZABBIX_DIR_PATH=/docker/zabbix-docker

#/docker/backups/zabbix
ZABBIX_BACKUP_DIR=/home/backupuser/wabi-server-backups/zabbix

#${ZABBIX_BACKUP_DIR}/full
ZABBIX_BACKUP_FULL_DIR=${ZABBIX_BACKUP_DIR}/full

#${ZABBIX_BACKUP_DIR}/main
ZABBIX_BACKUP_MAIN_DIR=${ZABBIX_BACKUP_DIR}/main


#ローテーション世代数
FULL_BACKUP_ROTATION_GEN=2
MAIN_BACKUP_ROTATION_GEN=5

#バックアップ先のフォルダのアクセス権変更
OWNER=root:backupgroup
MODE=750





#選択されたオプション
selected_option=""

#日付フォルダの命名　2025-06-03_18-26-10
DATE_DIR=$(date +%Y-%m-%d_%H-%M-%S)
########################################################################################
#
#　メイン関数
#
########################################################################################

docker_down(){
    max_wait=30
    count=0
    docker compose -f $ZABBIX_DIR_PATH/docker-compose.yml down
    while docker ps --format '{{.Names}}' | grep -q '^zabbix-'; do
        echo "zabbix- で始まるコンテナがまだ停止していません。待機中... (${count}s)"
        sleep 1
        ((count++))
        if [ $count -ge $max_wait ]; then
            echo "エラー: コンテナ停止待機タイムアウト (${max_wait}秒経過)"
            exit 1
        fi
    done
    echo "すべての zabbix- プレフィックスのコンテナが停止しました。"

}




full_backup(){
    #フォルダ作成
    mkdir -p $ZABBIX_BACKUP_FULL_DIR

    chmod $MODE $ZABBIX_BACKUP_FULL_DIR
    chown $OWNER $ZABBIX_BACKUP_FULL_DIR
    
    #フルバックアップ
    tar czvPf $ZABBIX_BACKUP_FULL_DIR/$DATE_DIR.tar.gz \
        /docker/zabbix-docker \
        /docker/volumes \
        /var/lib/docker/volumes/zabbix-docker_snmptraps
    if [ $? -eq 0 ]; then
        echo "フルファイルの圧縮が完了しました。ファイル名：$DATE_DIR.tar.gz"
        echo "------ /docker/zabbix-docker -----"
        echo "------ /docker/volumes -----"
        echo "------ /var/lib/docker/volumes/zabbix-docker_snmptraps -----"
        chmod $MODE $ZABBIX_BACKUP_FULL_DIR/$DATE_DIR.tar.gz
        chown $OWNER $ZABBIX_BACKUP_FULL_DIR/$DATE_DIR.tar.gz
    else
        echo "フルファイルの圧縮に失敗しました。"
    fi
    docker compose -f "$ZABBIX_DIR_PATH/docker-compose.yml" up -d
    #ローテーション
    rotate $ZABBIX_BACKUP_FULL_DIR $FULL_BACKUP_ROTATION_GEN
}

main_dir_backup(){
    #フォルダ作成
    mkdir -p $ZABBIX_BACKUP_MAIN_DIR
    
    chmod $MODE $ZABBIX_BACKUP_MAIN_DIR
    chown $OWNER $ZABBIX_BACKUP_MAIN_DIR

    #必要なフォルダを圧縮
    tar czvPf $ZABBIX_BACKUP_MAIN_DIR/$DATE_DIR.tar.gz \
        /docker/zabbix-docker/zbx_env \
        /docker/zabbix-docker/env_vars \
        /docker/volumes \
        /var/lib/docker/volumes/zabbix-docker_snmptraps
    if [ $? -eq 0 ]; then
        echo "メインファイルの圧縮が完了しました。ファイル名：$DATE_DIR.tar.gz"
        echo "------ /docker/zabbix-docker/zbx_env -----"
        echo "------ /docker/zabbix-docker/env_vars -----"
        echo "------ /docker/volumes -----"
        echo "------ /var/lib/docker/volumes/zabbix-docker_snmptraps -----"
        chmod $MODE $ZABBIX_BACKUP_MAIN_DIR/$DATE_DIR.tar.gz
        chown $OWNER $ZABBIX_BACKUP_MAIN_DIR/$DATE_DIR.tar.gz 

    else
        echo "メインファイルの圧縮に失敗しました。"
    fi
    docker compose -f "$ZABBIX_DIR_PATH/docker-compose.yml" up -d

    #ローテーション
    rotate $ZABBIX_BACKUP_MAIN_DIR $MAIN_BACKUP_ROTATION_GEN
    
}

backup_clear(){
rm -rf $ZABBIX_BACKUP_DIR
}


# ##################################################################################
#　ローテーション処理
# ##################################################################################

# ローテーション処理
rotate() {
    local TARGET_DIR=$1
    local ROTATE=$2
    local FILES=($(ls -dt $TARGET_DIR/*.tar.gz))
    local COUNT=${#FILES[@]}
    if [ $COUNT -gt $ROTATE ]; then
    for ((i=$ROTATE; i<$COUNT; i++)); do
        rm -f "${FILES[$i]}"
        echo "ローテーション: ${FILES[$i]} を削除しました"
    done
    fi
}









while getopts "fmch" opt; do
    if [[ -n "$selected_option" ]]; then
        echo "エラー: オプションは1つだけ指定してください。"
        exit 1
    fi
    selected_option=$opt
    case $opt in
        f) # フルバックアップ
            echo "zabbixのフルバックアップを開始します"
            echo "===============================================zabbix フルバックアップ==============================================="
            # エラー起きてスクリプト終了するならザビックスは立ち上げる
            docker_down
            full_backup
            ;;
        m) # Weeklyバックアップ
            echo "zabbixのメインバックアップを開始します"
            echo "===============================================メインバックアップ==============================================="
            docker_down
            main_dir_backup
            ;;
        c) # バックアップ削除
            echo "===============================================バックアップの削除==============================================="
            echo "バックアップ削除を開始します"
            backup_clear
            ;;
        h) # ヘルプ
            echo "オプション: [-f:full backup]"
            echo "　　　　　　[-m:main backup]"
            echo "　　　　　　[-c:delete backup]"
            echo "　　　　　　[-h:help]"
            exit 0
            ;;
        \?) # 無効なオプション
            echo "無効なオプションです: -$OPTARG" >&2
            echo "-h: ヘルプを参照してください。"
            exit 1
            ;;
    esac
done