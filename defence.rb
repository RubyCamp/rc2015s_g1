require 'dxruby'
require_relative 'ev3/ev3'

class Down
  LARM_MOTOR = "A"
  RARM_MOTOR = "D"
  PORT = "COM3"
  ARM_SPEED = 30
  motors = [LARM_MOTOR, RARM_MOTOR]
  def initialize
    @brick = EV3::Brick.new(EV3::Connections::Bluetooth.new(PORT))
    @brick.connect
  end

  def downarm(speed=ARM_SPEED)
      @brick.run_forward(RARM_MOTOR)
      @brick.run_forward(LARM_MOTOR)
      @brick.reverse_polarity(RARM_MOTOR)
      @brick.reverse_polarity(LARM_MOTOR)
      @brick.step_velocity(30, 0, 25, RARM_MOTOR)
      @brick.step_velocity(30, 0, 25, LARM_MOTOR)
      @brick.start(speed,RARM_MOTOR)

      @brick.start(speed,LARM_MOTOR)
  end

  def stop
    @brick.reset(LARM_MOTOR)
    @brick.reset(RARM_MOTOR)
    @brick.stop(true,LARM_MOTOR)
    @brick.stop(true,RARM_MOTOR)
    @brick.disconnect
  end
end

begin
  puts "starting..."
  font = Font.new(32)
  down = Down.new
  puts "connected..."

  Window.loop do
    break if Input.keyDown?(K_ESCAPE)
    down.downarm()
  end

rescue
  p $!
  $!.backtrace.each{|trace| puts trace}
# 終了処理は必ず実行する
ensure
  puts "closing..."
  down.stop
  puts "finished..."
end
