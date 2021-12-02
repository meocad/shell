#!/bin/bash
PS3="你想干啥："
select choice in eating wc sleep quit
do
    case $choice in
        eating)
            echo "you can eat some food now."
            ;;
        wc)
            echo "you can go go to wc now."
            ;;
        sleep)
            echo "you can go to sleep now."
            ;;
        quit)
            exit 0
    esac
done
