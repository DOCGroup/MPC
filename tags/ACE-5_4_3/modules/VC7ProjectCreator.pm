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
use WinVersionTranslator;
use ProjectCreator;

use vars qw(@ISA);
@ISA = qw(ProjectCreator);

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


sub compare_output {
  #my($self) = shift;
  return 1;
}


sub file_sorter {
  my($self)  = shift;
  my($left)  = shift;
  my($right) = shift;
  return lc($left) cmp lc($right);
}


sub require_dependencies {
  my($self) = shift;

  ## Only write dependencies for non-static projects
  ## and static exe projects, unless the user wants the
  ## dependency combined static library.
  return ($self->get_static() == 0 || $self->exe_target() ||
          $self->dependency_combined_static_library());
}


sub dependency_is_filename {
  #my($self) = shift;
  return 0;
}


sub crlf {
  my($self) = shift;
  return $self->windows_crlf();
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
  elsif ($name eq 'win_version') {
    $value = $self->get_assignment('version');
    if (defined $value) {
      $value = WinVersionTranslator::translate($value);
    }
  }
  else {
    $value = $self->get_configurable($name);
  }
  return $value;
}


sub project_file_name {
  my($self) = shift;
  my($name) = shift;

  if (!defined $name) {
    $name = $self->project_name();
  }

  return $self->get_modified_project_file_name(
                     $name, $info{$self->get_language()}->{'ext'});
}


sub get_dll_exe_template_input_file {
  my($self) = shift;
  return $info{$self->get_language()}->{'dllexe'};
}


sub get_lib_exe_template_input_file {
  my($self) = shift;
  return $info{$self->get_language()}->{'libexe'};
}


sub get_dll_template_input_file {
  my($self) = shift;
  return $info{$self->get_language()}->{'dll'};
}


sub get_lib_template_input_file {
  my($self) = shift;
  return $info{$self->get_language()}->{'lib'};
}


sub get_template {
  my($self) = shift;
  return $info{$self->get_language()}->{'template'};
}


1;
