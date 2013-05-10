# boilerplate
group { 'puppet': ensure => present, }

# resource defaults
Exec {
  path => '/root/.rbenv/shims:/root/.rbenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/X11R6/bin',
}

Package {
  ensure => present,
}

# install and configure all th necessary software for GVS
file { '/home/vagrant/src': ensure => directory, }
->
exec { 'apt-get update': }
->
package { 'git-core': }
->
package { 'pandoc': }
->
package { 'build-essential': }
->
exec { 'git clone git://github.com/sstephenson/rbenv.git ~/.rbenv':
  creates => '/root/.rbenv',
}
->
exec { 'echo \'export PATH="$HOME/.rbenv/bin:$PATH"\' >> ~/.profile':
  unless => 'grep \'export PATH="$HOME/.rbenv/bin:$PATH"\' ~/.profile',
}
->
exec { 'echo \'eval "$(rbenv init -)"\' >> ~/.profile':
  unless => 'grep \'eval "$(rbenv init -)"\' ~/.profile',
}
->
exec { 'git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build': 
  creates => '/root/.rbenv/plugins/ruby-build',
}
->
exec { 'rbenv install 1.9.3-p392': 
  cwd     => '/root',
  timeout => '0',
  creates => '/root/.rbenv/versions/1.9.3-p392',
}
->
exec { 'git clone git://github.com/dhgwilliam/google-voice-stats.git':
  cwd     => '/home/vagrant/src',
  creates => '/home/vagrant/src/google-voice-stats',
}
->
exec { 'gem install bundler': }
->
exec { 'rbenv rehash': }
->
exec { 'bundle install --binstubs': 
  cwd  => '/home/vagrant/src/google-voice-stats',
}
->
exec { 'wget http://redis.googlecode.com/files/redis-2.6.13.tar.gz':
  cwd => '/home/vagrant/src',
}
->
exec { 'tar xvzf redis-2.6.13.tar.gz':
  cwd => '/home/vagrant/src',
  creates => '/home/vagrant/src/redis-2.6.13',
}
->
exec { 'make':
  cwd => '/home/vagrant/src/redis-2.6.13',
}
->
exec { 'make install':
  cwd     => '/home/vagrant/src/redis-2.6.13',
  creates => '/usr/local/bin/redis-server',
}
->
exec {'redis-server &': }

