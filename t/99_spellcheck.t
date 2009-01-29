#!perl

## Spellcheck as much as we can
## Requires TEST_SPELL to be set

use 5.006;
use strict;
use warnings;
use Test::More;
select(($|=1,select(STDERR),$|=1)[1]);

my (@testfiles, $fh);

if (!$ENV{TEST_SPELL}) {
	plan skip_all => 'Set the environment variable TEST_SPELL to enable this test';
}
elsif (!eval { require Text::SpellChecker; 1 }) {
	plan skip_all => 'Could not find Text::SpellChecker';
}
else {
	opendir my $dir, 't' or die qq{Could not open directory 't': $!\n};
	@testfiles = map { "t/$_" } grep { /^.+\.(t|pl)$/ } readdir $dir;
	closedir $dir or die qq{Could not closedir "$dir": $!\n};
	plan tests => 18+@testfiles;
}

my %okword;
my $file = 'Common';
while (<DATA>) {
	if (/^## (.+):/) {
		$file = $1;
		next;
	}
	next if /^#/ or ! /\w/;
	for (split) {
		$okword{$file}{$_}++;
	}
}


sub spellcheck {
	my ($desc, $text, $file) = @_;
	my $check = Text::SpellChecker->new(text => $text);
	my %badword;
	while (my $word = $check->next_word) {
		next if $okword{Common}{$word} or $okword{$file}{$word};
		$badword{$word}++;
	}
	my $count = keys %badword;
	if (! $count) {
		pass ("Spell check passed for $desc");
		return;
	}
	fail ("Spell check failed for $desc. Bad words: $count");
	for (sort keys %badword) {
		diag "$_\n";
	}
	return;
}


## First, the plain ol' textfiles
for my $file (qw/ README Changes /) {
	if (!open $fh, '<', $file) {
		fail (qq{Could not find the file "$file"!});
	}
	else {
		{ local $/; $_ = <$fh>; }
		close $fh or warn qq{Could not close "$file": $!\n};
		spellcheck ($file => $_, $file);
	}
}

## Now the embedded POD
SKIP: {
	if (!eval { require Pod::Spell; 1 }) {
		skip ('Need Pod::Spell to test the spelling of embedded POD', 2);
	}

	## TODO: Build list of .pm files dynamically in one place
	for my $file (qw{
lib/Test/Database.pm
lib/Test/Database/Driver.pm
lib/Test/Database/Driver/CSV.pm
lib/Test/Database/Driver/DBM.pm
lib/Test/Database/Driver/SQLite.pm
lib/Test/Database/Driver/mysql.pm
lib/Test/Database/Driver/Pg.pm
lib/Test/Database/Handle.pm
}) {
		if (! -e $file) {
			fail (qq{Could not find the file "$file"!});
		}
		my $string = qx{podspell $file};
		spellcheck ("POD from $file" => $string, $file);
	}
}

## Now the comments
SKIP: {
	if (!eval { require File::Comments; 1 }) {
		skip ('Need File::Comments to test the spelling inside comments', 11+@testfiles);
	}

	my $fc = File::Comments->new();

	my @files;
	for (sort @testfiles) {
		push @files, "$_";
	}


	for my $file (@testfiles, qw{
Makefile.PL
lib/Test/Database.pm
lib/Test/Database/Driver.pm
lib/Test/Database/Driver/CSV.pm
lib/Test/Database/Driver/DBM.pm
lib/Test/Database/Driver/SQLite.pm
lib/Test/Database/Driver/mysql.pm
lib/Test/Database/Driver/Pg.pm
lib/Test/Database/Handle.pm
							}) {
		## TODO: Add tests
		if (! -e $file) {
			fail (qq{Could not find the file "$file"!});
		}
		my $string = $fc->comments($file);
		if (! $string) {
			fail (qq{Could not get comments from file $file});
			next;
		}
		$string = join "\n" => @$string;
		$string =~ s/=head1.+//sm;
		spellcheck ("comments from $file" => $string, $file);
	}


}


__DATA__
## These words are okay

## Common:

accessors
TODO
Ferraz
DBD
TCP
startup
Bruhat
CPAN
DSN
ACKNOWLEDGEMENTS
AnnoCPAN
BooK
DBI
username
ol
undef
perl
README
dev
yml
YAML
YAMLiciousness
env
SQLite
CSV
DBM
hntopp

## README:

BooK
Bruhat
CPAN
CPAN's
LICENCE
Makefile
NoAuth
Schwern
annocpan
cpan
cpanratings
html
http
perldoc

## Changes:
CEST
CSV
DBD
DBM
SQlite
mysql
uninstalled

## t/99_spellcheck.t:
Spellcheck
textfiles

