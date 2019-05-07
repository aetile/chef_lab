# -*- mode: ruby; coding: utf-8; -*-
#
# Cookbook Name:: cassandra
# Recipe:: example
#

# Get install databag items
#node = data_bag_item('cstar', 'cassandra')
#fail 'Unable to load the cstar:#{bag_item} databag.' unless node

#cassandra_pkg = node['pkg']
#apache_pkg = node['apache_pkg']

# Uninstall
include_recipe 'cassandra::uninstall' if node['cleaninstall']

# Create OS users
%w[ 'cassandra' 'opscenter' ].each do |osuser|
  user "#{osuser}" do
    comment "#{osuser} user"
    home "/home/#{osuser}"
    shell '/bin/bash'
    password "#{osuser}"
  end
end

# Install Required packages
case node[:platform]
  when 'redhat', 'centos'
  when 'debian', 'ubuntu'
    apt_repository 'datastax' do
      uri "#{node['proto']}://#{node['datastax_user']}:#{node['datastax_key']}@debian.datastax.com/enterprise"
      key "#{node['proto']}://#{node['repo_key']}"
      distribution ""
      components ['stable','main']
    end
    node['pkg']['debian'].each do |deb|
      apt_package deb do
	overwrite_config_files true
        action :install
      end
    end
end

# Configure Cassandra cluster
execute "Fix directory rights" do
  command "chown -R cassandra:cassandra /etc/dse/*;chown -R cassandra:cassandra /etc/datastax-agent/*;chown -R opscenter:opscenter /etc/opscenter/*"
end

template "/etc/dse/cassandra/cassandra.yaml" do
  source 'cassandra.erb'
  owner 'cassandra'
  group 'cassandra'
  mode '0644'
  variables(
    cluster_name: node['cluster_name'],
    cluster_seeds: node['seeds'],
    listen_address: node['ipaddress'],
    cql_port: node['cql_port']
  )
end

template "/etc/dse/cassandra/jvm.options" do
	source 'jvm.options.erb'
  owner 'cassandra'
  group 'cassandra'
  mode '0644'
  variables(
    java_heap: node['java_heap_size']
  )
end

# Configure Opscenter
directory '/etc/opscenter/clusters' do
  owner 'opscenter'
  group 'opscenter'
  mode '0755'
  only_if { node['opscenter']['enabled'] }
end

template "/etc/opscenter/opscenterd.conf" do
  source 'opscenterd.erb'
  owner 'opscenter'
  group 'opscenter'
  mode '0644'
  variables(
    http_port: node['opscenter']['http_port'],
    opscenter_address: node['opscenter']['address'],
    opscenter_auth: node['opscenter']['auth']
  )
  only_if { node['opscenter']['enabled'] }
end

template "/etc/opscenter/clusters/#{node['cluster_name']}.conf" do
  source 'cluster.erb'
  owner 'opscenter'
  group 'opscenter'
  mode '0644'
  variables(
    opscenter_jmx_port: node['opscenter']['jmx_port'],
    cql_port: node['cql_port'],
    cluster_seeds: node['seeds']
  )
  only_if { node['opscenter']['enabled'] }
end

template "/var/lib/datastax-agent/conf/address.yaml" do
  source 'agent.erb'
  owner 'cassandra'
  group 'cassandra'
  mode '0644'
  variables(
    stomp_interface: node['opscenter']['address'],
    use_ssl: 'no'
  )
  not_if { node['opscenter']['enabled'] }
end

# Allow Opscenter Web UI to run on port 80
execute 'Reset default sites' do
  command "rm -f /etc/#{node['apache_pkg']}/sites-enabled/*;rm -f /etc/#{node['apache_pkg']}/sites-available/*"
  only_if { node['opscenter']['enabled'] }
end

template "/etc/#{node['apache_pkg']}/sites-available/opscenter.conf" do
  source 'vhost.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    opscenter_port: node['opscenter']['http_port'],
    opscenter_address: node['opscenter']['address']
  )
  only_if { node['opscenter']['enabled'] }
end

link "/etc/#{node['apache_pkg']}/sites-enabled/opscenter.conf" do
  to "/etc/#{node['apache_pkg']}/sites-available/opscenter.conf"
  link_type :symbolic
  only_if { node['opscenter']['enabled'] }
end

execute "Enable Apache proxy module" do
  command "a2enmod proxy proxy_http"
  only_if { node['opscenter']['enabled'] }
end

# Start DSE services, seeds first
service "dse" do
  action [:enable, :stop, :start]
  only_if { node['is_seed'] }
end

service "dse" do
  action [:enable, :stop, :start]
  not_if { node['is_seed'] }
end

service "opscenterd" do
  action [:enable, :stop, :start]
end

service "#{node['apache_pkg']}" do
  action [:enable, :stop, :start]
  only_if { node['opscenter']['enabled'] }
end

execute "Wait for CQL ports" do
  command "netstat -nat | grep LISTEN | grep #{node['cql_port']}"
   retries 30
   retry_delay 5
end

execute "Wait for Opscenter port" do
  command "netstat -nat | grep LISTEN | grep #{node['opscenter']['http_port']}"
   retries 30
   retry_delay 5
  only_if { node['opscenter']['enabled'] }
end

service "datastax-agent" do
  action [:enable, :stop, :start]
end
