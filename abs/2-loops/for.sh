
# 1. 
# for arg in [list]
# do
#   command[s] ...
# done

# for arg in "$var1" "$var2" "$var3" ... "$varN"  
# example:1
for planet in Mercury Venus Earth Mars Jupiter Saturn Uranus Neptune Pluto
do
  echo $planet  # Each planet on a separate line.
done

# example:2
for planet in "Mercury Venus Earth Mars Jupiter Saturn Uranus Neptune Pluto"
    # All planets on same line.
    # Entire 'list' enclosed in quotes creates a single variable.
    # Why? Whitespace incorporated into the variable.
do
  echo $planet
done

# example:3
for planet in "Mercury 36" "Venus 67" "Earth 93"  "Mars 142" "Jupiter 483"
do
  # 将一个变量改成多个位置参数
  set -- $planet  #  Parses variable "planet"
                  #+ and sets positional parameters.
  #  The "--" prevents nasty surprises if $planet is null or
  #+ begins with a dash.

  #  May need to save original positional parameters,
  #+ since they get overwritten.
  #  One way of doing this is to use an array,
  #         original_params=("$@")

  echo "$1		$2,000,000 miles from the sun"
  #-------two  tabs---concatenate zeroes onto parameter $2
done

# 2.
# for arg in $variables
# do
#   command[s] ...
# done

FILES="/usr/sbin/accept
/usr/sbin/pwck
/usr/sbin/chroot
/usr/bin/fakefile
/sbin/badblocks
/sbin/ypbind"     # List of files you are curious about.
                  # Threw in a dummy file, /usr/bin/fakefile.

# example: 1
for file in $FILES
do

  if [ ! -e "$file" ]       # Check if file exists.
  then
    echo "$file does not exist."; echo
    continue                # On to next.
   fi

  ls -l $file | awk '{ print $8 "         file size: " $5 }'  # Print 2 fields.
  whatis `basename $file`   # File info.
  echo
done  

# for loop contains wild cards (* and ?) used in filename expansion, then globbing takes place.
filename="*txt"

# example: 2
for file in $filename
do
 echo "Contents of $file"
 echo "---"
 cat "$file"
 echo
done

# example: 3
for file in *
#           ^  Bash performs filename expansion
#+             on expressions that globbing recognizes.
do
  ls -l "$file"  # Lists all files in $PWD (current directory).
  #  Recall that the wild card character "*" matches every filename,
  #+ however, in "globbing," it doesn't match dot-files.

  #  If the pattern matches no file, it is expanded to itself.
  #  To prevent this, set the nullglob option
  #+   (shopt -s nullglob).
  # 在没有匹配结果的情况下输出结果为NULL而不是匹配字(pattern)本身
done

# example: 4
for file in [jx]*
do
  rm -f $file    # Removes only files beginning with "j" or "x" in $PWD.
  echo "Removed file \"$file\"".
done


# 3. 
# for arg
# do
#   command[s] ...
# done
#
# Omitting the in [list] part of a for loop causes the loop to operate on $@
# 把“in [list]” 省略意思就相当于：  for arg in "$@"
# 给for循环传递位置参数列表进去
for i
do
  echo "位置参数:$i"
done


# 4. 
# C-style for loop
#
for ((a=1; a <= LIMIT ; a++))  # Double parentheses, and naked "LIMIT"
do
  echo -n "$a "
done                           # A construct borrowed from ksh93.

# Let's use the C "comma operator" to increment two variables simultaneously.

for ((a=1, b=1; a <= LIMIT ; a++, b++))
do  # The comma concatenates operations.
  echo -n "$a-$b "
done

# 用花括号(curly brackets)代替do..done
for((n=1; n<=10; n++)) 
# No do!
{
  echo -n "* $n *"
}
# No done!

# 或者一行写入
# 注意： 行尾要有分号
for n in 1 2 3
{  echo -n "$n "; }
echo
