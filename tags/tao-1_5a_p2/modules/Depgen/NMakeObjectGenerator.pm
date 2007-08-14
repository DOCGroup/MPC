package WinProjectBaseEx;

use WinProjectBase;
use DirectoryManager;

use vars qw(@ISA);
@ISA = qw(WinProjectBase DirectoryManager);

sub new {
  return bless {};
}

1;


package NMakeObjectGenerator;

# ************************************************************
# Description   : Generates object files for NMake Makefiles.
# Author        : Chad Elliott
# Create Date   : 5/23/2003
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;
use ObjectGenerator;

use vars qw(@ISA);
@ISA = qw(ObjectGenerator);

# ************************************************************
# Subroutine Section
# ************************************************************

sub process {
  my($file) = $_[1];

  my($wpb) = new WinProjectBaseEx;
  my($noext) = $wpb->translate_directory($file);
  $noext =~ s/\.[^\.]+$//o;

  return [ "\"\$(INTDIR)\\$noext.obj\"" ];
}


1;
