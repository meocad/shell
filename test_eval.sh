#!/bin/sh
#****************************************************************#
# ScriptName: test_eval.sh
# Author: @outlook.com
# Create Date: 2021-04-30 10:44
# Modify Author: @outlook.com
# Modify Date: 2021-04-30 10:44
# Function: test eval command
#***************************************************************#

echo "Last argument is $(eval echo \$$#)"
