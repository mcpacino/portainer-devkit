#!/usr/bin/env bash

_rpc_dlv_exec_kill_tmux() {
  tmux kill-session -t "${TMUX_NAME}" 2>>"${STDOUT}" 1>&2
}

_rpc_dlv_exec_tmux() {
  TMUX_NAME="tmux-$PROJECT-$TARGET"
  TMUX_CMD="tmux new -d -s $TMUX_NAME"
}

_rpc_dlv_exec_cmder() {
  if [ "$TARGET" == "k8s" ]; then
    POD=$(kubectl get pod -l app=portainer-agent -n portainer -o jsonpath="{.items[0].metadata.name}")
    RPC_DLV_CMDER="kubectl exec -it -n portainer $POD --"
  else
    RPC_DLV_CMDER="sshpass -p $SSH_PASSWORD ssh root@$TARGET_IP"
  fi
}

_var_adder() {
  ENV_VAR_LIST="$ENV_VAR_LIST:$1"
}

_make_env_var_list() {
  ENV_VAR_LIST="DLV_PORT=$DLV_PORT:DEVKIT_DEBUG=$DEVKIT_DEBUG"

  [[ $TARGET == "k8s" ]] && _var_adder "AGENT_CLUSTER_ADDR=portainer-agent-headless"
  [[ $TARGET == "swarm" ]] && _var_adder "AGENT_CLUSTER_ADDR=tasks.portainer_edge_agent"

  [[ $PROJECT == "portainer" ]] && _var_adder "DATA_PATH=$DATA_PATH"
  [[ $PROJECT == "edge" ]] && _var_adder "EDGE=1:EDGE_INSECURE_POLL=1:EDGE_ID=devkit-edge-id:EDGE_KEY=$EDGE_KEY"
}

_rpc_dlv_exec_cmdee() {
  _make_env_var_list
  RPC_DLV_CMDEE="/app/scripts/devkit.sh dlv exec $PROJECT $ENV_VAR_LIST"
}

_do_rpc_dlv_exec() {
  _rpc_dlv_exec_tmux
  _rpc_dlv_exec_cmder
  _rpc_dlv_exec_cmdee

  _rpc_dlv_exec_kill_tmux

  RPC_DLV_FULL_CMD="$TMUX_CMD $RPC_DLV_CMDER $RPC_DLV_CMDEE"
  debug "RPC_DLV_FULL_CMD=$RPC_DLV_FULL_CMD"

  eval "${RPC_DLV_FULL_CMD}"
}

rpc_dlv_exec() {
  MSG0="RPC DLV Portainer"
  MSG1=$(msg_ing)
  MSG2=$(msg_ok)
  MSG3=$(msg_fail)

  echo && echo "$MSG1" &&
  (_do_rpc_dlv_exec && echo "$MSG2") ||
  (echo "$MSG3" && false)
}