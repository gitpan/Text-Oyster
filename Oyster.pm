package Text::Oyster;

# Copyright 2000-2001 by Steve McKay. All rights reserved.
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

# so our evals don't toss warnings;
#BEGIN {
#    $SIG{'__WARN__'} = sub { warn $_[0] if $WARNINGS }
#}

use strict;
use Carp;
use vars qw( @ISA $VERSION );
use Parse::Tokens;
@ISA = ('Parse::Tokens');

$VERSION = 0.26;

sub new
{
	my( $class, $params ) = @_;
	my $self = $class->SUPER::new;
	$self->delimiters( ['<?','?>'] );	# default delimiters
	$self->init( $params );
	$self;
}

sub init
{
	my( $self, $params ) = @_;
	no strict 'refs';
	my $hash;
	for ( keys %$params )
	{
		my $ref = lc $_;
		if( $_ eq 'hash' )
		{
			$hash = $params->{$_};
			next;
		}
		$self->$ref( $params->{$_} );
	}
	$self->hash( $hash ) if( defined $hash );
	use strict;
}

sub hash
{
	my( $self, $val ) = @_;
	if ( $val ){
		$self->_uninstall( $self->{hash} ) if $self->{hash};
		$self->{hash} = $val;
		$self->_install( $val );
	}
	return $self->{hash};
}

sub package
{
	my( $self, $val ) = @_;
	$self->{package} = $val if $val;
	# default to package main
	return $self->{package} || 'Safe';
}

sub inline_errs
{
	my( $self, $val ) = @_;
	$self->{inline_errs} = $val if $val;
	return $self->{inline_errs};
}

sub file
{
	my( $self, $val ) = @_;
	if( $val )
	{
		$self->{file} = $val;
		$self->text( &_get_file( $self->{file} ) );
	}
	return $self->{file};
}

sub parsed
{
	my( $self ) = @_;
	return $self->{parsed};
}

sub parse
{
	# overide SUPER::parse
	my( $self, $params ) = @_;
	$self->{parsed} = undef;
	$self->init( $params );
	return unless $self->{text};
	$self->SUPER::parse();
	return $self->{parsed};
}

sub token
{
	# overide SUPER::token

	my( $self, $token) = @_;
	my $package = $self->package();
	no strict 'vars';
	$WARNINGS = 0;
	$self->{parsed} .= eval qq{
		package $package;
		$token->[1];
	};
	$WARNINGS = 1;
	if( $@ ){
		carp $@;
		$self->{parsed} .= $@ if $self->{inline_errs};
	}
	use strict;
}

sub ether
{
	# overide SUPER::ether

	my( $self, $text ) = @_;
	$self->{parsed} .= $text;
}

sub _install
{
	# install a given hash in a package for later use

	my( $self, $hash ) = @_;
	my $package = $self->package();
	no strict 'refs';
	for( keys %{$hash} )
	{
		next unless defined $hash->{$_};
		*{$package."::$_"} = \$hash->{$_};
	}
	use strict;
	return 1;
}

sub _uninstall
{
	# clean up the contents of our package
	# called prior to the installation of a new hash

	my( $self, $hash ) = @_;
	my $package = $self->package();
	no strict 'refs';
	for( keys %{$hash} )
	{
		*{$package."::$_"} = \'';
	}
	use strict;
	return 1;
}

sub _get_file
{
	my( $file ) = @_;
	local *IN;
	open IN, $file || return;
   	local $/;
	my $text = <IN>;
	close IN;
	return $text;
}

1;

__END__

=head1 NAME

Perl::Hypotext - evaluate perl code embedded in text.

=head1 SYNOPSIS

  use Perl::Hypotext;

  # you can any argumnets at initialization
  my $t = Perl::Hypotext->new({});

  my $template = q{
    Yo nombre es [- $name -].
    I am [- $age -] years old.    	
  };

  # initialize a couple vars in package 'main'
  my $name = 'Steve';
  my $age  = 31;

  # parse defaults to package 'main' (unless a hash has been loaded)
  print $t->parse({
      text	=> $text
  });

  # or...use a hash ( slower, but MUCH easier to work with )

  my %hash = (
    name => 'Steve',
    age  => 31
  );

  print $t->parse({
      text	=> $text,
      hash	=> \%hash
  });

  # ...or however you like it, as long as text and hash or package name 
  # is loaded before or when parse() is called.

=head1 DESCRIPTION

C<Perl::Hypotext> a module for evaluating perl embedded in text. The perl can be evaluated under a specified package, or under a package built from a provided hash.

=head1 FUNCTIONS

=over 10

=item new()

Initializes a Perl::Hypotext object. Pass parameter as a hash reference. Optionally pass: delimiters, hash, package, text, file, inline_errs (see descriptions below).

=item hash()

Installs values identified by a given hash reference into a package under which to evaluate perl tokens.

=item text()

Install the text to be parsed as the template.

=item file()

Specify a file containing the text to be parsed as the template.

=item inline_errs()

Specify how to handle error messages generated during the evaluation of perl tokens. a true value = inline, a flase value = ignore.

=item package()

Set the package name under which to evaluate the extracted perl. If used in concert with a hash, the package name must be set prior to installation of a hash.

=item parse()

Runs the parser. Optionally accepts parameters as specified for new();.

=item parsed();

Returns the fully parsed and evaluated text.

=back

=head1 CHANGES

0.26 - Another name change...just cuz.
0.26 - Bug Fix: Internal package cleanup now works correctly when using hashes. REALLY!
0.25 - Name Change: Was stomping on a Template Toolkit module. Doh!
0.24 - Bug Fix: Internal package cleanup now works correctly when using hashes.
0.23 - Can now specify a package underwhich to install a hash (was explicitly 'Safe'). This also means that the package name must be set prior to or at the time of installation of a hash, or not at all.

Changed default delimiters to '<?' and '?>' (was '[-' and '-]').

=head1 AUTHOR

Steve McKay, steve@colgreen.com

=head1 COPYRIGHT

Copyright 2000-2001 Steve McKay. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

C<Parse::Tokens>, C<Text::Template>, C<Text::SimpleTemplate>

=cut
