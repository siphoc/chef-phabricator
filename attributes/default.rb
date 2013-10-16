default['phabricator']['username'] = 'admin'
default['phabricator']['email'] = 'jelmer@siphoc.com'
default['phabricator']['password'] = 'root'

default['phabricator']['domain'] = 'phabricator.dev'
# todo: fix port
default['phabricator']['full-domain'] = 'http://phabricator.dev:4567'

# user to own the checked out files
default['phabricator']['user'] = 'vagrant'
# dir where phabricator and deps are installed
default['phabricator']['install_dir'] = '/home/vagrant'

# packages to install before proceeding, php, nginx, etc
default['phabricator']['packages'] = %w{}
