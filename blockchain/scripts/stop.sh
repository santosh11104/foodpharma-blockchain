#!/bin/bash

. utils.sh

infoln "Stopping FoodPharma Blockchain Network"

./network.sh down

successln "FoodPharma blockchain network stopped and cleaned up"