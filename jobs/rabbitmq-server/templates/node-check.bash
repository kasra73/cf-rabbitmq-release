#!/bin/bash -e

[ -z "$DEBUG" ] || set -x

export PATH=/var/vcap/packages/erlang/bin/:/var/vcap/packages/rabbitmq-server/privbin/:$PATH
LOG_DIR=/var/vcap/sys/log/rabbitmq-server

main() {
  pid_file_contains_rabbitmq_erlang_vm_pid
  rabbitmq_application_is_running
}

pid_file_contains_rabbitmq_erlang_vm_pid() {
  local tracked_pid rabbitmq_erlang_vm_pid
  tracked_pid="$(cat /var/vcap/sys/run/rabbitmq-server/pid)"
  rabbitmq_erlang_vm_pid="$(rabbitmqctl eval 'list_to_integer(os:getpid()).')"

  [[ "$tracked_pid" = "$rabbitmq_erlang_vm_pid" ]] ||
  fail "Expected PID file to contain '$rabbitmq_erlang_vm_pid' but it contained '$tracked_pid'"
}

# rabbitmq_application_is_running checks the health of the node to determine
# whether the application is running. We assume if the application is not
# running that the cluster is not healthy.
rabbitmq_application_is_running() {
  rabbitmqctl node_health_check ||
  fail "RabbitMQ application is not running"
}


fail() {
  echo "$*"
  exit 1
}

send_all_output_to_logfile() {
  exec 1> >(tee -a "${LOG_DIR}/node-check.log")
  exec 2> >(tee -a "${LOG_DIR}/node-check.log")
}

send_all_output_to_logfile
SCRIPT_CALLER="${1:-node-check}"
echo "Running node checks at $(date) from $SCRIPT_CALLER..."
main
echo "Node checks running from $SCRIPT_CALLER passed"
