# -*- mode: ruby; coding: utf-8; -*-
#
# Cookbook Name:: apache
# Recipe:: example
#

# Get install databag items
web_bag = data_bag_item('web', 'apache')
fail 'Unable to load the web:#{bag_item} databag.' unless web_bag

apache_pkg = web_bag['pkg']
apache_websites = web_bag['websites']

# Stop Apache service
service "#{apache_pkg}" do
  action :stop
end

# Install Apache service
package apache_pkg do
  ignore_failure true
  action :purge
end

