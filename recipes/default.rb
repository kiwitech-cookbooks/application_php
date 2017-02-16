#
# Copyright 2016-2017, Pramod Singh
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

Chef::Log.info '***** The main PPA for PHP (5.6, 7.0, 7.1) with many PECL extensions *****'
apt_repository 'php-main' do
  uri 'http://ppa.launchpad.net/ondrej/php/ubuntu'
  components ['main', 'stable']
  trusted true
end
include_recipe 'build-essential'

app = search(:aws_opsworks_app).first
package value_for_platform_family(debian: 'mysql-client', rhel: 'mysql')
package 'tar' if platform_family?('rhel')
package 'git'

application "#{app['shortname']}" do
  path "/var/www/#{app['shortname']}"
  repository "#{app['app_source']['url']}"
  deploy_key "#{app['app_source']['ssh_key']}"
  revision "#{app['app_source']['revision']}"
  owner node[:apache][:user]
  group node[:apache][:user]
  if node['application_php']['php_version'].to_f == 5.6
    packages ["php-soap", "php5.6-intl", "php5.6-gd", "php5.6-curl", "php5.6-intl", "php5.6-json", "php5.6-mbstring", "php5.6-mcrypt", "php5.6-mysql", "php5.6-xml", "php5.6-zip"]
  else
    packages ["php-soap", "php-intl", "php-mbstring", "composer"]
  end
  mod_php_apache2
end
  
template "/var/www/#{app['shortname']}/shared/app.php" do
  source "cakephp/app.php.erb"
  owner node[:apache][:user]
  group node[:apache][:user]
  mode 0644
end
link "/var/www/#{app['shortname']}/current/config/app.php" do
  to "/var/www/#{app['shortname']}/shared/app.php"
end

if "#{node['application_php']['composer']}"
  Chef::Log.info 'Running composer install'
  directory "/var/www/#{app['shortname']}/shared/vendor" do
  owner node[:apache][:user]
  group node[:apache][:user]
  mode 0755
end
directory "/var/www/#{app['shortname']}/current/vendor" do
  action :delete
  recursive true
end
link "/var/www/#{app['shortname']}/current/vendor" do
  to "/var/www/#{app['shortname']}/shared/vendor"
end
execute "composer install -n -q" do
  cwd "/var/www/#{app['shortname']}/current"
  user node[:apache][:user]
end
else
  Chef::Log.info 'As opted by you, Composer not ran'
end
