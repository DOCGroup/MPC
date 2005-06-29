package GHSProjectCreator;

# ************************************************************
# Description   : Not a complete implementation for GHS
# Author        : Chad Elliott
# Create Date   : 4/19/2002
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use ProjectCreator;

use vars qw(@ISA);
@ISA = qw(ProjectCreator);

# ************************************************************
# Subroutine Section
# ************************************************************

sub compare_output {
  #my($self) = shift;
  return 1;
}


sub convert_slashes {
  #my($self) = shift;
  return 0;
}


sub project_file_extension {
  #my($self) = shift;
  return '.bld';
}


sub fill_value {
  my($self)  = shift;
  my($name)  = shift;
  my($value) = undef;

  if ($name =~ /^reltop_(\w+)/) {
    $value = $self->relative($self->get_assignment($1));
    if (defined $value &&
        ($value =~ /^\.\.?$/ || $value =~ /^\.\.?\//)) {
      my($top)  = $self->escape_regex_special($self->getstartdir());
      my($part) = $self->getcwd();
      $part =~ s/^$top[\/]?//;
      if ($part ne '') {
        if ($value eq '.') {
          $value = $part;
        }
        else {
          $value = $part . '/' . $value;
        }
      }
    }
  }
  elsif ($name eq 'reltop') {
    my($top) = $self->escape_regex_special($self->getstartdir());
    $value = $self->getcwd();
    $value =~ s/^$top[\/]?//;
    if ($value eq '') {
      $value = '.';
    }
  }

  return $value;
}

sub get_dll_exe_template_input_file {
  #my($self) = shift;
  return 'ghsdllexe';
}


sub get_lib_exe_template_input_file {
  #my($self) = shift;
  return 'ghslibexe';
}


sub get_lib_template_input_file {
  #my($self) = shift;
  return 'ghslib';
}


sub get_dll_template_input_file {
  #my($self) = shift;
  return 'ghsdll';
}


1;
