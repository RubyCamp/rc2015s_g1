require 'dxruby'
require_relative 'ev3/ev3'

LEFT_MOTOR = "C"
RIGHT_MOTOR = "A"
UDE_MOTOR = "B"
YUBI_MOTOR = "D"
COLOR_SENSOR_LEFT = "4"
SONIC_SENSOR = "3"
COLOR_SENSOR_RIGHT = "1"

PORT = "COM3"

UDE_MOTOR_SPEED = 10
YUBI_MOTOR_SPEED = 100
MOTOR_SPEED = 30
MOTOR_SPEED3 = 20
WHEEL_SPEED = 40
distance = 0
start = true
@takeball = false
@busy = false
@rotate = ""

def run_forward(brick,motors3,speed=WHEEL_SPEED)
  p "forward"
  operate(brick) do
	  brick.clear_all
    brick.start(speed,*motors3)
    brick.clear_all
  end
end
  # バックする
def run_backward(brick,motors3,speed=WHEEL_SPEED)
  operate(brick) do
    brick.clear_all
    brick.run_forward(*motors3)
	  brick.reverse_polarity(*motors3)
    brick.start(speed, *motors3)
    brick.clear_all
  end
end
  # 右に回る
def turn_right(brick,right_motor,motors3,speed=WHEEL_SPEED)
  operate(brick) do
    brick.clear_all
    brick.reverse_polarity(right_motor)
    brick.start(speed, *motors3)
    brick.clear_all
  end
end
  # 左に回る
def turn_left(brick,left_motor,motors3,speed=WHEEL_SPEED)
  operate(brick) do
    brick.clear_all
    brick.reverse_polarity(left_motor)
    brick.start(speed, *motors3)
    brick.clear_all
  end
end

def operate(brick)
  unless @busy
    @busy = true
    yield(brick)
  end
end

def stop(brick)
  brick.stop(true, *@all_motors)
  brick.run_forward(*@all_motors)
  @busy = false
end

@all_motors ||= self.class.constants.grep(/_MOTOR\z/).map{|c| self.class.const_get(c) }

def run(brick,right_motor,left_motor,motors3)
  #update
  run_forward(brick,motors3) if Input.keyDown?(K_UP)
  run_backward(brick,motors3) if Input.keyDown?(K_DOWN)
  turn_left(brick,left_motor,motors3) if Input.keyDown?(K_RIGHT)
  turn_right(brick,right_motor,motors3) if Input.keyDown?(K_LEFT)
  if Input.keyDown?(K_Q)
    @takeball = true
    @rotate = "right"
    p @takeball
  end
  if Input.keyDown?(K_W)
    @takeball = true
    @rotate = "left"
  end
  stop(brick) if [K_UP, K_DOWN, K_LEFT, K_RIGHT, K_Q, K_W].all?{|key| !Input.keyDown?(key) }
end

def takeball(brick ,motors,motors1,motors3,right_motor,left_motor)
  #戻る
  brick.stop(false, *motors3)
  brick.reverse_polarity(*motors3)
  brick.start(20, *motors3)
  sleep 1.5
  brick.reverse_polarity(*motors3)
  brick.stop(false, *motors3)


  #腕をあげる
  brick.run_forward(*motors1)
  #brick.reverse_polarity(*motors1)
  brick.step_velocity(10, 45, 15, *motors1)
  sleep 0.5

  #旋回
  p @rotate
  if (@rotate == "right")
    brick.start(20, *motors3)
    brick.stop(false,left_motor)
    sleep 2.3
    brick.stop(false,right_motor)
    brick.run_forward(*motors3)
    sleep 0.5
  elsif (@rotate == "left")
    brick.start(20, *motors3)
    brick.stop(false,right_motor)
    sleep 2
    brick.stop(false,left_motor)
    brick.run_forward(*motors3)
    sleep 0.5
  end

  #指をフル
  brick.run_forward(*motors)
  brick.step_velocity(100,100, 0, *motors)
  #brick.start(YUBI_MOTOR_SPEED, *motors)
  #sleep 0.03
  #brick.stop(false, *motors)
  sleep 1

  #ゆび戻す
  brick.reverse_polarity(*motors)
  brick.step_velocity(10, 35, 10, *motors)
  #brick.start(YUBI_MOTOR_SPEED, *motors)
  #sleep 0.03
  #brick.stop(false, *motors)
  sleep 0.3

  #下げる

  brick.reset(*motors1)
  sleep 0.5

  @takeball = false
end

begin
  puts "starting..."
  font = Font.new(32)
  brick = EV3::Brick.new(EV3::Connections::Bluetooth.new(PORT))
  brick.connect
  puts "connected..."

  motors1 = [UDE_MOTOR]
  motors = [YUBI_MOTOR]
  motors3 = [LEFT_MOTOR, RIGHT_MOTOR]
  @all_motors = [UDE_MOTOR,YUBI_MOTOR,LEFT_MOTOR,RIGHT_MOTOR]

  #モーターリセット
  brick.reset(*motors)
  brick.reset(*motors1)
  brick.reset(*motors3)

  Window.loop do
    if (start)
      p "start"

      brick.reverse_polarity(*motors)
      brick.step_velocity(10, 35, 10, *motors)
      #brick.start(YUBI_MOTOR_SPEED, *motors)
      #sleep 0.03
      #brick.stop(false, *motors)
      sleep 0.1
      brick.reverse_polarity(*motors1)
      brick.start(10,*motors1)
      sleep 0.9
      brick.stop(false, *motors1)
      brick.reset(*motors1)
      start = false
    end
    if (@takeball == false)
      run(brick,RIGHT_MOTOR,LEFT_MOTOR,motors3)
    elsif (@takeball == true)
      p "ok"
      distance = brick.get_sensor(SONIC_SENSOR, 0)
      if (distance >= 18)
        brick.run_forward(*motors3)
        brick.start(MOTOR_SPEED3, *motors3)
      else
        brick.stop(false,*motors3)
        sleep 0.4
        takeball(brick,motors,motors1,motors3,RIGHT_MOTOR,LEFT_MOTOR)
      end
    end
  end
rescue
  p $!
  print $!.backtrace.join("\n")
#終了処理は必ず実行する
ensure
  puts "closing..."
  brick.stop(false, *motors3)
  brick.clear_all
  brick.disconnect
  puts "finished..."
end