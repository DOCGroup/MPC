package VC6ProjectCreator;

# ************************************************************
# Description   : A VC6 Project Creator
# Author        : Chad Elliott
# Create Date   : 3/14/2002
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use ProjectCreator;
use VCProjectBase;

use vars qw(@ISA);
@ISA = qw(VCProjectBase ProjectCreator);

# ************************************************************
# Subroutine Section
# ************************************************************

sub validated_directory {
  my($self) = shift;
  my($dir)  = shift;

  ## VC6 (and EM3) do not deal with $(...) correctly
  if ($dir =~ /\$\(.*\)/) {
    return '.';
  }
  else {
    return $dir;
  }
}


sub project_file_extension {
  #my($self) = shift;
  return '.dsp';
}


sub override_valid_component_extensions {
  my($self)  = shift;
  my($comp)  = shift;
  my($array) = undef;

  if ($comp eq 'source_files' && $self->get_language() eq 'cplusplus') {
    $array = ["\\.cpp", "\\.cxx", "\\.c"];
  }

  return $array;
}


sub override_exclude_component_extensions {
  my($self)  = shift;
  my($comp)  = shift;
  my($array) = undef;

  if ($comp eq 'source_files') {
    my(@exts) = ("_T\\.cpp", "_T\\.cxx");
    $array = \@exts;
  }

  return $array;
}


sub get_dll_exe_template_input_file {
  #my($self) = shift;
  return 'vc6dspdllexe';
}


sub get_lib_exe_template_input_file {
  #my($self) = shift;
  return 'vc6dsplibexe';
}


sub get_lib_template_input_file {
  #my($self) = shift;
  return 'vc6dsplib';
}


sub get_dll_template_input_file {
  #my($self) = shift;
  return 'vc6dspdll';
}


sub get_template {
  #my($self) = shift;
  return 'vc6dsp';
}


1;
