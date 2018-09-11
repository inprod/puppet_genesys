node 'agent1.lan' {
  file { '/opt/lca':
    ensure => 'directory',
  }

  user { 'genesys':
    ensure => 'present',
  }

  # puppet module install puppet-archive --version 3.1.1
  archive { '/opt/lca/IP_LCA_8500009b1_ENU_linux.tar':
    ensure          => present,
    extract         => true,
    extract_path    => '/opt/lca',
    source          => 'http://puppetmaster/IP_LCA_8500009b1_ENU_linux.tar',
    cleanup         => false,
    creates         => '/opt/lca/ip/data.tar.gz',
    extract_command => 'tar --to-command=\'tar -z -x -v\' -x -v -f %s ip/data.tar.gz',
  }


  file {'/opt/lca/lca.cfg':
    ensure  => present,
    content => "
  [log]
  enable-thread=true
  verbose = standard
  all = lca
  expire = 5
  segment = 10000
  "
  }


  file {'/etc/systemd/system/lca.service':
    ensure  => present,
    content => "
  [Unit]
  Description=Genesys LCA
  After=network.target

  [Service]
  ExecStart=/opt/lca/lca_64
  TimeoutStartSec=30
  Restart=on-failure
  RestartSec=30
  StartLimitInterval=350
  StartLimitBurst=10

  [Install]
  WantedBy=default.target
  "
  }

  service { 'lca':
   enable => true,
   ensure => 'running',
  }

  # puppet module install puppetlabs-firewall --version 1.12.0
  class { 'firewall':}

  firewall { '000 allow lca access':
    dport  => 4999,
    proto  => tcp,
    action => accept,
  }

  changeset {"Create host":
    action => "executejson",
    path => '/root/Puppet.json',
    apihost=>'http://demo-box',
    apiusername=>'jarrod',
    apipassword=>'p',
    ensure => present
  }
}
