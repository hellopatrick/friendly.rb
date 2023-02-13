require "socket"

require "./lib/client"

class Server
  def initialize(port)
    @port = port

    @clients = {}

    @store = {}
  end

  def start
    server = TCPServer.new(@port)

    loop do
      sockets = [server, *@clients.keys]
      ready, _, _ = IO.select(sockets)

      next if ready.nil?

      ready.each do |socket|
        if socket == server
          sock = server.accept
          @clients[sock] = Client.new(sock)
        else
          client = @clients[socket]

          eof = client.read_some

          if eof
            socket.close
            @clients.delete(socket)
            next
          end

          loop do
            cmd = client.consume
            break unless cmd

            p cmd
            resp = exec(cmd)
            socket.write resp
          end
        end
      end
    end
  end

  def exec(command)
    cmd = command[0].upcase
    args = command[1..]

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
