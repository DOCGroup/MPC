package VC10ProjectCreator;

# ************************************************************
# Description   : A VC10 Project Creator
# Author        : Johnny Willemsen
# Create Date   : 11/10/2008
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use VC9ProjectCreator;

use vars qw(@ISA);
@ISA = qw(VC9ProjectCreator);

my %info = (Creator::cplusplus => {'ext'      => '.vcxproj',
                                   'dllexe'   => 'vc8exe',
                                   'libexe'   => 'vc8libexe',
                                   'dll'      => 'vc8dll',
                                   'lib'      => 'vc8lib',
                                   'template' => [ 'vc10', 'vc10filters' ],
                                  },
           );

my %config = ('vcversion' => '10.00',
              'prversion' => '10.0.30319.1',
              'toolsversion' => '4.0',
              'targetframeworkversion' => '4.0',
              'xmlheader' => 1,
              );

sub get_info_hash {
  my($self, $key) = @_;

  ## If we have the setting in our information map, the use it.
  return $info{$key} if (defined $info{$key});

  ## Otherwise, see if our parent type can take care of it.
  return $self->SUPER::get_info_hash($key);
}

sub get_configurable {
  my($self, $name) = @_;
  return $config{$name};
}

## Because VC10 puts file filters in a different file
## that starts with the project file name, and ends
## with .filters extension. So we need to return two
## templates.
sub get_template {
	my $self = shift;
	my $templates = $self->SUPER::get_template;

	return @$templates;
}

sub file_visible {
  my($self, $template) = @_;
  my $templates = $self->SUPER::get_template;

  return ($template eq $$templates[0]);
}

## If the template is one of the additional templates,
## we need to append the proper extension to the file name.
sub project_file_name {
  my($self, $name, $template) = @_;

  my $project_file_name = $self->SUPER::project_file_name($name, $template);
  if (!$self->file_visible($template)) {
	  $project_file_name .= '.filters';
  }

  return $project_file_name;
}

1;
