#!/bin/sh
while true;do
    select mysql_version in "d" "bddvvv" "aads" "c";do
        case $mysql_version  in
            d)
                echo "mysql 5.1"
                break
                ;;
            b.*)
                echo "mysql 5.6"
                break
                ;;
             quit)
                exit
                ;;
            *)
                 echo "Input error,Please enter again!"
                 break
        esac
    done
done
IFS=$IFS_OLD
