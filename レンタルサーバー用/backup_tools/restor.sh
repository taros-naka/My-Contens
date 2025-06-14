#!/usr/local/bin/bash
set -euo pipefail


#さくらレンタルサーバだと上記の記入じゃないと動かない。/home
USER_CURRENT_DIR=/home


#############################################################
#初期設定
#############################################################
#以下のにレンタルサーバで登録した情報を記載してください。

#サーバのアカウント名を入力（例："snowhare00")
Sever_NAME="snowhare00"

#データベースを構築したときの任意の名前を入力"xxxx_db"
USER_NAME="xxxx_db"

#ワードプレスのフォルダ名（www/から先）（例："wordpress_dir")
WORDPRESS_DIR_NAME="xxxx"

#DBのホスト名を入力（mysql0000.db.sakura.ne.jp)
DB_HOST="mysql0000.db.sakura.ne.jp"
#############################################################

#　DBのダンプした名前"mysql_dumpfile.sql"
DUMP_NAME="mysql_dumpfile.sql"


# バックアップしたファイルのフォルダ名"2023-10-01_12-00-00"
DATE_DIR=$1


# DBユーザー"snowhare64_xxxx_db"
DB_USER="${Sever_NAME}_${USER_NAME}"

# DB名"snowhare64_xxxx_db"
DB_NAME="$DB_USER"

#バックアップしているファイルのパス
# /home/snowhare64/backup/2023-10-01_12-00-00
BACKUP_PATH="${USER_CURRENT_DIR}/${Sever_NAME}/backup/$WORDPRESS_DIR_NAME/$DATE_DIR"

# ダンプファイルのパス
# /home/snowhare00/backup/2023-10-01_12-00-00/mysql_dumpfile.sql
DUMP_FILE="${USER_CURRENT_DIR}/${Sever_NAME}/backup/$WORDPRESS_DIR_NAME/$DATE_DIR/$DUMP_NAME"

#Wordpressのフォルダ位置
# /home/snowhare00/www/xxxx
WORDPRESS_DIR="${USER_CURRENT_DIR}/${Sever_NAME}/www/${WORDPRESS_DIR_NAME}"



#BACKUP_PATHの存在確認
if [ ! -d "$BACKUP_PATH" ]; then
    echo "バックアップパスが存在しません: $BACKUP_PATH"
    echo "正しいバックアップフォルダ名を指定してください。"
    echo "例: ./restor_${WORDPRESS_DIR_NAME}.sh 2023-10-01_12-00-00"
    echo ""
    echo "コマンドを終了します。"
    exit 1
fi

#パスワードを入力
read -s -p "パスワードを入力してください: " PASSWORD



#############################################################
# restore script
# このスクリプトは、指定されたデータベースのすべてのテーブルを削除し、
# その後、バックアップファイルからデータを復元します。
# 注意: この操作はデータを完全に削除するため、実行前にバックアップを取ることを強く推奨します。
#############################################################

# パスワード入力をエクスポート
export MYSQL_PWD=$PASSWORD

# スクリプト終了時にMYSQL_PWDをクリア
trap 'unset MYSQL_PWD' EXIT

# テーブル名を配列として取得
tables=($(mysql -h "$DB_HOST" -u "$DB_USER" -D "$DB_NAME" -Nse \
"SELECT table_name FROM information_schema.tables WHERE table_schema = DATABASE();"))

# 外部キー制約を一時的に無効化
mysql -h "$DB_HOST" -u "$DB_USER" -D "$DB_NAME" -e "SET FOREIGN_KEY_CHECKS = 0;"

# DROP TABLE 実行
for table in "${tables[@]}"; do
    echo "削除中: $table"
    mysql -h "$DB_HOST" -u "$DB_USER" -D "$DB_NAME" -e "DROP TABLE \`$table\`;"
done

# 外部キー制約を有効に戻す
mysql -h "$DB_HOST" -u "$DB_USER" -D "$DB_NAME" -e "SET FOREIGN_KEY_CHECKS = 1;"

echo "すべてのテーブルを削除しました。"


echo ""
echo "=== 削除後のテーブル一覧チェック ==="
remaining_tables=$(mysql -h "$DB_HOST" -u "$DB_USER" -D "$DB_NAME" -Nse \
"SELECT table_name FROM information_schema.tables WHERE table_schema = DATABASE();")

if [ -z "$remaining_tables" ]; then
  echo "✅ すべてのテーブルが削除されました。"
else
  echo "⚠️ 削除されなかったテーブルがあります:"
  echo "$remaining_tables"
fi

mysql -h "$DB_HOST" -u "$DB_USER" -p "$DB_NAME" < "$DUMP_FILE"


#############################################################################
# 圧縮ファイルを解凍して、ファイル位置に戻します
#############################################################################

# ワードプレスのディレクトリを削除
rm -rf "$WORDPRESS_DIR"
if [ $? -ne 0 ]; then
    echo "WordPressのディレクトリ削除に失敗しました。: "
    exit 1
fi
echo ""
echo "=== WordPressのディレクトリ削除しました==="

# バックアップファイルのコピー
cp -a "${BACKUP_PATH}/${WORDPRESS_DIR_NAME}.tar.gz" "${USER_CURRENT_DIR}/${Sever_NAME}/www/"
if [ $? -ne 0 ]; then
    echo "バックアップファイルのコピーに失敗しました。: "
    exit 1
fi
echo ""
echo "=== バックアップファイルをコピーしました ==="

#展開先ディレクトリに移動
cd "${USER_CURRENT_DIR}/${Sever_NAME}/www/"
if [ $? -ne 0 ]; then
    echo "ディレクトリの移動に失敗しました。: "
    exit 1
fi

# ワードプレスのディレクトリを解凍
echo "=== WordPressのディレクトリを解凍中 ==="
tar -zxf "${WORDPRESS_DIR_NAME}.tar.gz"
if [ $? -ne 0 ]; then
    echo "WordPressの解凍に失敗しました。: "
    exit 1
fi

# 解凍後のtar.gzファイルを削除
rm "${WORDPRESS_DIR_NAME}.tar.gz"
if [ $? -ne 0 ]; then
    echo "不要なtar.gzファイルの削除に失敗しました。: "
    exit 1
fi
echo "=== 不要なtar.gzファイルを削除しました ==="


echo ""
echo "=== WordPressのディレクトリを解凍・復元しました ==="

# データベースの復元が成功したか確認
echo ""
echo "=== データベースの復元確認 ==="
restored_tables=$(mysql -h "$DB_HOST" -u "$DB_USER" -D "$DB_NAME" -Nse \
"SELECT table_name FROM information_schema.tables WHERE table_schema = DATABASE();") 
if [ -z "$restored_tables" ]; then
  echo "⚠️ データベースが空です。復元に失敗した可能性があります。"
else
  echo "✅ データベースの復元が成功しました。以下のテーブルが存在します:"
  echo "$restored_tables"
fi
echo ""
echo "=== 復元が完了しました ==="
# MySQLのパスワードをクリア
unset MYSQL_PWD