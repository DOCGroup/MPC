package VC12ProjectCreator;

# ************************************************************
# Description   : A VC12 Project Creator
# Author        : Johnny Willemsen
# Create Date   : 10/29/2013
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use VC11ProjectCreator;

use vars qw(@ISA);
@ISA = qw(VC11ProjectCreator);

## NOTE: We call the constant as a function to support Perl 5.6.
my %info = (Creator::cplusplus() => {'ext'      => '.vcxproj',
                                     'dllexe'   => 'vc12exe',
                                     'libexe'   => 'vc12libexe',
                                     'dll'      => 'vc12dll',
                                     'lib'      => 'vc12lib',
                                     'template' => [ 'vc10', 'vc10filters' ],
                                    },
           );

my %config = ('vcversion' => '12.00',
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
