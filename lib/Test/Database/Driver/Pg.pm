package Test::Database::Driver::Pg;
use strict;
use warnings;

use Test::Database::Driver;
our @ISA = qw( Test::Database::Driver );

use File::Spec;
use DBI;
use Data::Dumper;

my ($pgctl, $verbose);

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
    $verbose       = !$quiet && ( $ENV{VERBOSE} || 1 );
    my $initdbargs = $ENV{TEST_DATABSE_INITDBARGS} || '';
	my $datadir    = $ENV{TEST_DATABASE_DATADIR} || getcwd().'/test_database_pgsql';
    my $port       = $ENV{TEST_DATABASE_PORT} || 54321;
    my $initdb     = $ENV{TEST_DATABASE_INITDB} || qx{which initdb} || 'initdb';
    chomp $initdb;      # Needed if $initdb came from qx{}
    print "Creating PostgreSQL database instance in $datadir" if ($verbose > 0);

    # Initialize a directory
    my $cmd = "$initdb -D $datadir $initdbargs 2>&1";
    qx{$cmd};

    mkdir "$datadir/socket";

    open my $fh, ">> $datadir/postgresql.conf"
        or die "Can't open $datadir/postgresql.conf to modify configuration";
    print $fh <<"END_PGCONF";
        listen_addresses = ''
        port = $port
        unix_socket_directory = '$datadir/socket/'
        log_destination = stderr
        #log_filename = 'postgresql.log'
        #logging_collector = on
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

    $pgctl = $ENV{PGCTL} || qx{which pg_ctl} || 'pg_ctl';
    chomp $pgctl;

    my $datadir = $config->{pgdata};
    my $cmd     = "$pgctl -w -s -l $datadir/logfile -D $datadir start 2>&1";
    my $output  = qx{$cmd};
    die "Error starting PostgreSQL: $output" if $output;

    open my $fh, '<', "$datadir/logfile"
        or die "Couldn't open log file $datadir/logfile: $!";
    seek $fh, -100, 2;
    WATCHLOG: {
          while (<$fh>) {
              last WATCHLOG if /system is ready/;
          }
          sleep 0.1;
          seek $fh, 0, 1;
          redo;
    }
    print "Database started successfully" if ($verbose > 0);
    close $fh;


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
        '-D',
        "$config->{pgdata}",
        '-m',
        'immediate',
    );

    return 1;
}

sub create_database {
    my ( $class, $config, $dbname ) = @_;

     my $dsn = join ';', "dbi:Pg:db=postgres;host=$config->{socket}", "port=$config->{port}";

     my $user = $ENV{user} || $class->username() || 'postgres';
     if (!-e File::Spec->catdir($class->base_dir(), 'postgres' )) {
         # TODO make user configurable
         my $dbh = DBI->connect($dsn, $user, 'postgres');
         $dbh->do ("CREATE DATABASE $dbname");
     }
 
     return Test::Database::Handle->new(
         dsn      => "$dsn",
         username => $class->username(),
     );
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

