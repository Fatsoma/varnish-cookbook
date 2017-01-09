node.override['varnish']['configure']['config']['listen_port'] = 80
node.override['varnish']['configure']['repo']['action'] = :nothing
node.override['varnish']['configure']['ncsa']['action'] = :configure

package 'nginx'

# avoid depending on init system
execute 'nginx_restart' do
  command 'pkill nginx; nginx'
  action :nothing
end

public_html = '/var/www/public_html'

directory public_html do
  recursive true
end

file "#{public_html}/index.html" do
  content 'Hello World!'
end

cookbook_file '/etc/nginx/nginx.conf' do
  notifies_immediately :run, 'execute[nginx_restart]'
end

include_recipe 'varnish::configure'