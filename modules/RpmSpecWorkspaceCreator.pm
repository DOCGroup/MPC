package RpmSpecWorkspaceCreator;

# ************************************************************
# Description   : An RPM .spec file Workspace Creator
# Author        : Adam Mitz (OCI)
# Create Date   : 11/23/2010
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;
#use Dumpvalue;
use File::Path;

use RpmSpecProjectCreator;
use WorkspaceCreator;

use vars qw(@ISA);
@ISA = qw(WorkspaceCreator);

# ************************************************************
# Data Section
# ************************************************************

my $ext = '.spec'; # extension of files written by this WorkspaceCreator

# ************************************************************
# Subroutine Section
# ************************************************************

sub workspace_file_name {
  my $self = shift;
  return $self->get_modified_workspace_name($self->get_workspace_name(), $ext);
}

# Don't actually write the .spec file for the workspace.  Instead just invoke
# the $func callback so that post_workspace() and other parts of the normal
# workspace processing are called.  We don't want a .spec file for each MPC
# workspace because that is too course-grained.  Instead, post_workspace() will
# create one .spec for each aggregated workspace inside the primary workspace.
# Using the workspace aggregation mechanism this way allows multiple .spec
# files per workspace with MPC deriving their dependencies based on the
# projects they contain.
sub write_and_compare_file {
  my($self, $outdir, $oname, $func, @params) = @_;
  &$func($self, undef, @params);
  return undef;
}

sub rpmname {
  my($self, $mwc, $rpm2mwc, $check_unique) = @_;
  my $outfile = $mwc;
  $outfile =~ s/\.mwc$//i;
  $outfile = $self->get_modified_workspace_name($outfile, $ext, 1);
  my $base = $self->mpc_basename($outfile);
  $base =~ tr/-/_/; # - is special for RPM, we translate it to _
  if ($check_unique && $rpm2mwc->{$base}) {
    die "ERROR: Can't create a duplicate RPM name: $base for mwc file $mwc\n" .
        "\tsee corresponding mwc file $rpm2mwc->{$base}\n";
  }
  $rpm2mwc->{$base} = $mwc;
  return $base;
}

## helper functions for the mini-template language

sub mtl_cond {
  my($vars, $pre, $rep) = @_;
  my @v;
  return (@v = grep {$_} map {$rep->{lc $_}} split(' ', $vars)) ? "$pre@v" : '';
}

sub mtl_apply {
  my($name, $subst, $rep) = @_;
  return join("\n", map {my $x = $subst; $x =~ s!\$_!$_!g; $x}
              split(' ', $rep->{lc $name}));
}

sub mtl_var {
  my($name, $default, $rep) = @_;
  return defined $rep->{lc $name} ? $rep->{lc $name} :
      (defined $default ? $default : ">>ERROR: no value for $name<<");
}

## end helper functions for the mini-template language

