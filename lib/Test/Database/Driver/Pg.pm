package Test::Database::Driver::Pg;
use strict;
use warnings;

use Test::Database::Driver;
our @ISA = qw( Test::Database::Driver );

use File::Spec;
use DBI;
use Data::Dumper;

my $verbose;

sub setup_engine {
    my ($class) = @_;

    # TODO: Update this documentation
    ########################################################################
    # Supports the following environment variables:
    # INITDB                   -- Location of initdb binary
    # INITDBARGS               -- Arguments to pass to initdb
    # VERBOSE                  -- Whether or not to print a bunch of messages
    # TEST_DATABASE_PORT       -- The port PostgreSQL should use
    # TEST_DATABASE_NOCLEANUP  -- If defined, the database directory will stick
    #                             around after the script exists

    # Get set up
    use Cwd;
    my $quiet      = $ENV{TEST_DATABASE_QUIET} || 0;
    $verbose       = !$quiet && ( $ENV{VERBOSE} || 0 );
    my $initdbargs = $ENV{TEST_DATABSE_INITDBARGS} || '';
	my $datadir    = $ENV{TEST_DATABASE_DATADIR} || getcwd().'/test_database_pgsql';
    my $port       = $ENV{TEST_DATABASE_PORT} || 54321;
    my $initdb     = $ENV{TEST_DATABASE_INITDB} || qx{which initdb} || 'initdb';
    chomp $initdb;      # Needed if $initdb came from qx{}
    warn "Creating PostgreSQL database instance in $datadir" if ($verbose > 0);

    # Initialize a directory
    my $cmd = "$initdb -D $datadir $initdbargs 2>&1";
    qx{$cmd};

    mkdir "$datadir/socket";
    mkdir "$datadir/pg_log";

    open my $fh, ">> $datadir/postgresql.conf"
        or die "Can't open $datadir/postgresql.conf to modify configuration";
    print $fh <<"END_PGCONF";
        listen_addresses = ''
        port = $port
        unix_socket_directory = '$datadir/socket/'
        log_destination = stderr
        logging_collector = on
END_PGCONF
    $quiet and print $fh "silent_mode = on\n";

    close $fh or warn "Couldn't close postgresql.conf";

    $verbose >= 1 and warn "PostgreSQL database instance created\n";
    return {
        pgdata => $datadir,
        port   => $port,
        socket => "$datadir/socket",
    };
}

sub start_engine {
    my ( $class, $config ) = @_;

    $verbose >= 1 and warn "Starting PostgreSQL database instance";
    my $pgctl      = $ENV{PGCTL} || qx{which pg_ctl} || 'pg_ctl';
    chomp $pgctl;

    my $datadir = $config->{pgdata};
    my $cmd     = "$pgctl -s -l $datadir/logfile -D $datadir start 2>&1";
    my $output  = qx{$cmd};

    return $config;
}

sub stop_engine {
    my ( $class, $config ) = @_;

    $verbose >=1 and warn "Stopping PostgreSQL database instance\n";
    my $pg_ctl = $ENV{PGCTL} || qx{which pg_ctl} || 'pg_ctl';
    chomp $pg_ctl;

    $class->run_cmd(
        $pg_ctl,
        'stop',
        "-D $config->{pgdata}",
        '-m immediate',
    );

    return 1;
}

sub create_database {
    my ( $class, $config, $dbname ) = @_;

}

'postgres';

__END__

=head1 NAME

Test::Database::Driver::Pg - A Test::Database driver for Pg

=head1 SYNOPSIS

    use Test::Database;
    my $dbh = Test::Database->dbh( 'Pg' );

=head1 DESCRIPTION

This module is the C<Test::Database> driver for C<DBD::Pg>.

=head1 SEE ALSO

L<Test::Database::Driver>

=head1 AUTHOR

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

