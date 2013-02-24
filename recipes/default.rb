bash "Download Phabricator" do
    user "vagrant"
    code <<-EOH
        git clone git://github.com/facebook/phabricator.git /home/vagrant/phabricator
        git clone git://github.com/facebook/libphutil.git /home/vagrant/libphutil
        git clone git://github.com/facebook/arcanist.git /home/vagrant/arcanist
        cd /home/vagrant/phabricator && ./bin/storage upgrade --force
    EOH
end

template "/home/vagrant/phabricator/scripts/user/admin.php" do
    source "account.erb"
    mode 0777
end

template "/home/vagrant/phabricator/conf/custom.conf.php" do
    source "phabricator-config.erb"
    mode 0777
end

bash "Install admin account" do
    user "vagrant"
    code <<-EOH
        cd /home/vagrant/phabricator/scripts/user && ./admin.php
    EOH
end

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
