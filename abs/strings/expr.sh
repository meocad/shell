# 1. expr match
# expr match "$string" '$substring'
# 输出匹配字符个数

stringZ=abcABC123ABCabc
#       |------|
#       12345678

echo `expr match "$stringZ" 'abc[A-Z]*.2'`   # 8
echo `expr "$stringZ" : 'abc[A-Z]*.2'`       # 8

# expr match "$string" '.*\($substring\)'
# expr "$string" : '\($substring\)'
# 上面两个语句意思一样, 从字符串的起始开始匹配
# Extracts $substring at beginning of $string, where $substring usually is a regular expression. 
# 
stringZ=abcABC123ABCabc
#       =======	    

echo `expr match "$stringZ" '\(.[b-c]*[A-Z]..[0-9]\)'`   # abcABC1
echo `expr "$stringZ" : '\(.[b-c]*[A-Z]..[0-9]\)'`       # abcABC1
echo `expr "$stringZ" : '\(.......\)'`                   # abcABC1
# All of the above forms give an identical result.

# expr match "$string" '.*\($substring\)'
# expr "$string" : '.*\($substring\)'
# 上面两个语句意思一样，从字符串后面提取
#
stringZ=abcABC123ABCabc
#                ======

echo `expr match "$stringZ" '.*\([A-C][A-C][A-C][a-c]*\)'`    # ABCabc
echo `expr "$stringZ" : '.*\(......\)'`                       # ABCabc


# 2. expr index 
# expr index $string $substring
# Numerical position in $string of first character in $substring that matches.
# 返回 string中包含 substring 中任意字符的第一个位置。

stringZ=abcABC123ABCabc
#       123456 ...
echo `expr index "$stringZ" C12`             # 6
                                             # C position.

echo `expr index "$stringZ" 1c`              # 3
# 'c' (in #3 position) matches before '1'.
# 返回 stringZ中包含 1c 中任意字符的第一个位置。


# 3. expr substr
# expr substr $string $position $length
# Extracts $length characters from $string starting at $position.
# 
stringZ=abcABC123ABCabc
#       123456789......
#       1-based indexing.

echo `expr substr $stringZ 1 2`              # ab
echo `expr substr $stringZ 4 3`              # ABC


# 4. 
