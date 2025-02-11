import time
import smbus2
from Adafruit_PCA9685 import PCA9685

i2c_bus = 1
pwm = PCA9685(address=0x40, busnum=i2c_bus)
pwm.set_pwm_freq(50)


# サーボの角度をPWMパルスに変換する関数
def angle_to_pwm(angle):
    min_pulse = 125  # 0度のPWM値
    max_pulse = 625  # 180度のPWM値
    return int(min_pulse + (angle / 180.0) * (max_pulse - min_pulse))

#
# map
# Front-Right
# 0: leg_index=0, axis_index=0 
# 1: leg_index=0, axis_index=1
# 2: leg_index=0, axis_index=2

# Front-Left
# 3: leg_index=1, axis_index=0
# 4: leg_index=1, axis_index=1
# 5: leg_index=1, axis_index=2

# Back-Right
# 6: leg_index=2, axis_index=0
# 7: leg_index=2, axis_index=1
# 8: leg_index=2, axis_index=2

# Back-Left
# 9: leg_index=3, axis_index=0
# 10: leg_index=3, axis_index=1
# 11: leg_index=3, axis_index=2

def move_servos():
    while True:
        print("Move to Position 1 (90°)")
        pwm.set_pwm(0, 0, angle_to_pwm(90))   # チャンネル0
        pwm.set_pwm(1, 0, angle_to_pwm(90))   # チャンネル1
        pwm.set_pwm(2, 0, angle_to_pwm(90))   # チャンネル2
        time.sleep(5)

        print("Move to Position 2 (10°)")
        pwm.set_pwm(0, 0, angle_to_pwm(10))  # チャンネル0
        pwm.set_pwm(1, 0, angle_to_pwm(10))  # チャンネル1
        pwm.set_pwm(2, 0, angle_to_pwm(10))  # チャンネル2
        time.sleep(1)

# サーボを動かす
move_servos()


if __name__ == '__main__':
    move_servos()
