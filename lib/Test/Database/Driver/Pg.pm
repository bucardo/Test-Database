package Test::Database::Driver::Pg;
use strict;
use warnings;

use Test::Database::Driver;
our @ISA = qw( Test::Database::Driver );

use File::Spec;
use DBI;

sub setup_engine {
    my ($class) = @_;
	my $config;

	return $config;
}

sub start_engine {
    my ( $class, $config ) = @_;
	my $config;

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

