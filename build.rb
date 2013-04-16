#!/usr/bin/env ruby
require 'erb'
require './opensips.var.rb'

template = ERB.new(File.read('./opensips.cfg.erb'))

outfile = File.new('opensips.cfg', 'w');

outfile.puts template.result($erb_context)

