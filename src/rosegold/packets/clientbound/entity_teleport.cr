require "../../world/look"
require "../../world/vec3"
require "../packet"

class Rosegold::Clientbound::EntityTeleport < Rosegold::Clientbound::Packet
  class_getter packet_id = 0x62_u8

  property \
    entity_id : Int32,
    location : Vec3d,
    look : Look
  property? \
    on_ground : Bool

  def initialize(@entity_id, @location, @look, @on_ground = true); end

  def self.read(packet)
    self.new(
      packet.read_var_int.to_i32,
      Vec3d.new(
        packet.read_double,
        packet.read_double,
        packet.read_double),
      Look.new(
        packet.read_angle256_deg,
        packet.read_angle256_deg),
      packet.read_bool
    )
  end

  def write : Bytes
    Minecraft::IO::Memory.new.tap do |buffer|
      buffer.write @@packet_id
      buffer.write entity_id
      buffer.write location.x
      buffer.write location.y
      buffer.write location.z
      buffer.write_angle256_deg look.yaw
      buffer.write_angle256_deg look.pitch
      buffer.write on_ground?
    end.to_slice
  end
end
