# Variable expansion / Substring replacement
#
# 1. ${var:pos}
#   Variable var expanded, starting from offset pos.
#

# 2. ${var:pos:len}
#   Expansion to a max of len characters of variable var, from offset pos.

# 3. ${var/Pattern/Replacement}
#   First match of Pattern, within var replaced with Replacement.
#   If Replacement is omitted, then the first match of Pattern is replaced by nothing, that is, deleted.
stringZ=abcABC123ABCabc
echo ${stringZ/abc/XYZ}     # XYZABC123ABCabc
echo ${stringZ/abc/}        # ABC123ABCabc

# 4. ${var//Pattern/Replacement}
#   Global replacement. All matches of Pattern, within var replaced with Replacement.
#   if Replacement is omitted, then all occurrences of Pattern are replaced by nothing, that is, deleted.
stringZ=abcABC123ABCabc
echo ${stringZ//abc/XYZ}    # XYZABC123ABCXYZ
echo ${stringZ//abc/}       # ABC123ABC


var1=abcd-1234-defg
echo "var1 = $var1"

t=${var1#*-*}
echo "var1 (with everything, up to and including first - stripped out) = $t"
#  t=${var1#*-}  works just the same,
#+ since # matches the shortest string,
#+ and * matches everything preceding, including an empty string.

t=${var1##*-*}
echo "If var1 contains a \"-\", returns empty string...   var1 = $t"

t=${var1%*-*}
echo "var1 (with everything from the last - on stripped out) = $t"

echo

# -------------------------------------------
path_name=/home/bozo/ideas/thoughts.for.today
# -------------------------------------------
echo "path_name = $path_name"
t=${path_name##/*/}
echo "path_name, stripped of prefixes = $t"
# Same effect as   t=`basename $path_name` in this particular case.
#  t=${path_name%/}; t=${t##*/}   is a more general solution,
#+ but still fails sometimes.
#  If $path_name ends with a newline, then `basename $path_name` will not work,
#+ but the above expression will.
# (Thanks, S.C.)

t=${path_name%/*.*}
# Same effect as   t=`dirname $path_name`
echo "path_name, stripped of suffixes = $t"
# These will fail in some cases, such as "../", "/foo////", # "foo/", "/".
#  Removing suffixes, especially when the basename has no suffix,
#+ but the dirname does, also complicates matters.
# (Thanks, S.C.)

echo

t=${path_name:11}
echo "$path_name, with first 11 chars stripped off = $t"
t=${path_name:11:5}
echo "$path_name, with first 11 chars stripped off, length 5 = $t"

echo

t=${path_name/bozo/clown}
echo "$path_name with \"bozo\" replaced  by \"clown\" = $t"
t=${path_name/today/}
echo "$path_name with \"today\" deleted = $t"
t=${path_name//o/O}
echo "$path_name with all o's capitalized = $t"
t=${path_name//o/}
echo "$path_name with all o's deleted = $t"


# 5. ${var/#Pattern/Replacement}
#   If prefix of var matches Pattern, then substitute Replacement for Pattern.

# 6. ${var/%Pattern/Replacement}
#   If suffix of var matches Pattern, then substitute Replacement for Pattern.
#
# 
v0=abc1234zip1234abc    # Original variable.
echo "v0 = $v0"         # abc1234zip1234abc
echo

# Match at prefix (beginning) of string.
v1=${v0/#abc/ABCDEF}    # abc1234zip1234abc
                        # |-|
echo "v1 = $v1"         # ABCDEF1234zip1234abc
                        # |----|

# Match at suffix (end) of string.
v2=${v0/%abc/ABCDEF}    # abc1234zip123abc
                        #              |-|
echo "v2 = $v2"         # abc1234zip1234ABCDEF
                        #               |----|

echo

#  ----------------------------------------------------
#  Must match at beginning / end of string,
#+ otherwise no replacement results.
#  ----------------------------------------------------
v3=${v0/#123/000}       # Matches, but not at beginning.
echo "v3 = $v3"         # abc1234zip1234abc
                        # NO REPLACEMENT.
v4=${v0/%123/000}       # Matches, but not at end.
echo "v4 = $v4"         # abc1234zip1234abc
                        # NO REPLACEMENT.


# 7. ${!varprefix*}, ${!varprefix@}
#   Matches names of all previously declared variables beginning with varprefix.

xyz23=whatever
xyz24=

a=${!xyz*}         #  Expands to *names* of declared variables
# ^ ^   ^           + beginning with "xyz".
echo "a = $a"      #  a = xyz23 xyz24
a=${!xyz@}         #  Same as above.
echo "a = $a"      #  a = xyz23 xyz24

echo "---"

abc23=something_else
b=${!abc*}
echo "b = $b"      #  b = abc23
c=${!b}            #  Now, the more familiar type of indirect reference.
echo $c            #  something_else
