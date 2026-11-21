import os, rclpy, numpy as np
from rclpy.node import Node
from sensor_msgs.msg import CompressedImage
from rclpy.qos import QoSProfile, ReliabilityPolicy

class Pub(Node):
    def __init__(s):
        super().__init__('pub')
        rel = ReliabilityPolicy.RELIABLE if os.getenv('REL','reliable')=='reliable' else ReliabilityPolicy.BEST_EFFORT
        s.p = s.create_publisher(CompressedImage, 'image', QoSProfile(depth=5, reliability=rel))
        s.seq = 0
        s.m = CompressedImage()
        s.m.format = 'jpeg'
        s.m.data = np.random.randint(0, 255, int(float(os.getenv('SIZE_KB','40'))*1024), dtype=np.uint8)
        s.create_timer(1/float(os.getenv('HZ','30')), s.tick)
    def tick(s):
        s.m.header.frame_id = str(s.seq); s.seq += 1
        s.m.header.stamp = s.get_clock().now().to_msg()
        s.p.publish(s.m)

rclpy.init(); rclpy.spin(Pub())
