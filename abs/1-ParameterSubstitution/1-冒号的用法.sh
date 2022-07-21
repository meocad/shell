# 冒号的作用：
# 1. 占位符作用，此时仅输入一个冒号 :
# 类似于python的 pass

if [ "ab" == "cd" ]
then
  :
else
  :
  echo 哈哈哈哈
fi


# 2. 单行注释与多行注释
: 不知道是不是单行注释
: '
这些是注释，脚本不会输出
this is comment not for output
冒号实现多行注释
'


# 3. : ${VAR:=DEFAULT}
# 起到赋值给VAR的作用, 让其只是变量的赋值不是当作命令去执行
#
: ${HOSTNAME?} ${USER?} ${HOME?} ${MAIL?}

echo ${HOSTNAME} ${USER} ${HOME} ${MAIL}
