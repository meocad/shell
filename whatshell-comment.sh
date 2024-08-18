: 'This script aims at recognizing all Bourne compatible shells.
   Emphasis is on shells without any version variables.
   Please comment to mascheck@in-ulm.de'
: '$Id: whatshell.sh.comments.html,v 1.5 2021/02/13 00:37:50 xmascheck Exp xmascheck $'
: 'fixes are tracked on www.in-ulm.de/~mascheck/various/whatshell/'

LC_ALL=C; export LC_ALL
: 'trivial cases first, yet parseable for historic shells'
	: '7th edition Bourne shell aka the V7 shell did not know # as comment sign, yet.'
	: 'Workaround: the argument to the : null command can be considered a comment,'
	: 'protect it, because the shell would have to parse it otherwise.'

case $BASH_VERSION in *.*) { echo "bash $BASH_VERSION";exit;};;esac
	: '"exec echo" would call the external command instead of the built-in.'
	: 'Thus: echo and exit, in the current context with { ... }'
	: 'It is not defined as function until later, because Bourne shells before SVR2 do not know functions.'

case $ZSH_VERSION  in *.*) { echo "zsh $ZSH_VERSION";exit;};;esac
case "$VERSION" in *zsh*) { echo "$VERSION";exit;};;esac
	: 'zsh 2.x has "$VERSION"'

case  "$SH_VERSION" in *PD*) { echo "$SH_VERSION";exit;};;esac
case "$KSH_VERSION" in *PD*|*MIRBSD*) { echo "$KSH_VERSION";exit;};;esac
case "$POSH_VERSION" in 0.[1234]|0.[1234].*) \
     { echo "posh $POSH_VERSION, possibly slightly newer, yet<0.5";exit;}
  ;; *.*|*POSH*) { echo "posh $POSH_VERSION";exit;};; esac
	: 'In some posh versions something went wrong when compiling in the version'
	: '(a literal "POSH_VERSION" instead of the variable value)'

case $YASH_VERSION in *.*) { echo "yash $YASH_VERSION";exit;};;esac

: 'traditional Bourne shell'
(eval ': $(:)') 2>/dev/null || {
	: 'Traditional Bourne shells do not implement the $( ) form of command substitution.'
	: 'Use eval to uncouple the failing part from the current script, and evaluate the delivered exit status.'

  case `(:^times) 2>&1` in *0m*):;;
    *)p=' (and pipe check for Bourne shell failed)';;esac
	: 'Almost all traditional Bourne shells implement ^ as an alias for |.'
	: 'Use a built-in with output to verify: times.'

  : 'pre-SVR2: no functions, no echo built-in.'
  (eval 'f(){ echo :; };f') >/dev/null 2>&1 || {
	: 'Bourne shells before SVR2 do not know functions. Protect the possible failure with eval (like above).'

    ( eval '# :' ) 2>/dev/null || { echo '7th edition Bourne shell'"$p";exit;}
	: '7th ed had not implemented # as comment sign, yet.'

    ( : ${var:=value} ) 2>/dev/null ||
	: 'test for NULL in the parameter expansion (with the : notation) came with System III.'
	: 'Otherwise, it is a 7th ed shell with comments.  BSD added this, and some current ports:'

    { echo '7th edition Bourne shell, # comments (BSD, or port)'"$p";exit;}

    set x x; shift 2;test "$#" != 0 && { echo 'System III Bourne shell'"$p";exit;}
    { echo 'SVR1 Bourne shell'"$p";exit;}
	: '"shift n" came with SVR1.'

  }
}; : 'keep syntactical block small for pre-SVR2'
	# Since SVR2 functions are available, so the block ends as soon as all possible pre-SVR2 variants
	# are done.  From now on we can use a function for a shorter echo+exit.

myex(){ echo "$@";exit;} # "exec echo" might call the external command
	# Stephane Chazelas points out that the external echo is not always called: called in the Bourne
	# shell, ash, bash and the AT&T variants of ksh, but not in zsh, pdksh and its derivatives.

