class Incomplete < StandardError
end

module CommandParser
  CRLF = "\r\n".freeze

  def self.read_complete_line(io)
    res = io.readline

    raise Incomplete if res[-2..] != CRLF

    return res[...-2] || ""
  end

  def self.decode(io)
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
        return nil
      else
        res = io.read(len) || ""
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
