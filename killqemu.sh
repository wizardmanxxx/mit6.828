#!/bin/sh

tomcat_id=`ps -ef | grep qemu | grep -v "grep" | awk '{print $2}'`
echo $tomcat_id

for id in $tomcat_id
do
    kill -9 $id  
    echo "killed $id"  
done
