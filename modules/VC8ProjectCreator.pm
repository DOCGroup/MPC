package VC8ProjectCreator;

# ************************************************************
# Description   : A VC8 Project Creator
# Author        : Chad Elliott
# Create Date   : 4/17/2003
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use VC8ProjectCreator;

use vars qw(@ISA);
@ISA = qw(VC7ProjectCreator);

# ************************************************************
# Subroutine Section
# ************************************************************

sub get_vcversion {
  #my($self)  = shift;
  return '8,00';
}

1;
