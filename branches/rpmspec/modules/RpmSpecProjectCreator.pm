package RpmSpecProjectCreator;

use strict;
use ProjectCreator;

use vars qw(@ISA);
@ISA = qw(ProjectCreator);

sub project_file_extension {
  return '.dummy';
}

sub write_output_file {
  my $self = shift;
  my $tover = $self->get_template_override();
  my @templates = $self->get_template();
  @templates = ($tover) if (defined $tover);

  if (scalar @templates != 1) {
    return 0, 'there should be only one template';
  }

  my $template = $templates[0];
#  print "Template is $template\n"; # 'rpmspec'
  $self->{'current_template'} = $template;

  my $name = $self->transform_file_name($self->project_file_name(undef,
                                                                 $template));
  $self->process_assignment('project_file', $name);
  new TemplateParser($self)->collect_data();

  if (defined $self->{'source_callback'}) {
    my $cb     = $self->{'source_callback'};
    my $pjname = $self->get_assignment('project_name');
    my @list   = $self->get_component_list('source_files');
    if (UNIVERSAL::isa($cb, 'ARRAY')) {
      my @copy = @$cb;
      my $s = shift(@copy);
      &$s(@copy, $name, $pjname, \@list);
    }
    elsif (UNIVERSAL::isa($cb, 'CODE')) {
      &$cb($name, $pjname, \@list);
    }
    else {
      $self->warning("Ignoring callback: $cb.");
    }
  }
  $self->add_file_written($name);
  return 1, '';
}

1;