sub post_workspace {
  my($self, $fh, $prjc) = @_;

  # for debugging only
#  my $dv = new Dumpvalue();
#  print ">>> ASSIGN:\n";
#  $dv->dumpValue($self->get_assignment_hash());
#  foreach my $key ('aggregated_mpc', 'aggregated_assign', 'mpc_to_output') {
#    print ">>> $key\n";
#    $dv->dumpValue($self->{$key});
#  }

  my $prjext = '\\' . # regexp escape for the dot that begins the extension
      $prjc->project_file_extension();

  my %rpm2mwc;  # rpm name (basename of spec file) => aggregated mwc w/ path
  my %mwc2rpm;  # inverse of the above hash
  my %proj2rpm; # project name (output of mpc) => rpm name that it belongs to
  # first pass to build the hashes above
  foreach my $agg (keys %{$self->{'aggregated_mpc'}}) {
    my $rpm = $mwc2rpm{$agg} = $self->rpmname($agg, \%rpm2mwc, 1);
    foreach my $m (@{$self->{'aggregated_mpc'}->{$agg}}) {
      foreach my $p (@{$self->{'mpc_to_output'}->{$m}}) {
        $proj2rpm{$p} = $rpm;
      }
    }
  }

  my $outdir = $self->get_outdir();

  foreach my $agg (keys %{$self->{'aggregated_mpc'}}) {
    my $name = "$outdir/$agg"; # $agg may contain directory parts
    my $dir  = $self->mpc_dirname($name);
    my $base = $mwc2rpm{$agg};
    my $rpm = $base;
    $rpm =~ s/$ext$//;
    $name = "$dir/$base";
    mkpath($dir, 0, 0777) if ($dir ne '.');

    my %rpm_requires; # keys are RPMs that this RPM depends on
    my @projects;
    foreach my $m (@{$self->{'aggregated_mpc'}->{$agg}}) {
      my $projdir = $self->mpc_dirname($m);
      foreach my $p (@{$self->{'mpc_to_output'}->{$m}}) {
        my $proj = $p;
        $proj =~ s/$prjext$//;
        push @projects, $proj;
        my $deps = $self->get_validated_ordering("$projdir/$p");
        foreach my $d (@$deps) {
          my $rpmdep = $proj2rpm{$d};
          if (defined $rpmdep && $rpmdep ne $base) {
            $rpm_requires{$rpmdep} = 1;
          }
        }
      }
    }

    # The hash %rep has replacement values for the template .spec file text,
    # those values come from a few different sources, starting with the
    # workspace-wide assignments, then let RPM-specific ones (from aggregated
    # workspaces) override those, finally add the ones known by MPC.
    # process_special() handles quotes and escape characters.

    my %rep = %{$self->get_assignment_hash()};

    # Allow the description to span multiple lines in the output file
    $rep{'rpm_description'} =~ s/\\n\s*/\n/g if exists $rep{'rpm_description'};

    map {$_ = $self->process_special($_)} values %rep;

    while (my($key, $val) = each %{$self->{'aggregated_assign'}->{$agg}}) {
      $val =~ s/\\n\s*/\n/g if $key eq 'rpm_description';
      $rep{$key} = $self->process_special($val);
    }
    $rep{'rpm_name'} = $rpm;
    $rep{'rpm_mpc_workspace'} = $agg;
    $rep{'rpm_mpc_requires'} =
        join(' ', sort map {s/$ext$//; $_} keys %rpm_requires);

    open OUT, ">$name" or die "can't open $name";
    my $t = get_template();

    ## We have decided not to reuse the TemplateParser.pm, so this file has
    ## its own little template language which is a subset of that one.

    ## <%cond(var1 [var2...], prefix)%>
    ##   Output the prefix text followed by the concatenated, space separated,
    ##   values of the variables (var1, var2, etc) only if at least one of
    ##   said values is non-empty.
    $t =~ s/<%cond\(([\w ]+), (.+)\)%>/mtl_cond($1, $2, \%rep)/ge;

    ## <%perl(expr)%>
    ##   Evaluate an arbitrary perl expression, which can reference the normal
    ##   variable replacements (see <%var%>, below) as $rep{'name'}.
    $t =~ s/<%perl\((.+)\)%>/join "\n", eval $1/ge;

    ## <%apply(listvar, text)%>
    ##   Treat the value of variable 'listvar' as a list (splitting on spaces)
    ##   and repeat the text for each element of the list, substituting $_ in
    ##   the text with the current list element.
    $t =~ s/<%apply\((\w+), (.+)\)%>/mtl_apply($1, $2, \%rep)/ge;

    ## <%var(default)%> or <%var%>
    ##   Output the value of variable 'var', either with a default value or an
    ##   error if 'var' is unknown.  If 'default' is enclosed in double-quotes,
    ##   they are ignored (for compatibility with TemplateParser).
    $t =~ s/<%(\w+)(?:\("?([^)"]*)"?\))?%>/mtl_var($1, $2, \%rep)/ge;

    print OUT $t;
    close OUT;
  }
}


sub get_template {
  return <<'EOT';
License: <%rpm_license("Freeware")%>
Version: <%rpm_version%>
Release: <%rpm_releasenumber%>
Source: <%rpm_source_base("")%><%rpm_name%>.tar.gz
Name: <%rpm_name%>
Group: <%rpm_group%>
Summary: <%rpm_summary%>
BuildRoot: %{_tmppath}/%{name}-%{version}-root
Prefix: <%rpm_prefix("/")%>
AutoReqProv: <%rpm_autorequiresprovides("no")%>
<%cond(rpm_buildrequires, BuildRequires: )%>
<%cond(rpm_mpc_requires rpm_requires, Requires: )%>
<%cond(rpm_provides, Provides: )%>

%description
<%rpm_description%>

%files -f %{_tmppath}/<%rpm_name%>.flist
%defattr(-,root,root)
%doc
%config

%post

%postun

%prep
%setup -n <%rpm_name%>-<%rpm_version%>

%build
<%apply(env_check, [ -z $$_ ] && echo Environment variable $_ is required. && exit 1)%>
rm -rf $RPM_BUILD_ROOT
<%prebuild()%>
<%makefile_generator(mwc.pl -type gnuace)%> -base install <%rpm_mpc_workspace%>
make <%makeflags()%>

%install
if [ "$RPM_BUILD_ROOT" = "/" ]; then
  echo "Build root of / is a bad idea.  Bailing."
  exit 1
fi
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/install
export install_dir=$RPM_BUILD_ROOT/install
export pkg_dir=$RPM_BUILD_ROOT/<%rpm_name%>_dir
mkdir -p $RPM_BUILD_ROOT/<%rpm_name%>_dir
make INSTALL_PREFIX=${install_dir} install
mkdir -p ${install_dir}/usr/share/man
files=$(find ${install_dir}/usr/share/man -name '*.bz2')
if [[ "${files}" ]]; then echo "${files}"| xargs bunzip2 -q; fi
files=$(find ${install_dir}/usr/share/man -name '*.[0-9]')
if [[ "${files}" ]]; then echo "${files}"| xargs gzip -9; fi
cp -ra ${install_dir}/* ${pkg_dir}
find $RPM_BUILD_ROOT/<%rpm_name%>_dir ! -type d | sed s^$RPM_BUILD_ROOT/<%rpm_name%>_dir^^ | sed /^\s*$/d > %{_tmppath}/<%rpm_name%>.flist
find $RPM_BUILD_ROOT/<%rpm_name%>_dir -type d | sed s^$RPM_BUILD_ROOT/<%rpm_name%>_dir^^ | sed '\&^/usr$&d;\&^/usr/share/man&d;\&^/usr/games$&d;\&^/lib$&d;\&^/etc$&d;\&^/boot$&d;\&^/usr/bin$&d;\&^/usr/lib$&d;\&^/usr/share$&d;\&^/var$&d;\&^/var/lib$&d;\&^/var/spool$&d;\&^/var/cache$&d;\&^/var/lock$&d;\&^/tmp/apkg&d' | sed /^\s*$/d | sed 's&^&%dir &' >> %{_tmppath}/<%rpm_name%>.flist
cp -ra $RPM_BUILD_ROOT/*_dir/* $RPM_BUILD_ROOT
rm -rf $RPM_BUILD_ROOT/*_dir
rm -rf $RPM_BUILD_ROOT/install

%clean
make realclean
find . -name '<%makefile_name_pattern(GNUmakefile*)%>' -o -name '.depend.*' | xargs rm -f

%changelog
EOT
}

1;
