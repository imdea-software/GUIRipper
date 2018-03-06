#!/bin/bash
# https://github.com/reddit/docker-android-build/blob/master/tools/android-wait-for-emulator.sh

#echo "Waiting for EMU"
sec=${TIME_TOOL_SEC}
time_inter_emu_boot=120

emu_log_path=${1:-EMU_LOG_PATH}
restart=${2:-"1"}

function msg() {
    local tab=${1}
    local opt=${2}
    local msg_str=${3}
    local error_color="\e[31m"
    local warn_color="\e[33m"
    local info_color="\033[0;36m"
    local reset_color="\e[0m"
    local color=${reset_color}
    local str=""

    case ${opt} in
        e|error) color=${error_color} ;;
        w|warn) color=${warn_color} ;;
        i|info) color=${info_color} ;;
        d|debug) str="${NAME}: DEBUG: "; color=${info_color} ;;
        *) color=${reset_color} ;;
    esac
    v=$(printf "%0.s\t" {1..${tab}})
    str=${v}${str}${msg_str}
    echo -e "${color}${str}${reset_color}"
}


function wait_for_boot_complete {
  # https://gist.github.com/stackedsax/2639601
  local boot_property=$1
  local boot_property_test=$2
  echo -n "[emulator]     Checking: ${boot_property} ... "
  local result=`adb shell ${boot_property} 2>/dev/null | grep "${boot_property_test}"`
  s=0
  while [ -z $result ]; do
    sleep 1
    result=`adb shell ${boot_property} 2>/dev/null | grep "${boot_property_test}"`
    if [[ ${restart} -eq 1 ]] && [[ ${s} -eq ${time_inter_emu_boot} ]]; then
      echo ""; echo "[emulator]     Restarting..."
      echo "[emulator]     Restarting..." >> ${emu_log_path}
      kill -9 `ps | grep emulator | awk '{print $1}'` &> /dev/null
      ${ANDROTEST_SCRIPTS_RUNEMU_FILEPATH} ${emu_log_path}
    fi
    s=$((${s}+1))
  done
  # echo "[emulator]     Checking: ${boot_property} ... OK"
  echo "OK"
}


date1=$(date +"%s")


echo "[emulator] Waiting for emulator to boot completely"
adb wait-for-device
wait_for_boot_complete "getprop dev.bootcomplete" 1
wait_for_boot_complete "getprop sys.boot_completed" 1
#wait_for_boot_complete "getprop init.svc.bootanim" "stopped"
echo "[emulator] All boot properties succesful"

echo -n " OK emulator is running... "
date2=$(date +"%s")
diff=$(($date2-$date1))
echo "took $(($diff / 60)) minutes and $(($diff % 60)) seconds."
exit 0
