#!/bin/bash
# trap 'echo before execute line:$LINENO' DEBUG

BASE=$(cd "$(dirname $0)" || exit; pwd -P)

WORK_DIR=${BASE}/Exercise

CURRENT_DIR=$(date +%Y-%m-%d)

# string="aa"
# [ -n "$string" ] || echo "expr 2" && echo "expr 3" || echo "expr 4" &&  [ -z  "$string " ] &&  echo "expr  6"  || echo "expr 7"
# [ -f "${Script_BASE}/$OSS_BIN" -a -f "~/.ossconfig" ] || echo "ossutil64 or config file is not exists, please check!" && exit

# 以下结果退出不了，需要排查
# cd $BASE || { echo "Dir is  Not defined" ; exit; }
#if ! cd $BASE 2>/dev/null ; then echo "Dir is  Not defined" ; exit; fi

if [ ! -d "${WORK_DIR}/${CURRENT_DIR}" ];then
	mkdir "${WORK_DIR}"/"${CURRENT_DIR}"
	echo -e "Dir \e[1;32m${WORK_DIR}/${CURRENT_DIR}\e[0m created successfully."
	touch "${WORK_DIR}"/"${CURRENT_DIR}"/writable.test
else
	echo -e "current dir \e[1;31m${WORK_DIR}/${CURRENT_DIR}\e[0m is exist, pls check!"
fi

if [ -h "${BASE}/today" ];then
	rm -f ${BASE}/today
fi

ln -sv "${WORK_DIR}"/"${CURRENT_DIR}" "${BASE}"/today
