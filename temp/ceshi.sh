#!/bin/bash
p=`ps -ef | grep tomcat | grep -v grep | grep -v bash | wc -l`
if [ $p == 0 ]
then
  echo "hello"
else
  echo "oops"
fi 
