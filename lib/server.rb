require "socket"

require "./lib/client"

class Server
  def initialize(port=6379)
    @server = TCPServer.new("0.0.0.0", port)

    @clients = {}
    @store = {}
  end

  def start
    loop do
      sockets = [@server, *@clients.keys]
      ready, _, _ = IO.select(sockets)

      next if ready.nil?

      ready.each do |socket|
        if socket == @server
          sock = @server.accept
          @clients[sock] = Client.new(sock)
        else
          client = @clients[socket]

          eof = client.read_some

          if eof
            clean(socket)
            next
          end

          loop do
            begin
              cmd = client.consume
              break if cmd.nil? || cmd.empty?
              resp = exec(cmd)
              socket.write resp
            rescue => e
              clean(socket)
            end
          end
        end
      end
    end
  end

  def clean(socket)
    socket.close
    @clients.delete(socket)
  end

  def exec(command)
    cmd = command[0].upcase
    args = command[1..] || []

    case cmd
    when "PING"
      "+PONG\r\n"
    when "ECHO"
      resp = args[0]
      "$#{resp.size}\r\n#{resp}\r\n"
    when "SET"
      return "-invalid\r\n" if args.size < 2

      key = args[0]
      val = args[1]

      @store[key] = val

      "+OK\r\n"
    when "GET"
      key = args[0]
      val = @store[key]

      val ? "$#{val.size}\r\n#{val}\r\n" : "$-1\r\n"
    else
      "+OK\r\n"
    end
  end
end
