package VC8ProjectCreator;

# ************************************************************
# Description   : A VC8 Project Creator
# Author        : Johnny Willemsen
# Create Date   : 4/21/2004
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use VC7ProjectCreator;

use vars qw(@ISA);
@ISA = qw(VC7ProjectCreator);

# ************************************************************
# Subroutine Section
# ************************************************************

sub get_vcversion {
  #my($self) = shift;
  return '8.00';
}

1;
