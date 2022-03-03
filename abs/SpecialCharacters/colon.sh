#!/bin/bash
#
# This is the shell equivalent of a "NOP" (no op, a do-nothing operation). 
# It may be considered a synonym for the shell builtin true. 
# The ":" command is itself a Bash builtin, and its exit status is true (0).
while :
do
   # operation-1
   # operation-2
   # ...
   # operation-n
    echo 
    break
done

# Same as:
#    while true
#    do
#      ...
#    done

# Placeholder in if/then test:
if condition
then :   # Do nothing and branch ahead
else     # Or else ...
   #take-some-action
   echo
fi

# A colon can serve as a placeholder in an otherwise empty function.
not_empty ()
{
  :
} # Contains a : (null command), and so is not empty.
