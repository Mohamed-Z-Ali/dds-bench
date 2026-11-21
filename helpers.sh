export COMPOSE_FILE=docker-compose.yml:docker-compose.tuned.yml
setnetem() {   # data direction only (pub egress); also clears sub
  docker compose exec -T pub tc qdisc del dev eth0 root 2>/dev/null
  docker compose exec -T sub tc qdisc del dev eth0 root 2>/dev/null
  docker compose exec -T pub tc qdisc add dev eth0 root netem "$@" limit 10000; }
setnetem_both() { setnetem "$@"; docker compose exec -T sub tc qdisc add dev eth0 root netem "$@" limit 10000; }
runx() {
  local SIZE=$1 QOS=$2 RMW=$3; shift 3
  local E=(); for v in "$@"; do E+=(-e "$v"); done
  docker compose exec -T pub pkill -f pub.py; sleep 2
  docker compose exec -d -e SIZE_KB=$SIZE -e REL=$QOS -e RMW_IMPLEMENTATION=$RMW "${E[@]}" pub bash -c "source /opt/ros/jazzy/setup.bash && python3 pub.py"
  sleep 3
  echo "$RMW,$QOS,${SIZE}KB,[$*],$(docker compose exec -T -e REL=$QOS -e DUR=30 -e RMW_IMPLEMENTATION=$RMW "${E[@]}" sub bash -c "source /opt/ros/jazzy/setup.bash && timeout 50 python3 sub.py" | tail -1)"
}
rep() { for i in $(seq ${REPS:-3}); do runx "$@" | tee -a $OUT; done; }
