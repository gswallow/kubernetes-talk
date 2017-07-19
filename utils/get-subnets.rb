#!/usr/bin/env ruby

require 'aws-sdk-core'
require 'yaml'

@client = Aws::EC2::Client.new

def get_vpc()
  @client.describe_vpcs({
    :filters => [
      {
        name: "tag:Environment",
        values: [ ENV['environment'] ]
      }
    ]
  }).vpcs.first.vpc_id
end

def get_subnets(vpc_id, type)
  @client.describe_subnets({
    :filters => [
      {
        name: "vpc-id",
        values: [ vpc_id ]
      },
      {
        name: "tag:Network",
        values: [ type ]
      }
    ]
  }).subnets
end

def attrs_of(subnets, type, pfx = nil)
  subnets.collect do |sn|
    { 'id' => sn.subnet_id, 'name' => "#{pfx + "-" if !pfx.nil?}#{sn.availability_zone}", 'type' => type, 'zone' => sn.availability_zone }
  end
end

vpc_id = get_vpc

subnets = attrs_of(get_subnets(vpc_id, 'Public'), 'Utility', 'utility')
subnets.concat(attrs_of(get_subnets(vpc_id, 'Private'), 'Private'))
puts YAML.dump('subnets' => subnets)
