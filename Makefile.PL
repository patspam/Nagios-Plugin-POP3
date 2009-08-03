use inc::Module::Install;

name     'Nagios-Plugin-POP3';
all_from 'lib/Nagios/Plugin/POP3.pm';
author   'Patrick Donelan <pdonelan@cpan.org>';
license  'perl';

build_requires 'Test::More';
requires 'Nagios::Plugin';
requires 'Mail::POP3Client';

install_script 'nagios_plugin_pop3';

auto_install;

WriteAll;

