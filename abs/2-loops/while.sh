# 1. 
# while 后是test-brackets场景, 方括号或者test命令
# while [ condition ] ; do
# done
# 
# example: 1
var0=0
LIMIT=10

while [ "$var0" -lt "$LIMIT" ]
#      ^                    ^
# Spaces, because these are "test-brackets" . . .
do
  echo -n "$var0 "        # -n suppresses newline.
  #             ^           Space, to separate printed out numbers.

  var0=`expr $var0 + 1`   # var0=$(($var0+1))  also works.
                          # var0=$((var0 + 1)) also works.
                          # let "var0 += 1"    also works.
done                      # Various other methods also work.

# example: 2
echo                           # Equivalent to:
while [ "$var1" != "end" ]     # while test "$var1" != "end"
do
  echo "Input variable #1 (end to exit) "
  read var1                    # Not 'read $var1' (why?).
  echo "variable #1 = $var1"   # Need quotes because of "#" . . .
  # If input is 'end', echoes it here.
  # Does not test for termination condition until top of loop.
  echo
done  

# 2. 
# while loop with multiple conditions
# while后面跟多个条件的时候
# A while loop may have multiple conditions. 
# Only the final condition determines when the loop terminates.

var1=unset
previous=$var1

while echo "previous-variable = $previous"
      echo
      previous=$var1
      [ "$var1" != quit ] # Keeps track of what $var1 was previously.
      # Four conditions on *while*, but only the final one controls loop.
      # The *last* exit status is the one that counts.
do
  echo "Input variable #1 (quit to exit) "
  read var1
  echo "variable #1 = $var1"
done

# 3.
# a while loop may employ C-style syntax by using the double-parentheses construct
#

LIMIT=10                 # 10 iterations.
a=1
((a = 1))      # a=1
# Double parentheses permit space when setting a variable, as in C.

while (( a <= LIMIT ))   #  Double parentheses,
do                       #+ and no "$" preceding variables.
  echo -n "$a "
  ((a += 1))             # let "a+=1"
  # Double parentheses permit incrementing a variable with C-like syntax.
done


# Inside its test brackets, a while loop can call a function.
t=0

condition ()
{
  ((t++))

  if [ $t -lt 5 ]
  then
    return 0  # true
  else
    return 1  # false
  fi
}

while condition    # Similar to the if-test construct, a while loop can omit the test brackets.
#     ^^^^^^^^^
#     Function call -- four loop iterations.
do
  echo "Still going: t = $t"
done
# Still going: t = 1
# Still going: t = 2
# Still going: t = 3
# Still going: t = 4


# while重定向
man ls | tail > ./filename
filename=filename
cat $filename |   # Supply input from a file.
while read line   # As long as there is another line to read ...
do
  :
done
