#!/usr/bin/env bash

debug() {
  [[ $DEVKIT_DEBUG == "true" ]] && echo "$E_MSG $E_BUG $(date) $*"
}

_do_msg() {
  echo "$E_MSG️ $MSG0 $1"
}

msg_ing() {
  _do_msg "$E_ING"
}

msg_ok() {
  _do_msg "$E_OK"
}

msg_warn() {
  _do_msg "$E_WARN"
}

msg_fail() {
  _do_msg "$E_FAIL"
}


_do_ssh() {
  sshpass -p "$SSH_PASSWORD" ssh root@"$TARGET_IP" true
}

wait_for_sshd_up() {
  #  until nc -w 1 "$TARGET_IP" 22; do

  until _do_ssh; do
    MSG0="Wait for SSH Server"
    MSG1=$(msg_ing)
    echo $MSG1
    sleep 3;
  done
}

scp_agent_to_target() {
  local TARGET_IP=$1

  sshpass -p "root" scp /go/bin/dlv root@"$TARGET_IP":/usr/bin/ >>"$STDOUT" 2>&1
  sshpass -p "root" scp /agent/dist/agent root@"$TARGET_IP":/app/
  sshpass -p "root" scp /scripts/libs/start-agent-dlv.sh root@"$TARGET_IP":/app/
}

rsync_portainer_to_target() {
  local TARGET_IP=$1
  local PROJECT_ROOT_PATH=$2

  sshpass -p "root" rsync /app/public/* root@192.168.100.1:/app/public/
  sshpass -p "root" scp /go/bin/dlv root@"$TARGET_IP":/usr/bin/ >>"$STDOUT" 2>&1
  sshpass -p "root" scp "${PROJECT_ROOT_PATH}/dist/portainer" root@"$TARGET_IP":/app/
  sshpass -p "root" scp /scripts/libs/start-portainer-dlv.sh root@"$TARGET_IP":/app/
}

ls_docker_sock() {
  local TARGET_CONTAINER_NAME=$1

  docker exec -e DEVKIT_DEBUG=$DEVKIT_DEBUG "$TARGET_CONTAINER_NAME" ls -l /var/run/docker.sock >>$STDOUT 2>&1
}

wait_for_target_up() {
  local TARGET_NAME=$1
  local TARGET_CONTAINER_NAME=$2

  MSG0="Wait for Target"
  MSG1=$(msg_ing)

  until ls_docker_sock $TARGET_CONTAINER_NAME; do
    echo $MSG1
    sleep 1;
  done
}

kill_dlv() {
  (killall dlv >/dev/null 2>&1 && sleep 1) || true
}
