#!/bin/bash
set -e

# ホストのUID/GIDを取得
USER_ID=${LOCAL_USER_ID:-9001}
GROUP_ID=${LOCAL_GROUP_ID:-9001}
BUILD_USER=yugabyte
BUILD_GROUP=yugabytegroup

echo "Starting with UID : $USER_ID, GID: $GROUP_ID"
groupadd -o -g $GROUP_ID $BUILD_GROUP || groupmod -o -g $GROUP_ID $BUILD_GROUP
useradd -u $USER_ID -g $GROUP_ID -s /bin/bash -m $BUILD_USER 2>/dev/null || usermod -o -u $USER_ID -g $GROUP_ID $BUILD_USER

# yugabyte ユーザーに sudo 権限を付与
if [ -d /etc/sudoers.d ] || mkdir -p /etc/sudoers.d; then
  echo "$BUILD_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$BUILD_USER
  chmod 0440 /etc/sudoers.d/$BUILD_USER
else
  if [ -w /etc/sudoers ]; then
    echo "$BUILD_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
  else
    echo "Warning: Could not grant sudo privileges to $BUILD_USER"
  fi
fi

# 環境設定を yugabyte ユーザーの .bashrc に追加
if [ ! -f /home/$BUILD_USER/.bashrc ]; then
  touch /home/$BUILD_USER/.bashrc
  chown $BUILD_USER:$BUILD_GROUP /home/$BUILD_USER/.bashrc
fi

# マウントされたディレクトリの所有権を変更しないようにする
# 代わりに必要なディレクトリを作成して所有権を設定
chown -R $BUILD_USER:$BUILD_GROUP /home/$BUILD_USER
chown -R $BUILD_USER:$BUILD_GROUP /opt/yb-build


# 指定されたコマンドを yugabyte ユーザーとして実行
if [ $# -eq 0 ]; then
  exec gosu $BUILD_USER /bin/bash -l
else
  exec gosu $BUILD_USER "$@"
fi
