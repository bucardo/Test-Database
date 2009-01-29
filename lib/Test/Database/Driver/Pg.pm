package Test::Database::Driver::Pg;
use strict;
use warnings;

use Test::Database::Driver;
our @ISA = qw( Test::Database::Driver );

use File::Spec;
use DBI;

sub setup_engine {
    my ($class) = @_;

    ########################################################################
    # Supports the following environment variables:
    # INITDB                   -- Location of initdb binary
    # INITDBARGS               -- Arguments to pass to initdb
    # VERBOSE                  -- Whether or not to print a bunch of messages
    # TEST_DATABASE_PORT       -- The port PostgreSQL should use
    # TEST_DATABASE_NOCLEANUP  -- If defined, the database directory will stick
    #                             around after the script exists

    # Get set up
    use File::Temp qw( tempdir );;
    use Data::Dumper;
    my $initdb     = $ENV{INITDB} || qx{which initdb} || 'initdb';
    chomp $initdb;      # Needed if $initdb came from qx{}
    my $quiet      = $ENV{QUIET} || 0;
    my $verbose    = !$quiet && ( $ENV{VERBOSE} || 0 );
	$verbose = 1;
    my $initdbargs = $ENV{INITDBARGS} || '';
    my $datadir    = defined $ENV{TEST_DATABASE_NOCLEANUP} ? tempdir() : tempdir( CLEANUP => 1 );
	$datadir = 'test_database_pgsql';
    my $port       = $ENV{TEST_DATABASE_PORT} || 54321;
    warn "Creating PostgreSQL database instance in $datadir" if ($verbose > 0);

    # Initialize a directory
    my $cmd = "$initdb -D $datadir $initdbargs 2>&1";
    qx{$cmd};

    mkdir "$datadir/socket"
        or die "Couldn't make a socket directory $datadir/socket";

    open my $fh, ">> $datadir/postgresql.conf"
        or die "Can't open $datadir/postgresql.conf to modify configuration";
    print $fh <<"END_PGCONF";
        listen_address = ''
        port = $port
        unix_socket_directory = $datadir/socket
END_PGCONF
    $verbose and print $fh "silent_mode = on\n";

    close $fh or "Couldn't close postgresql.conf";

    return {
        pgdata => $datadir,
        port   => $port,
        socket => "$datadir/socket",
    };
}

sub start_engine {
    my ( $class, $config ) = @_;

    return $config;
}

sub stop_engine {
    my ( $class, $config ) = @_;

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

