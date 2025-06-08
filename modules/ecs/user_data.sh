#!/bin/bash

# Set ECS_CLUSTER in the ECS agent configuration
#echo "ECS_CLUSTER=${ecs_cluster_name}" | sudo tee -a /etc/ecs/ecs.config
echo ECS_CLUSTER=prod-pfc-ecs-cluster | sudo tee -a /etc/ecs/ecs.config
# Append SSH public key to authorized_keys
echo "${ssh_public_key}" | sudo tee -a c/authorized_keys
