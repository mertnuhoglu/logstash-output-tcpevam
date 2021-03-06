# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"
require "thread"

# Write events over a TCP socket.
#
# Each event json is separated by a newline.
#
# Can either accept connections from clients or connect to a server,
# depending on `mode`.
class LogStash::Outputs::TcpEvam < LogStash::Outputs::Base

  config_name "tcpevam"

  default :codec, "json"

  config :hosts, :validate => :array, :required => true
  # When mode is `server`, the address to listen on.
  # When mode is `client`, the address to connect to.
  # config :host, :validate => :string, :required => true
  # config :host2, :validate => :string, :required => true
  config :dependent_jar_path, :validate => :path, :required => true
  # config :filelistener, :validate => :path, :required => true

  # When mode is `server`, the port to listen on.
  # When mode is `client`, the port to connect to.
  # config :port, :validate => :number, :required => true
  # config :port2, :validate => :number, :required => true

  # When connect failed,retry interval in sec.
  config :reconnect_interval, :validate => :number, :default => 10

  # Mode to operate in. `server` listens for client connections,
  # `client` connects to a server.
  config :mode, :validate => ["server", "client"], :default => "client"

  # The format to use when writing events to the file. This value
  # supports any string and can include `%{name}` and other dynamic
  # strings.
  #
  # If this setting is omitted, the full json representation of the
  # event will be written as a single line.
  config :message_format, :validate => :string, :deprecated => true

  @sockets

  class Client
    public
    def initialize(socket, logger)
      @socket = socket
      @logger = logger
      @queue = Queue.new
    end

    public
    def run
      loop do
        begin
          @socket.write(@queue.pop)
        rescue => e
          @logger.warn("tcp output exception", :socket => @socket,
                       :exception => e)
          break
        end
      end
    end

    # def run

    public
    def write(msg)
      @queue.push(msg)
    end # def write
  end # class Client

  public
  def register
    require "socket"
    require "stud/try"

    # jar_files = ['netty-3.10.0.Final.jar', 'log4j-1.2.17.jar', 'listener-tokenizer-4.0.4.jar', 'listener-parser-4.0.4.jar', 'legacy-listener-4.0.4.jar', 'guava-16.0.1.jar', 'commons-utils-4.0.4.jar', 'commons-sdk-4.0.4.jar', 'commons-pool-1.5.6.jar', 'commons-lang-2.6.jar', 'commons-event-sender-4.0.4.jar', 'commons-collections-3.1.jar', 'commons-cli-1.2.jar']
    # jar_files.each(|jar| require File.join(@dependent_jar_path, jar) )
    Dir["#{@dependent_jar_path}/*.jar"].each {|file| require file }

    begin
      @sockets = Hash.new

      # hosts_arr = @hosts.each_with_index { |k, i|
      #   host = k.split(":")[0]
      #   port = k.split(":")[1]
      #   @sockets[i] = connect(host, port)
      # }

      # @sockets["0"] = connect(@host, @port)
      # @sockets["1"] = connect(@host2, @port2)
      puts "socket created"
    rescue => e
      @logger.warn("tcp output exception",
                   :exception => e, :backtrace => e.backtrace)
      # @logger.warn("tcp output exception", :host => @hosts,
      #              :exception => e, :backtrace => e.backtrace)
      # @logger.warn("tcp output exception", :host => @host, :port => @port,
      #              :exception => e, :backtrace => e.backtrace)
      # @logger.warn("tcp output exception", :host => @host2, :port => @port2,
      #              :exception => e, :backtrace => e.backtrace)
      retry
    end


    @codec.on_event do |event, payload|
      begin
        # puts "payload: " + payload
        actor_id = payload.split(",")[1].to_i
        # puts "actor_id: " + actor_id.to_s
        # puts "node_id: " + node_id.to_s

        # node_id = actor_id % @sockets.length
        # write_to_tcp(payload, @sockets[node_id])
        write_to_evam(actor_id, payload)

        # if (actor_id == "001")
          # client_socket = write_to_tcp(client_socket, payload, @host, @port)
          # write_to_tcp(client_socket, payload, @host, @port)
          # write_to_tcp(payload, @sockets["0"])
        # else
        #   write_to_tcp(payload, @sockets["1"])
        # end
      rescue => e
        @logger.warn("tcp output exception", :host => @host, :port => @port,
                     :exception => e, :backtrace => e.backtrace)
        client_socket.close rescue nil
        client_socket = nil
        sleep @reconnect_interval
        retry
      end
    end
  end

  def write_to_evam(actor_id, payload)
    props = java.util.Properties.new
    props.setProperty("numServers", @hosts.length.to_s)
    props.setProperty("pollInterval", "10")
    props.setProperty("engineMonitorInterval", "10")
    props.setProperty("warningLevelThreshold", "30000")
    props.setProperty("warningLevelWaitTime", "15")
    props.setProperty("errorLevelThreshold", "50000")
    props.setProperty("errorLevelWaitTime", "30")
    props.setProperty("fatalLevelThreshold", "75000")
    props.setProperty("fatalLevelWaitTime", "60")
    props.setProperty("endOfResponseDelimiter", "END_OF_RESPONSE~\n")
    props.setProperty("eventSenderPoolSize", "3")
    @hosts.each_with_index { |k, i|
      host = k.split(":")[0]
      port = k.split(":")[1]
      props.setProperty("host.#{i}", host)
      props.setProperty("port.#{i}", port)
    }
    # props.load(java.io.FileInputStream.new(@filelistener))
    evam = com.intelllica.evam.client.EventSenderManager.getInstance()
    evam.init(props)
    evam.checkConnections()
    # event = com.intellica.model.Event.new("event02", 12, "test_event_ruby");
    # evam.sendEvent(event)
    evam.java_send :sendEvent, [java.lang.Long, java.lang.String], java.lang.Long.valueOf(actor_id), payload
  end

  def write_to_tcp(payload, client_socket)
    r, w, e = IO.select([client_socket], [client_socket], [client_socket], nil)
    # don't expect any reads, but a readable socket might
    # mean the remote end closed, so read it and throw it away.
    # we'll get an EOFError if it happens.
    client_socket.sysread(16384) if r.any?

    # Now send the payload
    client_socket.syswrite(payload) if w.any?
    client_socket
  end

  def write_to_tcp0(client_socket, payload, host, port)
    client_socket = connect(host, port) unless client_socket
    r, w, e = IO.select([client_socket], [client_socket], [client_socket], nil)
    # don't expect any reads, but a readable socket might
    # mean the remote end closed, so read it and throw it away.
    # we'll get an EOFError if it happens.
    client_socket.sysread(16384) if r.any?

    # Now send the payload
    client_socket.syswrite(payload) if w.any?
    client_socket
  end

  # def register

  private
  def connect(host, port)
    Stud::try do
      return TCPSocket.new(host, port)
    end
  end

  # def connect

  private
  def server?
    @mode == "server"
  end

  # def server?

  public
  def receive(event)


    #if @message_format
    #output = event.sprintf(@message_format) + "\n"
    #else
    #output = event.to_hash.to_json + "\n"
    #end

    @codec.encode(event)
  end # def receive
end # class LogStash::Outputs::Tcp
