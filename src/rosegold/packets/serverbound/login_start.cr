require "../packet"

class Rosegold::Serverbound::LoginStart < Rosegold::Serverbound::Packet
  class_getter packet_id = 0x00_u8
  class_getter state = Rosegold::ProtocolState::LOGIN

  property username : String

  def initialize(@username : String); end

  def write : Bytes
    Minecraft::IO::Memory.new.tap do |buffer|
      buffer.write @@packet_id
      buffer.write username
    end.to_slice
  end
end
