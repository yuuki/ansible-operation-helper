#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'optparse'
require 'json'
require 'mackerel/client'

# Mackerel API Spec
## http://help-ja.mackerel.io/entry/spec/api/v0

class MackerelInventory
  def initialize(args)
    @args = args
    @client = Mackerel::Client.new(
      :mackerel_api_key => "your api key"
    )
  end

  def run()
    inventory = if @args[:host]
        self.find_host(@args[:host])
      elsif @args[:list]
        self.find_hosts
      else
        self.find_hosts
      end

    puts JSON.dump inventory
  end

  def find_host(host)
    return {}
  end

  # out: 
  # {
  #   "Example-Blog_app": ["blogapp001.example.host", "blogapp002.example.host"],
  #   "Example-Blog_proxy": ["blogproxy001.example.host", "blogdproxy002.example.host"],
  #   ...
  #   "_meta" => { 
  #     "hostvars" => {
  #       "blogapp001.example.host" => {
  #         "status": "working",
  #         "roleFullnames": ["Example-Blog::app"]
  #         ...
  #       },
  #       "blogapp002.example.host" => {
  #         ...
  #       },
  #       ...
  #     }
  #   }
  # }
  def find_hosts
    # http://docs.ansible.com/developing_inventory.html#tuning-the-external-inventory-script
    inventory = { "_meta" => { "hostvars" => {} } }
    hostvars = inventory["_meta"]["hostvars"]

    @client.get_hosts.each do |host|
      hostvars[host.name] = host.to_h

      inventory["status_#{host.status}"] ||= []
      inventory["status_#{host.status}"] |= [host.name]

      next if host.roles.nil?
      hostvars[host.name]['roleFullnames'] = []

      host.roles.each_pair do |service, roles|
        roles.each do |role|
          service_group = service
          role_group    = "#{service}_#{role}"

          inventory[service_group] ||= []
          inventory[role_group]    ||= []
          inventory[service_group] << host.name unless inventory[service_group].include? host.name
          inventory[role_group]    << host.name unless inventory[role_group].include? host.name

          hostvars[host.name]['roleFullnames'] << "#{service}:#{role}"
        end
      end
    end

    inventory
  end
end

if __FILE__ == $0
  option = {}
  OptionParser.new do |opt|
    opt.on('--list', 'bool') {|v| option[:list] = v }
    opt.on('--host', 'fqdn') {|v| option[:host] = v }
    opt.parse!(ARGV)
  end
  mackerel = MackerelInventory.new(option)
  if mackerel.run
    exit 1
  else
    exit 0
  end
end
