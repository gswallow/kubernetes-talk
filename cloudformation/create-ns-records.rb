#!/usr/bin/env ruby

require 'aws-sdk-core'

# Creates an NS record delegating k8s.<domain_name> to its proper name servers.

def str2id(s)
  s.id.delete('/hostedzone/')
end

client = Aws::Route53::Client.new
zones = client.list_hosted_zones.hosted_zones

k8s = str2id(zones.find { |z| z.name == "k8s.#{ENV['public_domain']}." })

res = client.list_resource_record_sets(
  :hosted_zone_id => k8s,
  :start_record_type => 'NS',
  :start_record_name => "k8s.#{ENV['public_domain']}.",
  :max_items => 1)

rrsets = res['resource_record_sets']
records = rrsets.first.resource_records

top = str2id(zones.find { |z| z.name == "#{ENV['public_domain']}." })
resp = client.change_resource_record_sets({
  change_batch: {
    changes: [
      {
        action: "CREATE",
        "resource_record_set": {
          "name": "k8s.#{ENV['public_domain']}.",
          "resource_records": records,
          "ttl": 60,
          "type": "NS"
        }
      }
    ]
  },
  "hosted_zone_id": top
})

puts resp.change_info.status
