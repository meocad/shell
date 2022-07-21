# Variable length / Substring removal

# 1. ${#var}
# String length (number of characters in $var).
# For an array, ${#array} is the length of the first element in the array.
#
# 例外：
#   1).  ${#*} and ${#@} give the number of positional parameters. 
#   2).  For an array, ${#array[*]} and ${#array[@]} give the number of elements in the array.

E_NO_ARGS=65

if [ $# -eq 0 ]  # Must have command-line args to demo script.
then
  echo "Please invoke this script with one or more command-line arguments."
  exit $E_NO_ARGS
fi  

var01=abcdEFGH28ij
echo "var01 = ${var01}"
echo "Length of var01 = ${#var01}"
# Now, let's try embedding a space.
var02="abcd EFGH28ij"
echo "var02 = ${var02}"
echo "Length of var02 = ${#var02}"

echo "Number of command-line arguments passed to script = ${#@}"
echo "Number of command-line arguments passed to script = ${#*}"

# 2. ${var#Pattern}, ${var##Pattern}
# ${var#Pattern} Remove from $var the shortest part of $Pattern that matches the front end of $var.
# ${var##Pattern} Remove from $var the longest part of $Pattern that matches the front end of $var.

# Strips leading zero(s) from argument passed.
strip_leading_zero ()  #  Strip possible leading zero(s)
{                      #+ from argument passed.
  return=${1#0}        #  The "1" refers to "$1" -- passed arg.
}                      #  The "0" is what to remove from "$1" -- strips zeros.


strip_leading_zero2 ()               # Strip possible leading zero(s), since otherwise
{                                    # Bash will interpret such numbers as octal values.
  shopt -s extglob                   # Turn on extended globbing.
  local val=${1##+(0)}               # Use local variable, longest matching series of 0's.
  shopt -u extglob                   # Turn off extended globbing.
  _strip_leading_zero2=${val:-0}
                                     # If input was 0, return 0 instead of "".
}


echo `basename $PWD`        # Basename of current working directory.
echo "${PWD##*/}"           # Basename of current working directory.
echo
echo `basename $0`          # Name of script.
echo $0                     # Name of script.
echo "${0##*/}"             # Name of script.
echo
filename=test.data
echo "${filename##*.}"      # data
                            # Extension of filename.


# 3. ${var%Pattern}, ${var%%Pattern}
# ${var%Pattern} Remove from $var the shortest part of $Pattern that matches the back end of $var.
# ${var%%Pattern} Remove from $var the longest part of $Pattern that matches the back end of $var.

# Pattern matching  using the # ## % %% parameter substitution operators.

var1=abcd12345abc6789
pattern1=a*c  # * (wild card) matches everything between a - c.

echo
echo "var1 = $var1"           # abcd12345abc6789
echo "var1 = ${var1}"         # abcd12345abc6789
                              # (alternate form)
echo "Number of characters in ${var1} = ${#var1}"
echo

echo "pattern1 = $pattern1"   # a*c  (everything between 'a' and 'c')
echo "--------------"
echo '${var1#$pattern1}  =' "${var1#$pattern1}"    #         d12345abc6789
# Shortest possible match, strips out first 3 characters  abcd12345abc6789
#                                     ^^^^^               |-|
echo '${var1##$pattern1} =' "${var1##$pattern1}"   #                  6789      
# Longest possible match, strips out first 12 characters  abcd12345abc6789
#                                    ^^^^^                |----------|

echo; echo; echo

pattern2=b*9            # everything between 'b' and '9'
echo "var1 = $var1"     # Still  abcd12345abc6789
echo
echo "pattern2 = $pattern2"
echo "--------------"
echo '${var1%pattern2}  =' "${var1%$pattern2}"     #     abcd12345a
# Shortest possible match, strips out last 6 characters  abcd12345abc6789
#                                     ^^^^                         |----|
echo '${var1%%pattern2} =' "${var1%%$pattern2}"    #     a
# Longest possible match, strips out last 12 characters  abcd12345abc6789
#                                    ^^^^                 |-------------|

# Remember, # and ## work from the left end (beginning) of string,
#           % and %% work from the right end.

# 修改文件扩展名
#
#         rfe old_extension new_extension
#
# Example:
# To rename all *.gif files in working directory to *.jpg,
#          rfe gif jpg

E_BADARGS=65

case $# in
  0|1)             # The vertical bar means "or" in this context.
  echo "Usage: `basename $0` old_file_suffix new_file_suffix"
  exit $E_BADARGS  # If 0 or 1 arg, then bail out.
  ;;
esac


for filename in *.$1
# Traverse list of files ending with 1st argument.
do
  mv $filename ${filename%$1}$2
  #  Strip off part of filename matching 1st argument,
  #+ then append 2nd argument.
done



















