package VC7ProjectCreator;

# ************************************************************
# Description   : A VC7 Project Creator
# Author        : Chad Elliott
# Create Date   : 4/23/2002
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use GUID;
use ProjectCreator;
use VCProjectBase;

use vars qw(@ISA);
@ISA = qw(VCProjectBase ProjectCreator);

# ************************************************************
# Data Section
# ************************************************************

my(%info) = ('cplusplus' => {'ext'      => '.vcproj',
                             'dllexe'   => 'vc7exe',
                             'libexe'   => 'vc7libexe',
                             'dll'      => 'vc7dll',
                             'lib'      => 'vc7lib',
                             'template' => 'vc7',
                            },
             'csharp'    => {'ext'      => '.csproj',
                             'dllexe'   => 'vc7csharp',
                             'libexe'   => 'vc7csharp',
                             'dll'      => 'vc7csharp',
                             'lib'      => 'vc7csharp',
                             'template' => 'vc7csharp',
                            },
             'vb'        => {'ext'      => '.vbproj',
                             'dllexe'   => 'vc7vb',
                             'libexe'   => 'vc7vb',
                             'dll'      => 'vc7vb',
                             'lib'      => 'vc7vb',
                             'template' => 'vc7vb',
                            },
            );

# ************************************************************
# Subroutine Section
# ************************************************************

sub get_info_hash {
  my($self) = shift;
  my($key)  = shift;
  return $info{$key};
}

sub get_quote_symbol {
  #my($self) = shift;
  return '&quot;';
}


sub get_gt_symbol {
  #my($self) = shift;
  return '&gt;';
}


sub get_lt_symbol {
  #my($self) = shift;
  return '&lt;';
}


sub get_and_symbol {
  #my($self) = shift;
  return '&amp;&amp;';
}


sub get_configurable {
  my($self)   = shift;
  my($name)   = shift;
  my(%config) = ('vcversion'    => '7.00',
                 'forloopscope' => 'TRUE',
                );
  return $config{$name};
}


sub fill_value {
  my($self)  = shift;
  my($name)  = shift;
  my($value) = undef;

  if ($name eq 'guid') {
    my($guid) = new GUID();
    $value = $guid->generate($self->project_file_name(),
                             $self->{'current_input'},
                             $self->getcwd());
  }
  elsif ($name eq 'language') {
    $value = $self->get_language();
  }
  else {
    $value = $self->get_configurable($name);
  }
  return $value;
}


sub project_file_extension {
  my($self) = shift;
  return $self->get_info_hash($self->get_language())->{'ext'};
}


sub get_dll_exe_template_input_file {
  my($self) = shift;
  return $self->get_info_hash($self->get_language())->{'dllexe'};
}


sub get_lib_exe_template_input_file {
  my($self) = shift;
  return $self->get_info_hash($self->get_language())->{'libexe'};
}


sub get_dll_template_input_file {
  my($self) = shift;
  return $self->get_info_hash($self->get_language())->{'dll'};
}


sub get_lib_template_input_file {
  my($self) = shift;
  return $self->get_info_hash($self->get_language())->{'lib'};
}


sub get_template {
  my($self) = shift;
  return $self->get_info_hash($self->get_language())->{'template'};
}


1;
