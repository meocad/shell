
let "t2 = ((a = 9, 15 / 3))"
# Set "a = 9" and "t2 = 15 / 3"

a=3;b=7
echo $[$a+$b]   # 10
echo $[$a*$b]   # 21

# The comma operator can also concatenate strings.
for file in /{,usr/}bin/*calc
#             ^    Find all executable files ending in "calc"
#+                 in /bin and /usr/bin directories.
do
        if [ -x "$file" ]
        then
          echo $file
        fi
done
# results:
    # /bin/ipcalc
    # /usr/bin/kcalc
    # /usr/bin/oidcalc
    # /usr/bin/oocalc
