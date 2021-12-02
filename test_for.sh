#!/bin/sh

basedir=`pwd`
fix_path ()
{
  var=$1
  shift
  for filename  # 自动加上in后面的东西，相当于for file in '"$@"'
  do
    path=$basedir/$filename
    if [ -d "$path" ] ;
    then
      echo "$var"=$path
      return
    fi
  done
}

which ()
{
  IFS="${IFS=   }"; save_ifs="$IFS"; IFS=':'
  for file
  do
    for dir in $PATH
    do
      if test -f $dir/$file
      then
        echo "$dir/$file"
        continue 2
      fi
    done
    echo "which: no $file in ($PATH)"
    exit 1
  done
  IFS="$save_ifs"
}


which ls
fix_path /opt/soft /opt/git /opt/rh
