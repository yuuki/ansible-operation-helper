#!/bin/bash
set -e -o pipefail

apt-get update && apt-get install -y mackerel-agent mackerel-agent-plugins mackerel-check-plugins mkr
service mackerel-agent restart