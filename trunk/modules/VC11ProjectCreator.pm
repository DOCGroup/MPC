package VC11ProjectCreator;

# ************************************************************
# Description   : A VC11 Project Creator
# Author        : Johnny Willemsen
# Create Date   : 12/12/2011
# $Id$
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use VC10ProjectCreator;

use vars qw(@ISA);
@ISA = qw(VC10ProjectCreator);

## NOTE: We call the constant as a function to support Perl 5.6.
my %info = (Creator::cplusplus() => {'ext'      => '.vcxproj',
                                     'dllexe'   => 'vc11exe',
                                     'libexe'   => 'vc11libexe',
                                     'dll'      => 'vc11dll',
                                     'lib'      => 'vc11lib',
                                     'template' => [ 'vc10', 'vc10filters' ],
                                    },
           );

# ************************************************************
# Subroutine Section
# ************************************************************

sub get_info_hash {
  my($self, $key) = @_;

  ## If we have the setting in our information map, the use it.
  return $info{$key} if (defined $info{$key});

  ## Otherwise, see if our parent type can take care of it.
  return $self->SUPER::get_info_hash($key);
}

1;
