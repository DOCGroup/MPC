package AutomakeProjectCreator;

# ************************************************************
# Description   : A Automake Project Creator
# Author        : J.T. Conklin & Chad Elliott
# Create Date   : 2/26/2003
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use MakeProjectBase;
use ProjectCreator;

use vars qw(@ISA);
@ISA = qw(MakeProjectBase ProjectCreator);

# ************************************************************
# Subroutine Section
# ************************************************************

sub use_reldefs {
  #my($self) = shift;
  return 0;
}


sub sort_files {
  #my($self) = shift;
  return 1;
}


sub convert_slashes {
  #my($self) = shift;
  return 0;
}


sub fill_value {
  my($self)  = shift;
  my($name)  = shift;
  my($value) = undef;

  if ($name eq 'am_includes') {
    my($incs) = $self->get_assignment('includes');
    if (defined $incs) {
      my(@vec) = split(' ', $incs);
      foreach(@vec) {
        if (/^[^\$\/]/) {
          $_ = '$(srcdir)/' . $_;
        }
      }

      $value = \@vec;
    }
  }
  elsif ($name eq 'am_version') {
    $value = $self->get_assignment('version');
    if (defined $value) {
      if (($value =~ tr/./:/) < 2) {
        $value .= ':0';
      }
    }
  }

  return $value;
}


sub project_file_extension {
  #my($self) = shift;
  return '.am';
}


sub get_dll_exe_template_input_file {
  #my($self) = shift;
  return 'automakeexe';
}


sub get_dll_template_input_file {
  #my($self) = shift;
  return 'automakedll';
}


sub get_template {
  #my($self) = shift;
  return 'automake';
}


1;
