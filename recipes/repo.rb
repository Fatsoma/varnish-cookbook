# Cookbook Name:: varnish
# Recipe:: repo
#
# Copyright 2014. Patrick Connolly <patrick@myplanetdigital.com>
# Copyright 2015. Rackspace, US Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# packagecloud repos omit dot from major version
major_version_no_dot = node['varnish']['version'].to_s.tr('.', '')
case node['platform_family']
when 'debian'
  include_recipe 'apt'
  apt_repository 'varnish-cache' do
    uri "https://packagecloud.io/varnishcache/varnish#{major_version_no_dot}/#{node['platform']}"
    distribution node['lsb']['codename']
    components ['main']
    key "https://packagecloud.io/varnishcache/varnish#{major_version_no_dot}/gpgkey"
    deb_src true
    notifies 'nothing', 'execute[apt-get update]', 'immediately'
  end
when 'rhel', 'fedora'
  yum_repository 'varnish' do
    description "Varnish #{node['varnish']['version']} repo (#{node['platform_version']} - $basearch)"
    url "https://packagecloud.io/varnishcache/varnish#{major_version_no_dot}/el/#{node['platform_version'].to_i}/$basearch"
    gpgcheck false
    gpgkey "https://packagecloud.io/varnishcache/varnish#{major_version_no_dot}/gpgkey"
    action :create
  end
end