(eval ': $(:)') 2>/dev/null || {
  (set -m; set +m) 2>/dev/null && {
	# SVR4 implements job control, which can be toggled with the flag "m".

    priv=0;(priv work)>/dev/null 2>&1 &&
      case `(priv work)2>&1` in *built*|*found*) priv=1;;esac
	# SVR4.2 implements the priv built-in. work is a reliable argument.
	# There are pre-SVR4.2 shells, which alread accept the syntax but do not implement it.
	# Even the unimplemented built-in can exit with 0, thus the output has to be checked.

    read_r=0;(echo|read -r dummy 2>/dev/null) && read_r=1
	# checking for "read -r" is an alternative.

    a_read=0;unset var;set -a;read var <&-;case `export` in
       *var*) a_read=1;;esac
	# Bugfix after SVR4.0: variables set with "read" are also exported.

    case_in=0;(eval 'case x in in) :;;esac')2>/dev/null && case_in=1
	# SunOS 5 and its descendant are probably the only variants which have this bug fixed:
        # elsewhere the second "in" wrongly is still recognized as syntax (and thus an error)
        # instead as some arbitrary pattern.

    ux=0;a=`(notexistent_cmd) 2>&1`; case $a in *UX*) ux=1;;esac
	# Some other post SVR4.0 shells already implement "UX: ..." error messages
	# which had been defined in the SVID, the System V Interface Definition.

    case $priv$ux$read_r$a_read$case_in in
       11110) myex 'SVR4.2 MP2 Bourne shell'
    ;; 11010) myex 'SVR4.2 Bourne shell'
    ;; 10010|01010) myex 'SVR4.x Bourne shell (between 4.0 and 4.2)'
    ;; 00111) myex 'SVR4 Bourne shell (SunOS 5 schily variant, before 2016-02-02)'
    ;; 00101) myex 'SVR4 Bourne shell (SunOS 5 heirloom variant)'
    ;; 00001) myex 'SVR4 Bourne shell (SunOS 5 variant)'
    ;; 00000) myex 'SVR4.0 Bourne shell'
    ;; *)     myex 'unknown SVR4 Bourne shell variant' ;;esac
  }
	# It was not a SVR4 shell.  For SVR3 check two features,
	# whether "read" without arguments yields an error (the safe check)
	# and whether "getopts" is implemented.  This is the more important change,
	# but there are OSR variants where it was removed.

  r=0; case `(read) 2>&1` in *"missing arguments"*) r=1;;esac
  g=0; (set -- -x; getopts x var) 2>/dev/null && g=1
  case $r$g in
     11) myex 'SVR3 Bourne shell'
  ;; 10) myex 'SVR3 Bourne shell (but getopts built-in is missing)'
  ;; 01) myex 'SVR3 Bourne shell (but read built-in does not match)'
  ;; 00) (builtin :) >/dev/null 2>&1 &&
	myex '8th edition (SVR2) Bourne shell'"$p"
	# No SVR3, thus SVR2 - or 8th edition.  The latter comes with "builtin" instead of "type".

	(type :) >/dev/null 2>&1 && myex 'SVR2 Bourne shell'"$p" ||
	myex 'SVR2 shell (but type built-in is missing)'"$p"
	# I do not know any Bourne shell without "type" built-in, but if there is one it will be caught here.
  ;;esac
}
	# Schily sh since 2016-02-02 is the only traditional-like variant which implements $().
	# So try another simple feature which is only implemented in traditional Bourne shells.
	# Test this separately, because there's also a variant which doesn't implement ^.
	# Since 2016-05-24 the shell is even posix like and thus implements $(( ))

case $( (:^times) 2>&1) in *0m*)
  case `eval '(echo $((1+1))) 2>/dev/null'` in
    2) myex 'SVR4 Bourne shell (SunOS 5 schily variant, posix-like, since 2016-05-24)'
  ;;*) myex 'SVR4 Bourne shell (SunOS 5 schily variant, since 2016-02-02, before 2016-05-24)'
  ;;esac
;;esac
	# Since 2016-08-08, when running in posix mode (called with "-o posix", or compiled to posix mode),
	# it even doesn't accept ^ as |. But it implements type -F.

type -F >/dev/null 2>&1 &&
  myex 'SVR4 Bourne shell (SunOS 5 schily variant, since 2016-08-08, in posix mode)'

