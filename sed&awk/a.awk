#[root@maxiaorongtest-3-176 vhosts]# cat a.awk 
var=$1
echo $1 | grep -qi '\.conf$'
if [ ! $? = 0 ];then
  bash -c 'egrep --color -ri "[[:space:]]+'${var}'[[:space:]]*" * '
  exit
fi

/usr/bin/awk -r '$0 ~ "^[[:space:]]+location"{
  print $0
  while(getline){
    if($0~/location/){
      a="\n"$0
    }
    else{
      a=a"\n"$0
      if(a ~ "rewrite" && a ~ "break"){
        if($0 ~ "^[[:space:]]+proxy_pass.*://\\$.*")
          print a""
      }
    }
  }
}' $1
