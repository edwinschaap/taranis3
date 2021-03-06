# This file is part of Taranis, Copyright NCSC-NL. See http://taranis.ncsc.nl
# Licensed under EUPL v1.2 or newer, https://spdx.org/licenses/EUPL-1.2.html

package Taranis::Config;

use strict;
use Taranis qw(:all);
use XML::Simple;

# overwritten in TestUtil
our $mainconfig = "$ENV{HOME}/etc/taranis.conf.xml";

my $xs = XML::Simple->new(NormaliseSpace => 2, SuppressEmpty => '');

sub new(;$) {
	my ($class, $config_relfn) = @_;
	$config_relfn ||= $mainconfig;
	my $config_fn = find_config $config_relfn
		or die "ERROR: cannot find config file $config_relfn\n";

	my @xml = $xs->XMLin($config_fn);
	my $cfglayout = $xml[0];

	bless $cfglayout, $class;
}

sub getSetting {
	# remain backward compatible
	my $self = shift;
	my $want = $_[0];

	if (ref(\$self) eq "REF") {
		return $self->{$want};
	} else {
		if ($self !~ /Taranis::Config/) {
			$want = $self;
			$self = 'Taranis::Config';
		}
		my $cfg = $self->new();
		if ($cfg->{$want}) {
			return $cfg->{$want};
		} else {
			return;
		}
	}
}

sub saveSettings {
	my ( $self, %settings ) = @_;
	undef $self->{errmsg};

	my $file = delete $settings{file};

	eval{
		my $fh;
		open( $fh, ">", $file) or $self->{errmsg} = "open($file): $!";
		XMLout( \%settings, NoAttr => 1, RootName => 'settings', OutputFile => $fh, XMLDecl => 1 );
		close $fh;
	};
	
	if ($@) {
		$self->{errmsg} = $@;
		return 0;
	} else {
		return 1;
	}
}

=head1 NAME 

Taranis::Config - Module for retrieving configuration settings from XML files.

=head1 SYNOPSIS

  use Taranis::Config;

  my $obj = Taranis::Config->new( '/optional/path/to/alternative.xml' );

  $obj->getSetting( 'config setting' );

  $obj->saveSettings( %saveSettings );

=head1 DESCRIPTION

This module is used for retrieving and editing settings stored in XML files. 
Mostly used for retrieving configuration settings from the main configuration file.

=head1 METHODS

=head2 new( '/optional/path/to/alternative.xml' )

Constructor of the C<Taranis::Config> module.
Takes a XML configuration file path as optional argument.
If the argument is undefined it will use the main configuration file specified in $mainconfig (normally
taranis.conf.xml).

    my $obj = Taranis::Config->new( '/opt/taranis/conf/taranis.conf.example.xml' );

OR

    my $obj = Taranis::Config->new();

Returns a blessed ARRAY containing the configuration.

=head2 getSetting( 'config setting' )

Method for retrieving one configuration setting. May be used as in OO context as well as direct use.
Takes one the configuration setting name as argument.

    my $config_setting = $cfg->getSetting( 'config setting' );

OR 

    my $config_setting = Taranis::Config->getSetting( 'config setting' );

Return the setting if present. If not it returns undef. 

=head2 saveSettings( %saveSettings )

Method for saving configuration settings back to file.

Takes a HASH with all the settings as argument.

    $obj->saveSettings( earthling => 'Arthur Dent', answer => 42, etc... );

Returns TRUE if saving of settings is ok. Returns FALSE if it fails, and will set C<< $obj->{errmsg} >> to the error generated by C<XML::Simple>. 

=head1 DIAGNOSTICS

The following messages can be expected from this module:

=over

=item *

I<error in XML ...>

The method will die on this error if C<XML::Simple> cannot read the XML file. You should probably check the XML syntax of the XML file.

=back

=cut

1;
