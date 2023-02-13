# typed: true

require "stringio"

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

  def read_complete_line(io)
    res = io.readline

    raise Incomplete if res[-2..] != CRLF

    return res[...-2]
  end

  def consume
    io = StringIO.new @buf

    begin
      res = decode(io)
      pos = io.pos
      @buf = @buf[pos..]
      res
    rescue Incomplete => e
      nil
    end
  end

  def decode(io)
    raise Incomplete if io.eof?

    case io.readchar
    when "+"
      return read_complete_line(io)
    when "-"
      return read_complete_line(io)
    when ":"
      return read_complete_line(io).to_i
    when "$"
      len = read_complete_line(io).to_i

      if len == -1
        _ = read_complete_line(io)
        return nil
      else
        res = io.read(len)
        raise Incomplete if len != res.size
        _ = read_complete_line(io)
        return res
      end
    when "*"
      len = read_complete_line(io).to_i
      return Array.new(len) { decode(io) }
    end
  end
end
