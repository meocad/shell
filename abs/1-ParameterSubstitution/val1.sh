#!/bin/sh
#

# 1. ${parameter}
# Same as $parameter, i.e., value of the variable parameter. 
# In certain contexts, only the less ambiguous ${parameter} form works.

your_id=${USER}-on-${HOSTNAME}
echo "$your_id"
#
echo "Old \$PATH = $PATH"
PATH=${PATH}:/opt/bin  # Add /opt/bin to $PATH for duration of script.
echo "New \$PATH = $PATH"


# 2. ${parameter-default}, ${parameter:-default}
# If parameter not set, use default.

var1=1
var2=2
# var3 is unset.

echo ${var1-$var2}   # 1
echo ${var3-$var2}   # 2
#           ^          Note the $ prefix.

echo ${username-`whoami`}
# Echoes the result of `whoami`, if variable $username is still unset.


# 3. ${parameter-default} and ${parameter:-default} are almost equivalent.
# The extra : makes a difference only when parameter has been declared, but is null.
a1=
echo ${a1-$var2}     # 输出值为空
echo ${a1:-$var2}    # 输出值为2

# The default parameter construct finds use in providing "missing" command-line arguments in scripts.
DEFAULT_FILENAME=generic.data
filename=${1:-$DEFAULT_FILENAME}

#  From "hanoi2.bash" example:
DISKS=${1:-E_NOPARAM}   # Must specify how many disks.
#  Set $DISKS to $1 command-line-parameter,
#+ or to $E_NOPARAM if that is unset.


# 4. ${parameter=default}, ${parameter:=default}
# If parameter not set, set it to default.
# 这两个写法和上面的场景一样 
# Both forms nearly equivalent. The : makes a difference only when $parameter has been declared and is null  as above.

echo ${var=abc}   # abc 此时是因为var这个变量没有被设置，所以可以被设置为default，也就是abc
echo ${var=xyz}   # abc 此时var变量已经被上面的命令定义
# $var had already been set to abc, so it did not change.


# 5. ${parameter+alt_value}, ${parameter:+alt_value}
# If parameter set, use alt_value, else use null string.
# Both forms nearly equivalent. The : makes a difference only when parameter has been declared and is null, see below.

echo "###### \${parameter+alt_value} ########"
echo

a=${param1+xyz}
echo "a = $a"      # a =

param2=
a=${param2+xyz}
echo "a = $a"      # a = xyz          两个的区别输出值

param3=123
a=${param3+xyz}
echo "a = $a"      # a = xyz



# 
echo
echo "###### \${parameter:+alt_value} ########"
echo

a=${param4:+xyz}
echo "a = $a"      # a =

param5=
a=${param5:+xyz}
echo "a = $a"      # a =              两个的区别输出为空
# Different result from   a=${param5+xyz}

param6=123
a=${param6:+xyz}
echo "a = $a"      # a = xyz


# 6. ${parameter?err_msg}, ${parameter:?err_msg}
# If parameter set, use it, else print err_msg and abort the script with an exit status of 1.
# Both forms nearly equivalent. The : makes a difference only when parameter has been declared and is null, as above.




















