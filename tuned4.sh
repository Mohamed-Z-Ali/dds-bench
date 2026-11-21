#!/bin/bash
source ./helpers.sh
OUT=tuned4.csv
echo "rmw,qos,size,vars,rx,expected,delivered_pct,fps,p50,p95,p99,max,stall_s" > $OUT
docker compose down; RMW=rmw_cyclonedds_cpp docker compose up -d; sleep 5
CY=rmw_cyclonedds_cpp; FD=rmw_fastrtps_cpp
N1=CYCLONEDDS_URI=file:///tuned/cyc-n1.xml
W=CYCLONEDDS_URI=file:///tuned/cyc-w.xml
FX=(FASTDDS_DEFAULT_PROFILES_FILE=/tuned/fd-fast.xml FASTRTPS_DEFAULT_PROFILES_FILE=/tuned/fd-fast.xml RMW_FASTRTPS_USE_QOS_FROM_XML=1)

REPS=2
setnetem_both delay 20ms 5ms          # control: delayed return path, no loss
rep 100 reliable $CY
rep 100 reliable $CY $W
docker compose exec -T sub grep -iE "Watermarks|WhcHigh|error|invalid" /tmp/cdds.log | tail -5

REPS=3
setnetem_both loss 3% delay 20ms 5ms
rep 100 reliable $CY $W
rep 40  reliable $CY $N1
rep 40  reliable $CY $W
rep 40  reliable $FD "${FX[@]}"
setnetem_both loss 1% delay 20ms 5ms
rep 100 reliable $CY $N1
rep 100 reliable $CY $W
rep 100 reliable $FD "${FX[@]}"
docker compose exec -T pub pkill -f pub.py
