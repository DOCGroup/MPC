package MakeProjectCreator;

# ************************************************************
# Description   : A Generic Make Project Creator
# Author        : Chad Elliott
# Create Date   : 2/18/2003
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

sub escape_spaces {
  #my($self) = shift;
  return 1;
}


sub get_dll_exe_template_input_file {
  #my($self) = shift;
  return 'makeexe';
}


sub get_dll_template_input_file {
  #my($self) = shift;
  return 'makedll';
}


sub fill_value {
  my($self)  = shift;
  my($name)  = shift;

  if ($name eq 'compilers') {
    if ($self->get_language() eq 'java') {
      return 'java';
    }
    else {
      return 'gcc';
    }
  }
  elsif ($name eq 'language') {
    return $self->get_language();
  }
  elsif ($name eq 'main') {
    my(@sources) = $self->get_component_list('source_files', 1);
    my($exename) = $self->find_main_file(\@sources);
    return $exename if (defined $exename);
  }

  return undef;
}
1;
