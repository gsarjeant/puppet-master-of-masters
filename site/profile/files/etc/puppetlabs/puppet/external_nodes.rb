#!/opt/puppet/bin/ruby

require 'yaml'

# Stub for function that will query EMAN
# Need to implement actual lookup
def query_eman(certname)
  eman_result = Hash.new

  tenant_string = ''
  if /\w+\.\w+\.\w+\.\w+/ =~ certname then
    tenant_string = '::tenant'
  end

  case certname.to_s
  when /master/
    role = "role::puppet#{tenant_string}::master"
  when /puppetdb/
    role = "role::puppet#{tenant_string}::puppetdb"
  when /console/
    role = "role::puppet#{tenant_string}::console"
  end

  eman_result['CONFIG_MGMT_ROLE'] = role
  eman_result['CONFIG_MGMT_ENVIRONMENT'] = 'production'

  return eman_result
end

def transform_eman_results(eman_result)
  eman_role_field = 'CONFIG_MGMT_ROLE'
  eman_environment_field = 'CONFIG_MGMT_ENVIRONMENT'

  node_classification = Hash.new
  node_classification['classes'] = [ eman_result[eman_role_field] ]
  node_classification['environment'] = eman_result[eman_environment_field]

  return node_classification.to_yaml
end

certname = ARGV[0]
eman_result = query_eman(certname)
node_classification_yaml = transform_eman_results(eman_result)

puts node_classification_yaml
