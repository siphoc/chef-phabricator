#
## Cookbook Name:: phabricator
## Recipe:: default
##
## Copyright 2013, Siphoc
##
## Permission is hereby granted, free of charge, to any person obtaining a copy
## of this software and associated documentation files (the "Software"), to deal
## in the Software without restriction, including without limitation the rights
## to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
## copies of the Software, and to permit persons to whom the Software is furnished
## to do so, subject to the following conditions:
##
## The above copyright notice and this permission notice shall be included in all
## copies or substantial portions of the Software.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
## FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
## AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
## LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
## OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
## THE SOFTWARE.
##

# Install optional packages
node['phabricator']['packages'].each do |pkg|
    package pkg
end

# user to own the checked out files
install_user = node['phabricator']['user']
# dir where phabricator and deps are installed
install_dir = node['phabricator']['install_dir']
# phabricator dir, used too often, so create local variable
phabricator_dir = "#{install_dir}/phabricator"

# checkout code
packages = %w{phabricator libphutil arcanist}
packages.each do |pkg|
    git "#{install_dir}/#{pkg}" do
        user install_user
        repository "git://github.com/facebook/#{pkg}.git"
        reference "master"
        action :checkout
    end
end

bash "Configure Phabricator" do
    creates "#{phabricator_dir}/conf/local/local.json"
    user install_user
    cwd phabricator_dir
    mysql = node['phabricator']['mysql']
    code <<-EOH
        ./bin/config set mysql.host '#{mysql.host}'
        ./bin/config set mysql.port '#{mysql.port}'
        ./bin/config set mysql.user '#{mysql.user}'
        ./bin/config set mysql.pass '#{mysql.pass}'
    EOH
    notifies :run, "bash[Upgrade Phabricator storage]", :immediately
end

bash "Upgrade Phabricator storage" do
    user install_user
    cwd phabricator_dir
    code "./bin/storage upgrade --force"
end

# Install custom script to easily install an admin.
template "#{phabricator_dir}/scripts/user/admin.php" do
    source "account.erb"
    user install_user
    mode 0755
end

bash "Install admin account" do
    user install_user
    code <<-EOH
        cd #{phabricator_dir}/scripts/user && ./admin.php
    EOH
end

bash "Remove admin script" do
    user install_user
    code <<-EOH
        rm #{phabricator_dir}/scripts/user/admin.php
    EOH
end

# Set the phabricator config.
template "#{phabricator_dir}/conf/custom.conf.php" do
    source "phabricator-config.erb"
    user install_user
    mode 0644
end

# just to be sure dirs exist
directory "/etc/nginx/sites-available"
directory "/etc/nginx/sites-enabled"

# Set nginx dependencies.
template "/etc/nginx/sites-available/phabricator" do
    source "nginx.erb"
    variables ({ :phabricator_dir => phabricator_dir })
    mode 0644
end

link "Enable Phabricator for nginx" do
    to "../sites-available/phabricator"
    target_file "/etc/nginx/sites-enabled/phabricator"
end

service "nginx" do
    service_name node['phabricator']['nginx']['service']
    action :reload
end
