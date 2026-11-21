import os, time, rclpy, numpy as np
from rclpy.node import Node
from sensor_msgs.msg import CompressedImage
from rclpy.qos import QoSProfile, ReliabilityPolicy

DUR = float(os.getenv('DUR', '30'))

class Sub(Node):
    def __init__(s):
        super().__init__('sub')
        rel = ReliabilityPolicy.RELIABLE if os.getenv('REL','reliable')=='reliable' else ReliabilityPolicy.BEST_EFFORT
        s.create_subscription(CompressedImage, 'image', s.cb,
            QoSProfile(depth=int(os.getenv('DEPTH','5')), reliability=rel))
        s.lat, s.first, s.last, s.n = [], None, -1, 0
        s.t0, s.tfirst, s.prev, s.stall = time.time(), None, 0, 0
        s.create_timer(1.0, s.tick)
    def cb(s, m):
        now = s.get_clock().now().nanoseconds
        t = m.header.stamp.sec*10**9 + m.header.stamp.nanosec
        s.lat.append((now-t)/1e6)
        seq = int(m.header.frame_id)
        if s.first is None: s.first, s.tfirst = seq, time.time()
        s.last = max(s.last, seq); s.n += 1
    def tick(s):
        if s.n == s.prev: s.stall += 1
        s.prev = s.n
        if time.time()-s.t0 >= DUR: s.done()
    def done(s):
        a = np.array(s.lat) if s.lat else np.array([0.0])
        exp = (s.last - s.first + 1) if s.first is not None else 0
        dt = max(time.time() - (s.tfirst or s.t0), 1e-3)
        print(f"{s.n},{exp},{100*s.n/max(exp,1):.1f},{s.n/dt:.1f},"
              f"{np.percentile(a,50):.1f},{np.percentile(a,95):.1f},"
              f"{np.percentile(a,99):.1f},{a.max():.1f},{s.stall}", flush=True)
        os._exit(0)

rclpy.init(); rclpy.spin(Sub())
