#!/bin/bash
set -e

# Set the host's UID and GID
USER_ID=${LOCAL_USER_ID:-9001}
GROUP_ID=${LOCAL_GROUP_ID:-9001}
BUILD_USER=yugabyte
BUILD_GROUP=yugabytegroup

# Create the user and group
echo "Starting with UID : $USER_ID, GID: $GROUP_ID"
groupadd -o -g $GROUP_ID $BUILD_GROUP || groupmod -o -g $GROUP_ID $BUILD_GROUP
useradd -u $USER_ID -g $GROUP_ID -s /bin/bash -m $BUILD_USER 2>/dev/null || usermod -o -u $USER_ID -g $GROUP_ID $BUILD_USER

# Grant sudo priviledges to the yugabyte user
if [ -d /etc/sudoers.d ] || mkdir -p /etc/sudoers.d
then
  echo "$BUILD_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$BUILD_USER
  chmod 0440 /etc/sudoers.d/$BUILD_USER
elif [ -w /etc/sudoers ]
then
  echo "$BUILD_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
else
  echo "WARNING: Could not grant sudo privileges to $BUILD_USER"
fi

# Change ownership of $HOME directory
# Be careful not to alter ownership of the mounted /yugabytedb directory
chown -R $BUILD_USER:$BUILD_GROUP /home/$BUILD_USER
chown -R $BUILD_USER:$BUILD_GROUP /opt/yb-build

# Run the specified command as yugabyte user
if [ $# -eq 0 ]
then
  exec gosu $BUILD_USER /bin/bash -l
else
  exec gosu $BUILD_USER "$@"
fi
