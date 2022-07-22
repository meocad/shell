#!/bin/bash
#
# 1. break 
# The break command may optionally take a parameter. 
# A plain break terminates only the innermost loop in which it is embedded, but a break N breaks out of N levels of loop.

# "break N" breaks out of N level loops.

for outerloop in 1 2 3 4 5
do
  echo -n "Group $outerloop:   "

  # --------------------------------------------------------
  for innerloop in 1 2 3 4 5
  do
    echo -n "$innerloop "

    if [ "$innerloop" -eq 3 ]
    then
      # break  # Try   break 2   to see what happens.
      break 2  # 结束从里到外第2个循环
      # break  # 结束离自己最近的那个循环
             # ("Breaks" out of both inner and outer loops.)
    fi
  done
  # --------------------------------------------------------

  echo
done

# 2. continue
# continue optionally takes a parameter. 
# A plain continue cuts short the current iteration within its loop and begins the next. 
# A continue N terminates all remaining iterations at its loop level and continues with the next iteration at the loop, N levels above.
for outer in I II III IV V           # outer loop
do
  echo; echo -n "Group $outer: "

  # --------------------------------------------------------------------
  for inner in 1 2 3 4 5 6 7 8 9 10  # inner loop
  do

    if [[ "$inner" -eq 7 && "$outer" = "III" ]]
    then
      continue 2  # Continue at loop on 2nd level, that is "outer loop".
                  # Replace above line with a simple "continue"
                  # to see normal loop behavior.
    fi  

    echo -n "$inner "  # 7 8 9 10 will not echo on "Group III."
  done  
  # --------------------------------------------------------------------

done

# 上面的loop运行结果：
: '
Group 1:   1 2 3
Group I: 1 2 3 4 5 6 7 8 9 10
Group II: 1 2 3 4 5 6 7 8 9 10
Group III: 1 2 3 4 5 6
Group IV: 1 2 3 4 5 6 7 8 9 10
Group V: 1 2 3 4 5 6 7 8 9 10
'
# 