# Almquist shell aka ash
(typeset -i var) 2>/dev/null || {
	# typeset is Korn shell specific. If it is not implemented it must be an Almquist shell.
	# There is a better check for Almquist shells ("%func" as suffix in PATH component), but it requires file system access.

  case $SHELLVERS in "ash 0.2") myex 'original ash';;esac
	# Only the original shell had a version variable.

  test "$1" = "debug" && debug=1
	# Safe the argument to this script before we are fiddling with the positional parameters.

  n=1; case `(! :) 2>&1` in *not*) n=0;;esac
	# negation came with 4.4 BSD Alpha

  b=1; case `echo \`:\` ` in '`:`') b=0;;esac
	# nesting of `...` was possible with 4.4 BSD and with the 386BSD 0.2.4 patchkit,
	# which was also used by NetBSD 0.9 and Minix.
	# Minix has a bugfix about getopt concerning OPTIND:

  g=0; { set -- -x; getopts x: var 
         case $OPTIND in 2) g=1;;esac;} >/dev/null 2>&1
	# OPTIND is set correctly if getopt yields an error if an argument to an option is missing.
	# Some busybox sh might not have getopts available, so even redirect errors from the block.
        # FreeBSD 11 had a getopts fix.

  p=0; (eval ': ${var#value}') 2>/dev/null && p=1
	# The # and % form of parameter expansion is implemented in 4.4 BSD Lite2
	# and thus BSD/OS 3.x, but also since NetBSD 1.2.

  r=0; ( (read</dev/null)) 2>/dev/null; case $? in 0|1|2)
	  var=`(read</dev/null)2>&1`; case $var in *arg*) r=1;;esac
	;;esac
	# read without arguments yields an error message since 4.4 BSD lite.
	# Some ash segfault upon this, so check for a clean exit status in advance.

  v=1; set x; case $10 in x0) v=0;;esac
	# NetBSD 1.3 and its descendants handle $10 as ${10} instead of ${1}0

  t=0; (PATH=;type :) >/dev/null 2>&1 && t=1
	# The original ash (accidentally?) had not implemented the "type" built-in.
	# Early Net- and FreeBSD added it.

  test -z "$debug" || echo debug '$n$b$g$p$r$v$t: ' $n$b$g$p$r$v$t
  case $n$b$g$p$r$v$t in
     00*) myex 'early ash (4.3BSD, 386BSD 0.0-p0.2.3/NetBSD 0.8)'
  ;; 010*) myex 'early ash (ash-0.2 port, Slackware 2.1-8.0,'\
	'386BSD p0.2.4, NetBSD 0.9)'
  ;; 1110100) myex 'early ash (Minix 2.x-3.1.2)'
  ;; 1000000) myex 'early ash (4.4BSD Alpha)'
  ;; 1100000) myex 'early ash (4.4BSD)'
  ;; 11001*) myex 'early ash (4.4BSD Lite, early NetBSD 1.x, BSD/OS 2.x)'
  ;; 1101100) myex 'early ash (4.4BSD Lite2, BSD/OS 3 ff)'
  ;; 1101101) myex 'ash (FreeBSD -10.x, Cygwin pre-1.7, Minix 3.1.3 ff)'
  ;; 1111101) myex 'ash (FreeBSD 11.0 ff)'
  ;; esac
  e=0; case `(PATH=;exp 0)2>&1` in 0) e=1;;esac
	# Later dash removed the "exp" built-in.

  n=0; case y in [^x]) n=1;;esac
	# Some dash and busybox use fnmatch() instead of pmatch(). Here, [^..] is equivalent to [!..].

  r=1; case `(PATH=;noexist 2>/dev/null) 2>&1` in
        *not*) r=0 ;; *file*) r=2 ;;esac
	# If a command is not found, the error message usually (except in some dash)
	# cannot be redirected in the above way.  The redirection is applied to the command
	# and not to the shell trying to call it.

  f=0; case `eval 'for i in x;{ echo $i;}' 2>/dev/null` in x) f=1;;esac
	# Usually {...} is accepted as for loop body , except in some dash.

  test -z "$debug" || echo debug '$e$n$r$a$f: ' $e$n$r$a$f 
  case $e$n$r$f in
     1100) myex 'ash (dash 0.3.8-30 - 0.4.6)'
  ;; 1110) myex 'ash (dash 0.4.7 - 0.4.25)'
  ;; 1010) myex 'ash (dash 0.4.26 - 0.5.2)'
  ;; 0120|1120|0100) myex 'ash (Busybox 0.x)'
  ;; 0110) myex 'ash (Busybox 1.x)'
  ;;esac
  a=0; case `eval 'x=1;(echo $((x)) )2>/dev/null'` in 1) a=1;;esac
	# Arithmetic expansion has not been checked earlier because ash which have not
	# implemented it, stumble really hard over it.

  x=0; case `f(){ echo $?;};false;f` in 1) x=1;;esac
	# One dash fix: is the previous exit status preserved upon entering a function?
	# Another dash fix: are unknown escape sequences printed literally?
	# The window between these two dash fixes suggests that it is the Slackware variant.

  c=0; case `echo -e '\x'` in *\\x) c=1;;esac
  test -z "$debug" || echo debug '$e$n$r$f$a$x$c: ' $e$n$r$f$a$x$c
  case $e$n$r$f$a$x$c in
     1001010) myex 'ash (Slackware 8.1 ff, dash 0.3.7-11 - 0.3.7-14)'
  ;; 10010??) myex 'ash (dash 0.3-1 - 0.3.7-10, NetBSD 1.2 - 3.1/4.0)'
  ;; 10011*)  myex 'ash (NetBSD 3.1/4.0 ff)'
  ;; 00101*)  myex 'ash (dash 0.5.5.1 ff)'
  ;; 00100*)  myex 'ash (dash 0.5.3-0.5.5)'
  ;;      *)  myex 'unknown ash'
  ;;esac
}

