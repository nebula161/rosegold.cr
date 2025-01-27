require "socket"
require "../minecraft/io"
require "./control/*"
require "./models/*"
require "./packets/*"
require "./world/*"

abstract class Rosegold::Event; end # defined elsewhere, but otherwise it would be a module

class Rosegold::Event::RawPacket < Rosegold::Event
  getter bytes : Bytes

  def initialize(@bytes); end
end

# Holds world state (player, chunks, etc.)
# and control state (physics, open window, etc.).
# Can be reconnected.
class Rosegold::Client < Rosegold::EventEmitter
  class_getter protocol_version = 758_u32

  property host : String, port : UInt16
  @connection : Connection::Client?

  property \
    online_players : Hash(UUID, PlayerList::Entry) = Hash(UUID, PlayerList::Entry).new,
    player : Player = Player.new,
    dimension : Dimension = Dimension.new,
    physics : Physics,
    current_window : Window = Window.player_inventory

  def initialize(@host : String, @port : UInt16 = 25565)
    if host.includes? ":"
      @host, port_str = host.split ":"
      @port = port_str.to_u16
    end
    @physics = uninitialized Physics
    @physics = Physics.new self
  end

  def connection : Connection::Client
    @connection || raise "Client was never connected"
  end

  def connected?
    !@connection.nil? && !connection.close_reason
  end

  def state=(state)
    connection.state = state
  end

  def join_game(&)
    connect

    until connection.state == ProtocolState::PLAY.clientbound
      sleep 0.1
    end
    Log.info { "Ingame" }

    yield self
  end

  def connect
    raise "Already connected" if connected?

    io = Minecraft::IO::Wrap.new TCPSocket.new(host, port)
    connection = @connection = Connection::Client.new io, ProtocolState::HANDSHAKING.clientbound, self
    Log.info { "Connected to #{host}:#{port}" }

    send_packet! Serverbound::Handshake.new Client.protocol_version, host, port, 2
    connection.state = ProtocolState::LOGIN.clientbound

    queue_packet Serverbound::LoginStart.new ENV["MC_NAME"]

    @online_players = Hash(UUID, PlayerList::Entry).new

    spawn do
      loop do
        if connection.close_reason
          Fiber.yield
          Log.info { "Stopping reader: #{connection.close_reason}" }
          break
        end
        read_packet
      end
    end
  end

  def status
    self.class.status host, port
  end

  def self.status(host : String, port : UInt16 = 25565)
    io = Minecraft::IO::Wrap.new TCPSocket.new(host, port)
    connection = Connection::Client.new io, ProtocolState::HANDSHAKING.clientbound

    connection.send_packet Serverbound::Handshake.new Client.protocol_version, host, port, 1
    connection.state = ProtocolState::STATUS.clientbound

    connection.send_packet Serverbound::StatusRequest.new
    connection.read_packet || raise "Server responded with unknown packet"
  end

  # Send a packet to the server concurrently.
  def queue_packet(packet : Serverbound::Packet)
    raise "Unabled to queue #{packet}; Not connected" unless connected?
    spawn do
      Fiber.yield
      send_packet! packet
    end
  end

  # Send a packet in the current fiber. Useful for things like
  # EncryptionRequest, because it must change the IO socket only AFTER
  # a EncryptionResponse has been sent.
  def send_packet!(packet : Serverbound::Packet)
    raise "Not connected" unless connected?
    Log.trace { "SEND #{packet}" }
    connection.send_packet packet
  end

  private def read_packet
    raise "Not connected" unless connected?
    raw_packet = connection.read_raw_packet

    emit_event Event::RawPacket.new raw_packet

    packet = Connection.decode_packet raw_packet, connection.state
    return nil unless packet
    Log.trace { "RECV #{packet}" }

    packet.callback(self)

    emit_event packet

    packet
  end
end
