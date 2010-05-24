package CDT6ProjectCreator;

# ************************************************************
# Description   : Eclipse CDT 6 generator
# Author        : Chris Cleeland, Object Computing, Inc.
# Create Date   : 23-Apr-2010
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use ProjectCreator;

use vars qw(@ISA);
@ISA = qw(ProjectCreator);

# ************************************************************
# Data Section
# ************************************************************

my %templates = ('cdt6project'   => '.project',
                 'cdt6cproject'  => '.cproject' );

my @tkeys = sort keys %templates;

# ************************************************************
# Subroutine Section
# ************************************************************

sub crlf {
  #my $self = shift;
  return "\n";
}

sub project_file_name {
  my($self, $name, $template) = @_;

  ## Fill in the name and template if they weren't provided
  $name = $self->project_name() if (!defined $name);
  $template = 'cdt6' if (!defined $template || !defined $templates{$template});

  if ($self->{'make_coexistence'}) {
    return $self->get_modified_project_file_name($name,
                                                 '/' . $templates{$template});
  }
  else {
    return $templates{$template};
  }
}

sub get_template {
  #my $self = shift;
  return @tkeys;
}

sub dependency_is_filename {
  #my $self = shift;
  return 0;
}

sub requires_forward_slashes {
  return 1;
}

sub file_visible {
  ## We only want the project file visible to the workspace creator.
  ## There can only be one and this is it.
  #my($self, $template) = @_;
  return $_[1] eq 'cdt6';
}

sub get_dll_exe_template_input_file {
  #my $self = shift;
  return 'cdt6exe';
}

sub get_dll_template_input_file {
  #my $self = shift;
  return 'cdt6dll';
}

1;
