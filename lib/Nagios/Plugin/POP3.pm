package Nagios::Plugin::POP3;

use warnings;
use strict;
use Nagios::Plugin;
use Mail::POP3Client;

=head1 NAME

Nagios::Plugin::POP3 - Nagios plugin for checking POP3 Servers

head1 DESCRIPTION

Currently only two POP3 mailbox actions are supported: C<count> and C<delete>

=over 4

=item * count

Counts the number of messages on the server. The messages are not modified.

=item * delete

Deletes all messages on the server (and returns then number deleted)

=back

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Installs the C<nagios_plugin_pop3> command that can be used as:

    > nagios_plugin_pop3 --help
    nagios_plugin_pop3 0.01

    This nagios plugin is free software, and comes with ABSOLUTELY NO WARRANTY. 
    It may be used, redistributed and/or modified under the terms of the GNU 
    General Public Licence (see http://www.fsf.org/licensing/licenses/gpl.txt).

    Nagios plugin for POP3 mailboxes

    Usage: nagios_plugin_pop3 [ -v|--verbose ] [-h|--host=<host>] [-u|--user=<user>] [-p|--password=<password>] [--count] [--delete]
    [ -c|--critical=<critical threshold> ] 
    [ -w|--warning=<warning threshold> ]  

     -?, --usage
       Print usage information
     -h, --help
       Print detailed help screen
     -V, --version
       Print version information
     --extra-opts=[<section>[@<config_file>]]
       Section and/or config_file from which to load extra options (may repeat)
     -w, --warning=INTEGER:INTEGER
    Minimum and maximum number of allowable result, outside of which a
    warning will be generated.  If omitted, no warning is generated.

     -c, --critical=INTEGER:INTEGER
    Minimum and maximum number of the generated result, outside of
    which a critical will be generated.

     -h, --host
    POP3 Host (defaults to localhost.localdomain)

     -u, --username
    POP3 Username

     -p, --password
    POP3 password

     --count
    Count the number of messages on the server. The messages on the server are not modified.
    This is the default action. 

     --delete
    Delete all messages on the server. Counts how many messages were deleted.

     -t, --timeout=INTEGER
       Seconds before plugin times out (default: 15)
     -v, --verbose
       Show details for command-line debugging (can repeat up to 3 times)
    Currently only two POP3 mailbox actions are supported: count and delete

    Count - Counts the number of messages on the server. The messages are not modified.
    Delete - Deletes all messages on the server (and returns then number deleted)

    THRESHOLDs for -w and -c are specified 'min:max' or 'min:' or ':max'
    (or 'max'). If specified '@min:max', a warning status will be generated
    if the count *is* inside the specified range.
    
For example, if you have a process that sends an email to a pop3 mailbox once per day, you can
get nagios to check the mailbox for a single message (and delete all messages) every day via:

    nagios_plugin_pop3 -h myhost -u myname -p mypass -c 1:1 --delete

=cut

=head1 METHODS

=head2 run

Run the plugin

=cut

sub run {

    my $p = Nagios::Plugin->new(
        usage => <<END_USAGE,
Usage: %s [ -v|--verbose ] [-h|--host=<host>] [-u|--user=<user>] [-p|--password=<password>] [--count] [--delete]
[ -c|--critical=<critical threshold> ] 
[ -w|--warning=<warning threshold> ]  
END_USAGE
        version => $VERSION,
        blurb   => q{Nagios plugin for POP3 mailboxes},
        extra   => <<END_EXTRA,
Currently only two POP3 mailbox actions are supported: count and delete

Count - Counts the number of messages on the server. The messages are not modified.
Delete - Deletes all messages on the server (and returns then number deleted)

THRESHOLDs for -w and -c are specified 'min:max' or 'min:' or ':max'
(or 'max'). If specified '\@min:max', a warning status will be generated
if the count *is* inside the specified range.
END_EXTRA
    );

    $p->add_arg(
        spec => 'warning|w=s',
        help => <<END_HELP,
-w, --warning=INTEGER:INTEGER
Minimum and maximum number of allowable result, outside of which a
warning will be generated.  If omitted, no warning is generated.
END_HELP
    );

    $p->add_arg(
        spec => 'critical|c=s',
        help => <<END_HELP,
-c, --critical=INTEGER:INTEGER
Minimum and maximum number of the generated result, outside of
which a critical will be generated.
END_HELP
    );

    $p->add_arg(
        spec    => 'host|h=s',
        default => 'localhost.localdomain',
        help    => <<END_HELP,
-h, --host
POP3 Host (defaults to localhost.localdomain)
END_HELP
    );

    $p->add_arg(
        spec => 'username|u=s',
        help => <<END_HELP,
-u, --username
POP3 Username
END_HELP
    );

    $p->add_arg(
        spec => 'password|p=s',
        help => <<END_HELP,
-p, --password
POP3 password
END_HELP
    );
    
    $p->add_arg(
        spec => 'count',
        help => <<END_HELP,
--count
Count the number of messages on the server. The messages on the server are not modified.
This is the default action. 
END_HELP
    );

    $p->add_arg(
        spec => 'delete',
        help => <<END_HELP,
--delete
Delete all messages on the server. Counts how many messages were deleted.
END_HELP
    );

    # Parse arguments and process standard ones (e.g. usage, help, version)
    $p->getopts;

    if ( !defined $p->opts->warning && !defined $p->opts->critical ) {
        $p->nagios_die("You need to specify a threshold argument");
    }

    my $pop = new Mail::POP3Client(
        USER     => $p->opts->username,
        PASSWORD => $p->opts->password,
        HOST     => $p->opts->host,
    );
    my $count = $pop->Count;
    $p->nagios_die("Error connecting to server: " . $p->opts->host) if $count < 0;
    
    for my $i ( 1 .. $count ) {
        $pop->Delete($i) if $p->opts->delete,
    }
    $pop->Close();

    $p->nagios_exit(
        return_code => $p->check_threshold($count),
        message     => 
            ( $p->opts->delete ? 'Deleted ' : 'Counted ' )
            . "$count message"
            . ( $count == 1 ? "\n" : "s\n" ),
    );
}

=head1 AUTHOR

Patrick Donelan, C<< <pdonelan at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-nagios-plugin-pop3 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Nagios-Plugin-POP3>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Nagios::Plugin::POP3


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Nagios-Plugin-POP3>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Nagios-Plugin-POP3>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Nagios-Plugin-POP3>

=item * Search CPAN

L<http://search.cpan.org/dist/Nagios-Plugin-POP3/>

=back


=head1 SEE ALSO

L<Nagios::Plugin>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Patrick Donelan, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;
