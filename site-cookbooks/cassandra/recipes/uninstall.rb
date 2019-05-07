# -*- mode: ruby; coding: utf-8; -*-
#
# Cookbook Name:: apache
# Recipe:: example
#

# Get install databag items
#web_bag = data_bag_item('cstar', 'cassandra')
#fail 'Unable to load the cstar:#{bag_item} databag.' unless web_bag

#cassandra_pkg = web_bag['pkg']
#apache_pkg = web_bag['apache_pkg']

# Stop services
service "dse" do
  action :stop
end

service "opscenterd" do
  action :stop
end

service "node['apache_pkg']" do
  action :stop
end

service "datastax-agent" do
  action :stop
end

execute "Kill remaining processes" do
  command "if ps -aux | grep cassandra | grep -v grep >> /dev/null;then killall -u cassandra;fi;if ps -aux | grep opscenter | grep -v grep >> /dev/null;then killall -u opscenter;fi;"
end

# Remove OS users
%w[ 'cassandra' 'opscenter' ].each do |osuser|
  user "#{osuser}" do
    comment "#{osuser} user"
    home "/home/#{osuser}"
    shell '/bin/bash'
    password "#{osuser}"
    action :remove
  end
end

# Remove Apache service
node['pkg']['debian'].each do |deb|
  apt_package deb do
    options "--install-suggests --autoremove"
    action :purge
  end
end
