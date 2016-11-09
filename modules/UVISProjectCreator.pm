package UVISProjectCreator;

# ************************************************************
# Description   : The Keil uVision Project Creator
# Author        : Chad Elliott
# Create Date   : 11/1/2016
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use ProjectCreator;
use XMLProjectBase;
use WinProjectBase;

use vars qw(@ISA);
@ISA = qw(XMLProjectBase WinProjectBase ProjectCreator);

# ************************************************************
# Data Section
# ************************************************************

my $tmpl = 'uvis';

# ************************************************************
# Subroutine Section
# ************************************************************

sub compare_output {
  #my $self = shift;
  return 1;
}

sub dependency_is_filename {
  #my $self = shift;
  return 0;
}

sub project_file_extension {
  return '.uvprojx';
}


sub get_lib_exe_template_input_file {
  return $tmpl;
}


sub get_lib_template_input_file {
  return $tmpl;
}


sub get_dll_exe_template_input_file {
  return $tmpl;
}


sub get_dll_template_input_file {
  return $tmpl;
}


sub get_template {
  return 'uvis.mpd';
}


sub get_cmdsep_symbol {
  #my $self = shift;
  return '&amp;';
}


1;