savedbg=$! # save unused $! for a later check

# Korn shell ksh93, $KSH_VERSION not implemented before 93t'
# protected: fatal substitution error in non-ksh
( eval 'test "x${.sh.version}" != x' ) 2>/dev/null &
wait $! && { eval 'PATH=;case $(XtInitialize 2>&1) in Usage*)
    DTKSH=" (dtksh/CDE variant)";;esac
    myex "ksh93 ${.sh.version}${DTKSH}"'; }
        # Korn shells use a special version variable syntax which is otherwise invalid,
        # to avoid that it is set in other shells.  Avoid another shell stumbling (hard) over
        # this by protecting it with eval, and (not enough) putting it into the background.
        # This is an evil hack to keep any other shell running which is unknown and hits this.
        #
        # There's a dtksh variant (probably only 93d) which implements a bunch of built-ins
        # to interact with X and Motif. XtInitialize is one of these built-ins.

# Korn shell ksh86/88
_XPG=1;test "`typeset -Z2 x=0; echo $x`" = '00' && {
	# IRIX ksh does not implement $( ) if called as "sh", except _XPG is set to 1.
	# The typeset format is ksh specific.

  case `print -- 2>&1` in *"bad option"*)
    myex 'ksh86 Version 06/03/86(/a)';; esac
	# ksh86 stumbles here.

  test "$savedbg" = '0'&& myex 'ksh88 Version (..-)11/16/88 (1st release)'
	# ksh88a wrongly sets $! to 0 instead of "nothing" if no bg job has been executed yet.

  test ${x-"{a}"b} = '{ab}' && myex 'ksh88 Version (..-)11/16/88a'
	# ...instead of expanding to {a}b since ksh88b.

  case "`for i in . .; do echo ${i[@]} ;done 2>&1`" in
    "subscript out of range"*)
    myex 'ksh88 Version (..-)11/16/88b or c' ;; esac
	# This was fixed with ksh88d.
	# No check implemented yet to distinguish between b and c.

  test "`whence -v true`" = 'true is an exported alias for :' &&
    myex 'ksh88 Version (..-)11/16/88d'
  test "`(cd /dev/null 2>/dev/null; echo $?)`" != '1' &&
    myex 'ksh88 Version (..-)11/16/88e'
	# pre-ksh88f abort execution if cd cannot change the directory.

  test "`(: $(</file/notexistent); echo x) 2>/dev/null`" = '' &&
    myex 'ksh88 Version (..-)11/16/88f'
	# pre-ksh88g abort execution if this redirection fails.

   case `([[ "-b" > "-a" ]]) 2>&1` in *"bad number"*) \
    myex 'ksh88 Version (..-)11/16/88g';;esac # fixed in OSR5euc
	# A special bug in ksh88g.

  test "`cd /dev;cd -P ..;pwd 2>&1`" != '/' &&
    myex 'ksh88 Version (..-)11/16/88g' # fixed in OSR5euc
	# pre-ksh88h wrongly do not change directory with cd -P .. if you are one below /.

  test "`f(){ typeset REPLY;echo|read;}; echo dummy|read; f;
     echo $REPLY`" = "" && myex 'ksh88 Version (..-)11/16/88h'
	# In pre-ksh88i read wrongly uses the global REPLY variable if a local has been declared with typeset.

  test $(( 010 )) = 8 &&
    myex 'ksh88 Version (..-)11/16/88i (posix octal base)'
	# The posix variant on SunOS ksh88i recognizes octal base notation, in accordance with POSIX.

  myex 'ksh88 Version (..-)11/16/88i'
}

echo 'oh dear, unknown shell. mascheck@in-ulm.de would like to know this'
