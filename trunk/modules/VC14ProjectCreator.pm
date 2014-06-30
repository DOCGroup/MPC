package VC14ProjectCreator;

# ************************************************************
# Description   : A VC14 Project Creator
# Author        : Johnny Willemsen
# Create Date   : 6/04/2014
# $Id$
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use VC12ProjectCreator;

use vars qw(@ISA);
@ISA = qw(VC12ProjectCreator);

## NOTE: We call the constant as a function to support Perl 5.6.
my %info = (Creator::cplusplus() => {'ext'      => '.vcxproj',
                                     'dllexe'   => 'vc14exe',
                                     'libexe'   => 'vc14libexe',
                                     'dll'      => 'vc14dll',
                                     'lib'      => 'vc14lib',
                                     'template' => [ 'vc10', 'vc10filters' ],
                                    },
           );

my %config = ('vcversion' => '14.00',
             );

# ************************************************************
# Subroutine Section
# ************************************************************

sub get_info_hash {
  my($self, $key) = @_;

  ## If we have the setting in our information map, then use it.
  return $info{$key} if (defined $info{$key});

  ## Otherwise, see if our parent type can take care of it.
  return $self->SUPER::get_info_hash($key);
}

sub get_configurable {
  my($self, $name) = @_;

  ## If we have the setting in our config map, then use it.
  return $config{$name} if (defined $config{$name});

  ## Otherwise, see if our parent type can take care of it.
  return $self->SUPER::get_configurable($name);
}

1;
