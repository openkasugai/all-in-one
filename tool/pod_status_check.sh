#!/bin/bash

command_to_check="sudo kubectl get pods -A | tail +2 | grep -v Running"

max_wait_time=600
elapsed_time=0
wait_interval=5

while eval $command_to_check; do
    if [ $elapsed_time -ge $max_wait_time ]; then
        echo "ERROR: wait_time($max_wait_time sec) expired."
        exit 1
    fi

    echo "INFO: Retrying due to non-Running Pods."
    sleep $wait_interval
    elapsed_time=$((elapsed_time + wait_interval))
done

echo "INFO: All Pods are now Running."
exit 0
