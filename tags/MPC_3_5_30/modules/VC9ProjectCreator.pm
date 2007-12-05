package VC9ProjectCreator;

# ************************************************************
# Description   : A VC9 Project Creator
# Author        : Johnny Willemsen
# Create Date   : 11/22/2007
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use VC8ProjectCreator;

use vars qw(@ISA);
@ISA = qw(VC8ProjectCreator);

my(%config) = ('vcversion' => '9.00',
              );

# ************************************************************
# Subroutine Section
# ************************************************************

sub get_configurable {
  my($self)   = shift;
  my($name)   = shift;
  return $config{$name};
}

1;
