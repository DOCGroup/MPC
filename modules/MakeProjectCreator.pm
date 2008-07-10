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
# Data Section
# ************************************************************

my %info = ('cplusplus' => {'dllexe'   => 'makeexe',
                            'dll'      => 'makedll',
                            'template' => 'make',
                           },
            'csharp'    => {'dllexe'   => 'make.net',
                            'dll'      => 'make.net',
                            'template' => 'make.net',
                           },
            'java'      => {'dllexe'   => 'makeexe',
                            'dll'      => 'makedll',
                            'template' => 'make',
                           },
            'vb'        => {'dllexe'   => 'make.net',
                            'dll'      => 'make.net',
                            'template' => 'make.net',
                           },
           );

# ************************************************************
# Subroutine Section
# ************************************************************

sub escape_spaces {
  #my $self = shift;
  return 1;
}


sub get_dll_exe_template_input_file {
  return $info{$_[0]->get_language()}->{'dllexe'};
}


sub get_dll_template_input_file {
  return $info{$_[0]->get_language()}->{'dll'};
}


sub get_template {
  my($self) = shift;
  return $info{$self->get_language()}->{'template'};
}

sub fill_value {
  my($self, $name) = @_;

  if ($name eq 'compilers') {
    my $language = $self->get_language();
    if ($language eq 'java') {
      return 'java';
    }
    elsif ($language eq 'csharp') {
      return 'mcs';
    }
    else {
      return 'gcc';
    }
  }
  elsif ($name eq 'language') {
    return $self->get_language();
  }
  elsif ($name eq 'main') {
    my @sources = $self->get_component_list('source_files', 1);
    my $exename = $self->find_main_file(\@sources);
    return $exename if (defined $exename);
  }

  return undef;
}
1;
