package NMakeProjectCreator;

# ************************************************************
# Description   : An NMake Project Creator
# Author        : Chad Elliott
# Create Date   : 5/31/2002
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use WinVersionTranslator;
use ProjectCreator;

use vars qw(@ISA);
@ISA = qw(ProjectCreator);

# ************************************************************
# Subroutine Section
# ************************************************************

sub dollar_special {
  #my($self) = shift;
  return 1;
}


sub sort_files {
  #my($self) = shift;
  return 0;
}


sub crlf {
  my($self) = shift;
  return $self->windows_crlf();
}


sub project_file_name {
  my($self) = shift;
  my($name) = shift;

  if (!defined $name) {
    $name = $self->project_name();
  }

  return $self->get_modified_project_file_name($name, '.mak');
}


sub fill_value {
  my($self)  = shift;
  my($name)  = shift;
  my($value) = undef;

  if ($name eq 'win_version') {
    $value = $self->get_assignment('version');
    if (defined $value) {
      $value = WinVersionTranslator::translate($value);
    }
  }

  return $value;
}

sub get_dll_exe_template_input_file {
  #my($self) = shift;
  return 'nmakeexe';
}


sub get_dll_template_input_file {
  #my($self) = shift;
  return 'nmakedll';
}


sub get_template {
  #my($self) = shift;
  return 'nmake';
}


1;
