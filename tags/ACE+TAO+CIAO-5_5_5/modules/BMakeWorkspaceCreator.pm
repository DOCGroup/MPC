package BMakeWorkspaceCreator;

# ************************************************************
# Description   : A Borland Make Workspace (Makefile) creator
# Author        : Chad Elliott
# Create Date   : 2/03/2004
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use BMakeProjectCreator;
use MakeWorkspaceBase;
use WorkspaceCreator;

use vars qw(@ISA);
@ISA = qw(MakeWorkspaceBase WorkspaceCreator);

# ************************************************************
# Data Section
# ************************************************************

my($max_line_length) = 32767; ## Borland Make's maximum line length
my($targets) = 'clean generated realclean $(CUSTOM_TARGETS)';

# ************************************************************
# Subroutine Section
# ************************************************************

sub crlf {
  my($self) = shift;
  return $self->windows_crlf();
}


sub workspace_file_extension {
  #my($self) = shift;
  return '.bmak';
}


sub pre_workspace {
  my($self) = shift;
  my($fh)   = shift;
  $self->workspace_preamble($fh, $self->crlf(),
                            'Borland Workspace Makefile',
                            '$Id$');
}


sub write_project_targets {
  my($self)     = shift;
  my($fh)       = shift;
  my($crlf)     = shift;
  my($target)   = shift;
  my($list)     = shift;
  my($and)      = shift;
  my($cwd)      = $self->getcwd();

  foreach my $project (@$list) {
    my($dir)   = $self->slash_to_backslash($self->mpc_dirname($project));
    my($chdir) = ($dir ne '.');

    print $fh "\t", ($chdir ? "\$(COMSPEC) /c \"cd $dir $and " : ''),
              "\$(MAKE) -\$(MAKEFLAGS) -f ",
              $self->mpc_basename($project), " $target",
              ($chdir ? '"' : ''), $crlf;
  }
}


sub write_comps {
  my($self)     = shift;
  my($fh)       = shift;
  my($creator)  = shift;
  my(%targnum)  = ();
  my($pjs)      = $self->get_project_info();
  my(@list)     = $self->number_target_deps($self->get_projects(), $pjs,
                                            \%targnum, 0);
  my($crlf)     = $self->crlf();

  ## Set up the custom targets
  print $fh '!ifndef CUSTOM_TARGETS', $crlf,
            'CUSTOM_TARGETS=_EMPTY_TARGET_', $crlf,
            '!endif', $crlf;

  my(%trans) = ();
  foreach my $project (@list) {
    $trans{$project} = $$pjs{$project}->[0];
  }

  $self->write_named_targets($fh, $crlf, \%targnum, \@list,
                             $targets, '', '', \%trans, undef,
                             $creator->get_and_symbol(), $max_line_length);
}



1;
