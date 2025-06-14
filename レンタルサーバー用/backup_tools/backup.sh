#!/usr/local/bin/bash


#さくらレンタルサーバだと上記の記入じゃないと動かない。/home
USER_CURRENT_DIR=/home
Sever_NAME=$(whoami)
DATA=$(date +%Y-%m-%d_%H-%M-%S)


#############################################################
#初期設定
#############################################################
#以下のにレンタルサーバで登録した情報を記載してください。

#データベースを構築したときの任意の名前を入力
##例："xxxx_db"
USER_NAME="xxxx_db"

#ワードプレスのフォルダ名（www/から先）（例："wordpress_dir")
ROOT_DIR="xxxx"

#############################################################


# バックアップディレクトリ名
BACKUP_DIR="backup"

# ローテーション数（世代管理）
# 例: 5世代管理する場合は5を指定
ROTATINE_GEN=5


# DB情報
#snowhare00_wpsxxxx_db
DB_USER="${Sever_NAME}_${USER_NAME}"
DB_NAME="$DB_USER"

#ファイルパス
#/home/snowhare00/backup
BACKUP_PATH="${USER_CURRENT_DIR}/${Sever_NAME}/${BACKUP_DIR}"


#バックアップファイルを格納する場所
BACKUP_ROOT_DIR="${BACKUP_PATH}/${ROOT_DIR}"


#バックアップファイルを格納する場所
#/home/snowhare00/backup/0000-00-00_00-00-00
#BACKUP_DATE_PATH=$BACKUP_PATH/$DATA
BACKUP_DATE_PATH=$BACKUP_PATH/$ROOT_DIR/$DATA


#Wordpressのフォルダ位置
#/home/snowhare00/www/wordpress_directory
WORDPRESS_DIR="${USER_CURRENT_DIR}/${Sever_NAME}/www/${ROOT_DIR}"

#Wordpressの親フォルダ
#/home/snowhare00/www/
WWW_DIR="${USER_CURRENT_DIR}/${Sever_NAME}/www"

#tar.gzにしたときのファイル名
#wordpress_directory.tar.gz
COMMPRESSED_FILE="${ROOT_DIR}.tar.gz"

#dumpファイルの名前
DUMP_NAME=mysql_dumpfile.sql


# ##################################################################################
#　ローテーション処理
# ##################################################################################

# ローテーション処理
rotate() {
    local TARGET_DIR=$1
    local ROTATE=$2
    local FOLDERS=($(ls -dt $TARGET_DIR/*/)) # フォルダを取得し、最新順に並べる
    local COUNT=${#FOLDERS[@]}

    if [ $COUNT -gt $ROTATE ]; then
        for ((i=$ROTATE; i<$COUNT; i++)); do
            # フォルダを削除
            rm -rf "${FOLDERS[$i]}" # フォルダを削除
            echo "ローテーション: ${FOLDERS[$i]} を削除しました"
        done
    fi
}

#############################################################
#バックアップ
#############################################################

make_dir(){
    mkdir -p $BACKUP_DATE_PATH
    if [ $? -ne 0 ]; then
        echo "backupフォルダの生成に失敗: " 
        exit 1
    fi
    return 0
}


commpress(){
    cd $WWW_DIR
    if [ $? -ne 0 ]; then
        echo "cd:圧縮コマンドが失敗しました。: " 
        cd /home
        exit 1
    fi

    tar -czf $COMMPRESSED_FILE $ROOT_DIR
    if [ $? -ne 0 ]; then
        echo "圧縮に失敗しました: " 
        cd ~
        exit 1
    fi
    cd ~
    return 0
}


file_move(){
    #/home/snowhare00/www/wordpress_directory.tar.gz → /home/snowhare00/backup/0000-00-00/wordpress_directory.tar.gz
    mv $WWW_DIR/$COMMPRESSED_FILE $BACKUP_DATE_PATH/$COMMPRESSED_FILE
    if [ $? -ne 0 ]; then
        echo "ファイルの移動に失敗しました。: " 
        exit 1
    fi
    return 0
}

mysql_dump(){

    mysqldump --defaults-file=/home/${Sever_NAME}/backuptool/.my.conf_${ROOT_DIR} --no-tablespaces $DB_NAME >$BACKUP_DATE_PATH/$DUMP_NAME
    if [ $? -ne 0 ]; then
        echo "ダンプファイルの作成に失敗しました。: " 
        exit 1
    fi



    #次回コンフィグファイルを作って、自動化できるようにする
    # mysqldump --no-tablespaces -h $DB_HOST -u $DB_USER -p"$DB_PASS" $DB_NAME > $BACKUP_DATE_PATH/$DUMP_NAME
    # if [ $? -ne 0 ]; then
    #     echo "ダンプファイルの作成に失敗しました。: " 
    #     exit 1
    # fi

}

backup(){
    make_dir
    if [ $? -ne 0 ]; then
        echo "フォルダ作成エラー: " 
        exit 1
    fi
    echo "バックアップ用フォルダ作成完了"

    commpress
    if [ $? -ne 0 ]; then
        echo "圧縮エラー: " 
        exit 1
    fi
    echo "フォルダ圧縮完了"

    file_move
    if [ $? -ne 0 ]; then
        echo "ファイルが移動できません: " 
        exit 1
    fi
    echo "バックアップファイルに格納"

    mysql_dump
    if [ $? -ne 0 ]; then
        echo "ダンプファイルエラー: " 
        exit 1
    fi
    echo "ダンプファイル作成・格納完了"

    echo ""
    echo "####################"
    echo "# バックアップ完了  #"
    echo "####################"
    # ローテーション処理を実行
    echo "ローテーション処理を開始します..."
    rotate $BACKUP_ROOT_DIR $ROTATINE_GEN
    if [ $? -ne 0 ]; then
        echo "ローテーション処理に失敗しました。: " 
        exit 1
    fi
    echo "ローテーション処理完了"   
    return 0

}

# 処理の時間計測
start_time=$(date +%s)
backup

# 処理の時間計測終了
end_time=$(date +%s)
# 処理時間の計算
elapsed_time=$((end_time - start_time))
# 処理時間の表示
echo "処理時間: $elapsed_time 秒"
# 処理時間の表示
echo "バックアップスクリプトが正常に終了しました。"

