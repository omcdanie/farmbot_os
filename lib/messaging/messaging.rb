require 'json'

require_relative 'credentials'
require_relative 'web_socket'
require_relative 'messagehandler.rb'

#require '/home/pi/ruby-socket.io-client-simple/lib/socket.io-client-simple.rb'
#require_relative 'socket.io-client-simple.rb'


# The Device class is temporarily inheriting from Tim's HardwareInterface.
# Eventually, we should merge the two projects, but this is good enough for now.
class Messaging
  class << self
    attr_accessor :current

    def current
      @current ||= self.new
    end
  end

  attr_accessor :socket, :uuid, :token, :identified, :confirmed,
    :confirmation_id

  include Credentials, WebSocket

  # On instantiation #new sets the @uuid, @token variables, connects to skynet
  def initialize
    identified = false
    creds      = credentials
    @uuid      = creds[:uuid]
    @token     = creds[:token]
    # Still pointing to old URL?
    @socket    = SocketIO::Client::Simple.connect 'http://skynet.im:80'
    @confirmed = false
  end

  def start
    create_socket_events
    @message_handler  = MessageHandler.new
  end

  def send_message(devices, message_hash )
    @socket.emit("message", devices: devices, message: message_hash)
  end

  # Acts as the entry point for message traffic captured from MeshBlu.
  def handle_message(message)
    case message.class
    when Hash
      @message_handler.handle_message(message)
    when String
      message_hash = JSON.parse(message)
      @message_handler.handle_message(message_hash)
    else
      raise "Can't handle messages of class #{message.class}"
    end
  rescue
    raise "Runtime error while attempting to parse message: #{message}."
  end

end