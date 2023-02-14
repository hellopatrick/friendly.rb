require "stringio"

require "./lib/command_parser"

class Invalid < StandardError; end

class Client
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

      raise Invalid unless res.is_a? Array

      res
    rescue Incomplete => e
      []
    end
  end
end
