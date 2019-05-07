# -*- mode: ruby; coding: utf-8; -*-
#
# Cookbook Name:: apache
# Recipe:: example
#

# Get install databag items
#web_bag = data_bag_item('web', 'apache')
#fail 'Unable to load the web:#{bag_item} databag.' unless web_bag

#apache_pkg = web_bag['pkg']
#apache_websites = web_bag['websites']

# Install Apache service
package node['pkg'] do
  ignore_failure true
  action :install
end

# Configure Apache service
template "/etc/#{node['pkg']}/ports.conf" do
  source 'ports.erb'
  owner 'root'
  group 'root'
  mode '0644'
  action [:delete, :create]
  variables(
    http_port: node['http_port']
  )
end

template "/etc/#{node['pkg']}/#{node['pkg']}.conf" do
  source 'apache.erb'
  owner 'root'
  group 'root'
  mode '0644'
  action [:delete, :create]
end

# Configure Apache virtual hosts
execute 'Reset default sites' do
  command "rm -f /etc/#{node['pkg']}/sites-enabled/*;rm -f /etc/#{node['pkg']}/sites-available/*"
end
node['websites'].each do |website|
  template "/etc/#{node['pkg']}/sites-available/#{website['name']}.conf" do
    source 'website.erb'
    owner 'root'
    group 'root'
    mode '0644'
    action [:delete, :create]
    variables(
      vhostip: node['ipaddress'],
      vhostport: website['vhost']['port'],
      servername: "#{website['server']['name']}",
      serveralias: "#{website['server']['alias']}",
      documentroot: "#{node['root']}/#{website['name']}",
      loglevel: node['log_level']
    )
  end
  cookbook_file "#{node['root']}/#{website['tarball']}" do
     source website['tarball']
     owner 'root'
     group 'root'
     mode '0644'
  end
  execute 'Extract website files' do
    command <<-EOF
      cd #{node['root']}
      unzip #{website['tarball']}
      chmod 0755 #{website['name']}
      EOF
  end
  link "/etc/#{node['pkg']}/sites-enabled/#{website['name']}.conf" do
    to "/etc/#{node['pkg']}/sites-available/#{website['name']}.conf"
    link_type :symbolic
  end
end

# Restart Apache service
service "#{node['pkg']}" do
  action [:enable, :restart]
end

