use strict;
use warnings;
use lib '/usr/share/sympa/lib';
use Conf;
use Digest::MD5 qw(md5_hex);
use File::Path qw(make_path);
use Sympa::List;
use Sympa::Log;
use Sympa::User;

Conf::load() or die "Cannot load Sympa configuration\n";
Sympa::Log->instance->openlog('LOCAL1', 'unix', service => 'test-seed');

for my $email ('postmaster@sympa.test', 'reader@example.test') {
    Sympa::User->new($email, password => 'test', gecos => 'Integration user', lang => 'en_US')
        or die "Cannot create user $email\n";
}

for my $name ('testlist', 'partners') {
    my $directory = "/var/lib/sympa/list_data/$name";
    make_path($directory);
    open my $config, '>', "$directory/config" or die $!;
    print {$config} <<"CONFIG";
subject Test list $name

status open

visibility noconceal

subscribe open

unsubscribe open

review owner

topics testlist/testlist


owner
email postmaster\@sympa.test
profile privileged

editor
email postmaster\@sympa.test

CONFIG
    close $config or die $!;
    my $list = Sympa::List->new($name, 'sympa.test') or die "Cannot load list $name\n";
    if ($name eq 'testlist') {
        $list->add_list_member({email => 'reader@example.test', gecos => 'Test reader', subscribed => 1})
            or die "Cannot seed subscriber\n";
    }
}

open my $trusted, '>', '/etc/sympa/trusted_applications.conf' or die $!;
print {$trusted} "trusted_application\n  name mail-sympa-tests\n  md5password ",
    md5_hex('test-app-password'), "\n  proxy_for_variables USER_EMAIL\n\n";
close $trusted or die $!;

print "Seeded real Sympa users, lists, and trusted application.\n";
