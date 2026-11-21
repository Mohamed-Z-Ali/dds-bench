#!/bin/bash
export COMPOSE_FILE=docker-compose.yml:docker-compose.tuned.yml
REPS=${REPS:-3}; OUT=${OUT:-tuned2.csv}
setnetem() { docker compose exec -T pub tc qdisc del dev eth0 root 2>/dev/null; docker compose exec -T pub tc qdisc add dev eth0 root netem "$@" limit 10000; }
runx() {
  local SIZE=$1 QOS=$2 RMW=$3; shift 3
  local E=(); for v in "$@"; do E+=(-e "$v"); done
  docker compose exec -T pub pkill -f pub.py; sleep 2
  docker compose exec -d -e SIZE_KB=$SIZE -e REL=$QOS -e RMW_IMPLEMENTATION=$RMW "${E[@]}" pub bash -c "source /opt/ros/jazzy/setup.bash && python3 pub.py"
  sleep 3
  echo "$RMW,$QOS,${SIZE}KB,[$*],$(docker compose exec -T -e REL=$QOS -e DUR=30 -e RMW_IMPLEMENTATION=$RMW "${E[@]}" sub bash -c "source /opt/ros/jazzy/setup.bash && timeout 50 python3 sub.py" | tail -1)"
}
rep() { for i in $(seq $REPS); do runx "$@" | tee -a $OUT; done; }

echo "rmw,qos,size,vars,rx,expected,delivered_pct,fps,p50,p95,p99,max,stall_s" > $OUT
docker compose down; RMW=rmw_cyclonedds_cpp docker compose up -d; sleep 5
setnetem loss 3% delay 20ms 5ms
CY=rmw_cyclonedds_cpp; FD=rmw_fastrtps_cpp
rep 100 reliable $CY
rep 100 reliable $CY CYCLONEDDS_URI=file:///tuned/cyc-n1.xml
rep 100 reliable $CY CYCLONEDDS_URI=file:///tuned/cyc-n10.xml
docker compose exec -T sub grep -i NackDelay /tmp/cdds.log | tail -1
rep 100 reliable $FD
rep 100 reliable $FD RMW_FASTRTPS_PUBLICATION_MODE=SYNCHRONOUS
rep 100 reliable $FD RMW_FASTRTPS_PUBLICATION_MODE=ASYNCHRONOUS
docker compose exec -T pub pkill -f pub.py
