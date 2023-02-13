#!/usr/bin/env ruby
# typed: strict
# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("lib", File.dirname(__FILE__))

require "./lib/server"

srv = Server.new(6379)
srv.start
