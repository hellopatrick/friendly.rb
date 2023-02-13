# typed: true
# frozen_string_literal: true

require "minitest/autorun"

require "stringio"

require "./lib/command_parser"

class CommandParserTest < Minitest::Test
  def io(str)
    StringIO.new str
  end

  def test_simple_string
    tc = io "+OK\r\n"
    v = CommandParser.decode tc

    assert_equal "OK", v
  end

  def test_error
    tc = io "-NOPE\r\n"
    v = CommandParser.decode tc

    assert_equal "NOPE", v
  end

  def test_integer
    tc = io ":10\r\n"
    v = CommandParser.decode tc

    assert_equal 10, v
  end

  def test_negative_integer
    tc = io ":-1\r\n"
    v = CommandParser.decode tc

    assert_equal(-1, v)
  end

  def test_bulk_string
    tc = io "$12\r\nhello\r\nworld\r\n"
    v = CommandParser.decode tc
    assert_equal "hello\r\nworld", v
  end

  def test_empty_bulk_string
    tc = io "$0\r\n\r\n"
    v = CommandParser.decode tc
    assert_equal "", v
  end

  def test_nil
    tc = io "$-1\r\n"
    v = CommandParser.decode tc
    assert_nil v
  end

  def test_empty_array
    tc = io "*0\r\n"
    v = CommandParser.decode tc
    assert_empty v
  end

  def test_basic_array
    tc = io "*3\r\n+ONE\r\n+TWO\r\n+THREE\r\n"
    v = CommandParser.decode tc
    assert_equal %w[ONE TWO THREE], v
  end

  def test_nested_array
    tc = io "*3\r\n+ONE\r\n+TWO\r\n*3\r\n+ONE\r\n+TWO\r\n+THREE\r\n"
    v = CommandParser.decode tc
    assert_equal ["ONE", "TWO", %w[ONE TWO THREE]], v
  end

  def test_nil_in_array
    tc = io "*3\r\n$5\r\nhello\r\n$-1\r\n$5\r\nworld\r\n"
    v = CommandParser.decode tc
    assert_equal ["hello", nil, "world"], v
  end

  def test_incomplete_array
    tc = io "*4\r\n+ONE\r\n+TWO\r\n+THREE\r\n"

    assert_raises(Incomplete) { CommandParser.decode tc }
  end
end
