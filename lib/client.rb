require "stringio"

require "./lib/command_parser"

class Incomplete < StandardError
end

class Client
  CRLF = "\r\n"

  def initialize(socket)
    @socket = socket
    @buf = ""
  end

  def read_some(cnt = 1024)
    begin
      bytes = @socket.readpartial cnt
      @buf << bytes
    rescue EOFError => e
      return true
    end

    return false
  end

  def consume
    io = StringIO.new @buf

    begin
      res = CommandParser.decode(io)
      pos = io.pos
      @buf = @buf[pos..] || ""
      res
    rescue Incomplete => e
      nil
    end
  end
end
