# Class: psdash
#
# This class installs psdash
#
# Parameters:
#
# Actions:
#   - Install PSDash and dependencies
#   - https://github.com/Jahaja/psdash
#
# Requires:
#
# Sample Usage:
#
class psdash {
    # Distro-specific
    case $::operatingsystem {
        Debian, Ubuntu: { $python-dev = 'python-dev' }
        RedHat, CentOS, Fedora: { $python-dev = 'python-devel' }
        default: { $python-dev = 'python-dev' }
    }
    # Dependencies
    Package { ensure => "installed" }
    $dependencies = [ "sudo", "git", "gcc", "make", $python-dev, "python-setuptools" ]
    package { $dependencies: }
    # Installation
    file { '/opt/psdash':    
        ensure  => 'directory',
        group   => 'root',
        owner   => 'root',
        mode    => 0755,
    }
    vcsrepo { '/opt/psdash':
        before => Exec['install_psdash'],
        require => [ Package["git"], File['/opt/psdash'] ],
        ensure   => latest,
        owner    => 'root',
        group    => 'root',
        provider => git,
        source   => 'https://github.com/Jahaja/psdash.git',
        revision => 'master',
    }
    exec { 'rhel_sudo_fix':
        require => Package['sudo'],
        onlyif => [
                    "/bin/cat /etc/sudoers | /bin/grep '^Defaults\s*requiretty'",
                  ],
        cwd => '/etc',
        command => "/bin/sed -i -e 's/^Defaults.*requiretty/# Defaults requiretty/g' /etc/sudoers",
        path => '/bin/sed',
        logoutput => on_failure,
        before => Exec['install_psdash'],
    }
    exec { 'install_psdash':
        require => [ Exec['rhel_sudo_fix'], Package["python-setuptools"], Package[$python-dev], Package["gcc"], Package["make"], Package["sudo"] ],
        creates => '/usr/local/bin/psdash',
        cwd => '/opt/psdash',
        command => '/usr/bin/sudo /usr/bin/python setup.py install',
        path => '/usr/bin/sudo',
        logoutput => on_failure,
        before => File['/etc/init.d/psdash'],
    }
    # Start Service / Enable at boot
    file { '/etc/init.d/psdash':
        require => Exec['install_psdash'],
        ensure => 'present',
        owner => 'root',
        group => 'root',
        mode => '755',
        source => 'puppet:///modules/psdash/psdash',
    }
    service { 'psdash':
        require => File['/etc/init.d/psdash'],
        ensure => 'running',
        enable => true,
        hasrestart => true,
        hasstatus => true,
        status => '/usr/sbin/service psdash status | grep "Running"',
    }
}
