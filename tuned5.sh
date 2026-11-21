#!/bin/bash
source ./helpers.sh
OUT=tuned5.csv; REPS=3
echo "rmw,qos,size,vars,rx,expected,delivered_pct,fps,p50,p95,p99,max,stall_s" > $OUT
docker compose down; RMW=rmw_fastrtps_cpp docker compose up -d; sleep 5
FD=rmw_fastrtps_cpp
fx() { echo FASTDDS_DEFAULT_PROFILES_FILE=/tuned/$1 FASTRTPS_DEFAULT_PROFILES_FILE=/tuned/$1 RMW_FASTRTPS_USE_QOS_FROM_XML=1; }

setnetem_both loss 3% delay 20ms 5ms
rep 100 reliable $FD $(fx fd-hb10.xml)
rep 100 reliable $FD $(fx fd-hb50.xml)
rep 20  reliable $FD $(fx fd-fast.xml)
rep 60  reliable $FD $(fx fd-fast.xml)
setnetem_both delay 20ms 5ms
rep 100 reliable $FD $(fx fd-fast.xml)
setnetem_both loss 5% delay 20ms 5ms
rep 40  reliable $FD $(fx fd-fast.xml)
docker compose exec -T pub pkill -f pub.py
