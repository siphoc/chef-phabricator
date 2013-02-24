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

bash "Download Phabricator and dependencies" do
    user "vagrant"
    code <<-EOH
        git clone git://github.com/facebook/phabricator.git /home/vagrant/phabricator
        git clone git://github.com/facebook/libphutil.git /home/vagrant/libphutil
        git clone git://github.com/facebook/arcanist.git /home/vagrant/arcanist
        cd /home/vagrant/phabricator && ./bin/storage upgrade --force
    EOH
end

# Install custom script to easily install an admin.
template "/home/vagrant/phabricator/scripts/user/admin.php" do
    source "account.erb"
    mode 0777
end

bash "Install admin account" do
    user "vagrant"
    code <<-EOH
        cd /home/vagrant/phabricator/scripts/user && ./admin.php
    EOH
end

bash "Remove admin script" do
    user "vagrant"
    code <<-EOH
        rm /home/vagrant/phabricator/scripts/user/admin.php
    EOH
end

# Set the phabricator config.
template "/home/vagrant/phabricator/conf/custom.conf.php" do
    source "phabricator-config.erb"
    mode 0777
end

# Set nginx dependencies.
template "/etc/nginx/sites-available/phabricator" do
    source "nginx.erb"
    mode 0644
end

bash "Enable Phabricator for nginx" do
    code <<-EOH
        sudo ln -sf /etc/nginx/sites-available/phabricator /etc/nginx/sites-enabled/phabricator
    EOH
end

service "nginx" do
    action :reload
end
