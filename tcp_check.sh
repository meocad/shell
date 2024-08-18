hosts=(127.0.0.1 127.0.0.2 127.0.0.3)
ports=(22 23 25 80)

for host in "${hosts[@]}"
do
  for port in "${ports[@]}"
  do
    if echo "Hi from Bharat's scanner at $(uname -n)" 2>/dev/null > /dev/tcp/"$host"/"$port"
    then
      echo success at "$host":"$port"
    else
      echo failure at "$host":"$port"
    fi
  done
done

