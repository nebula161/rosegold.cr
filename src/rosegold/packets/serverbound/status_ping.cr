require "../packet"

class Rosegold::Serverbound::StatusPing < Rosegold::Serverbound::Packet
  class_getter packet_id = 0x01_u8
  protocol_state Rosegold::ProtocolState::STATUS

  property ping_id : Int64

  def initialize(@ping_id); end

  def self.read(packet)
    self.new(packet.read_long)
  end

  def write : Bytes
    Minecraft::IO::Memory.new.tap do |buffer|
      buffer.write @@packet_id
      buffer.write_full ping_id
    end.to_slice
  end

  def callback(server)
    server.send_packet Serverbound::StatusPong.new ping_id
  end
end