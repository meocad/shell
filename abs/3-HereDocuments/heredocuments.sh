# here documents 命名格式如下：

: 'COMMAND <<InputComesFromHERE
...
...
...
InputComesFromHERE'

: 'interactive-program <<LimitString
command #1
command #2
...
LimitString'

# 1. 使用wall命令给每个用户发送broadcast
wall <<zzz23EndOfMessagezzz23
E-mail your noontime orders for pizza to the system administrator.
    (Add an extra dollar for anchovy or mushroom topping.)
# Additional message text goes here.
# Note: 'wall' prints comment lines.
zzz23EndOfMessagezzz23

# 2. 使用vim面交互式写入文件内容
vi ceshi <<x23LimitStringx23
i
This is line 1 of the example file.
This is line 2 of the example file.

ZZ
x23LimitStringx23

# 需要注意的是： 是控制字符 ESC 的控制字符
# 通过连续按下 Ctrl + v + [ 三个字符即可生成, 需要连续按下，中间无停顿
# 


# 3. 文本替换
ORIGINAL=Smith
REPLACEMENT=Jones

cat > ceshi.txt <<'EOF'
1. Smith
2. danny
3. jenny
4. xiaorong
EOF

for word in $(fgrep -l $ORIGINAL *.txt)
do
  # -------------------------------------
  ex $word <<EOF
  :%s/$ORIGINAL/$REPLACEMENT/g
  :wq
EOF
done


# 4. 使用heredocuments打印多行信息
# 使用cat
echo;echo;echo
cat <<End-of-message
-------------------------------------
This is line 1 of the message.
This is line 2 of the message.
This is line 3 of the message.
This is line 4 of the message.
This is the last line of the message.
-------------------------------------
End-of-message

echo;echo;echo
# 也可以使用echo达到相同的效果
echo "-------------------------------------
This is line 1 of the message.
This is line 2 of the message.
This is line 3 of the message.
This is line 4 of the message.
This is the last line of the message.
-------------------------------------"

echo;echo;echo
# 5. 通过在LimitString前面加“-”来忽略每行首的TAB，
cat <<-ENDOFMESSAGE
	This is line 1 of the message.
	This is line 2 of the message.
	This is line 3 of the message.
	This is	line 4 of the message.
	This is the last line of the message.
ENDOFMESSAGE

echo;echo;echo 1
# 6. heredocuments传递的内容使用参数替换
RESPONDENT="the author of this fine script" 
NAME="John Doe"
cat <<Endofmessage

Hello, there, $NAME.
Greetings to you, $NAME, from $RESPONDENT.

# This comment shows up in the output.

Endofmessage

# 7. heredocuments传递的内容禁止使用参数替换

# cat <<'Endofmessage'
# cat <<"SpecialCharTest"
# cat <<\Endofmessage
# 上面三种方式等价，均是 禁止使用参数替换

# 方式1:
cat <<'Endofmessage'

Hello, there, $NAME.
Greetings to you, $NAME, from $RESPONDENT.

Endofmessage

# 方式2:
cat <<\Endofmessage

Hello, there, $NAME.
Greetings to you, $NAME, from $RESPONDENT.

Endofmessage

# 方式3:
cat <<"SpecialCharTest"

Directory listing would follow
if limit string were not quoted.
`ls -l`

Arithmetic expansion would take place
if limit string were not quoted.
$((5 + 3))

A a single backslash would echo
if limit string were not quoted.
\\

SpecialCharTest

# 8. heredocments传递的内容输出到文件
# 前后的() 必须得有

OUTFILE=generated.sh 
(
cat <<'EOF'
#!/bin/bash

echo "This is a generated shell script."
#  Note that since we are inside a subshell,
#+ we can not access variables in the "outside" script.

echo "Generated file will be named: $OUTFILE"
#  Above line will not work as normally expected
#+ because parameter expansion has been disabled.
#  Instead, the result is literal output.

a=7
b=3

let "c = $a * $b"
echo "c = $c"

exit 0
EOF
) > $OUTFILE

# 9. 使用heredocument做命令替换
variable=$(cat <<SETVAR
This variable
runs over multiple lines.
SETVAR
)

echo "$variable"

# 10. Here documents与函数function设置
GetPersonalData ()
{
  read firstname
  read lastname
  read address
  read city 
  read state 
  read zipcode
} # This certainly appears to be an interactive function, but . . .


# Supply input to the above function.
GetPersonalData <<RECORD001
Bozo
Bozeman
2726 Nondescript Dr.
Bozeman
MT
21226
RECORD001

echo
echo "$firstname $lastname"
echo "$address"
echo "$city, $state $zipcode"
echo

# 11. "Anonymous" Here Document
# 用来测试变量是否有设置
: <<TESTVARIABLES
${HOSTNAME?}${USER?}${MAIL?}${asdfasdf?}  # Print error message if one of the variables not set.
# 					  # heredocuments.sh:行210: asdfasdf: 参数为空或未设置 
TESTVARIABLES


# 12. 使用Here Document 对代码进行多段注释
# 如下行将不会进行打印，也不会报错
# 类似于c中的多行注释
# /*
#  *
#  */
#  
: <<COMMENTBLOCK
echo "This line will not echo."
This is a comment line missing the "#" prefix.
This is another comment line missing the "#" prefix.

&*@!!++=
The above line will cause no error message,
because the Bash interpreter will ignore it.
COMMENTBLOCK

# 如果:没有顶行写，则需要对COMMENTBLOCK 进行引用, 强引用或弱引用均可以
  : <<"COMMENTBLOCK"
  echo "This line will not echo."
  &*@!!++=
  ${foo_bar_bazz?}
  $(rm -rf /tmp/foobar/)
  $(touch my_build_directory/cups/Makefile)
COMMENTBLOCK


# 13. 使用here documents打印帮助信息
if [ "$1" = "-h"  -o "$1" = "--help" ]     # Request help.
then
cat <<DOCUMENTATIONXX
List the statistics of a specified directory in tabular format.
---------------------------------------------------------------
The command-line parameter gives the directory to be listed.
If no directory specified or directory specified cannot be read,
then list the current working directory.

DOCUMENTATIONXX
exit $DOC_REQUEST
fi
