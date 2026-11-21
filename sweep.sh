#!/bin/bash
REPS=${REPS:-2}; DUR=${DUR:-30}; OUT=${OUT:-results_fixed.csv}
DC="docker compose exec -T"; SRC="source /opt/ros/jazzy/setup.bash"
echo "rmw,qos,size_kb,loss_pct,rx,expected,delivered_pct,fps,p50,p95,p99,max,stall_s" > $OUT
for LOSS in 0 1 3; do
 $DC pub tc qdisc del dev eth0 root 2>/dev/null
 $DC pub tc qdisc add dev eth0 root netem delay 20ms 5ms loss ${LOSS}% limit 10000
 for SIZE in 40 100 300; do
  for QOS in best_effort reliable; do
   for RMW in rmw_fastrtps_cpp rmw_cyclonedds_cpp; do
    for REP in $(seq $REPS); do
     $DC pub pkill -f pub.py; sleep 2
     $DC -d -e SIZE_KB=$SIZE -e REL=$QOS -e RMW_IMPLEMENTATION=$RMW pub bash -c "$SRC && python3 pub.py"
     sleep 3
     LINE=$($DC -e REL=$QOS -e DUR=$DUR -e RMW_IMPLEMENTATION=$RMW sub bash -c "$SRC && timeout $((DUR+20)) python3 sub.py" | tail -1)
     echo "$RMW,$QOS,$SIZE,$LOSS,$LINE" | tee -a $OUT
    done
   done
  done
 done
done
$DC pub pkill -f pub.py
