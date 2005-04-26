package ProjectCreator;

# ************************************************************
# Description   : Base class for all project creators
# Author        : Chad Elliott
# Create Date   : 3/13/2002
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;
use FileHandle;
use File::Path;
use File::Compare;
use File::Basename;

use Creator;
use TemplateInputReader;
use TemplateParser;
use FeatureParser;

use vars qw(@ISA);
@ISA = qw(Creator);

# ************************************************************
# Data Section
# ************************************************************

my($BaseClassExtension)      = 'mpb';
my($ProjectCreatorExtension) = 'mpc';
my($TemplateExtension)       = 'mpd';
my($TemplateInputExtension)  = 'mpt';

## Valid names for assignments within a project
## Bit Meaning
## 0   Preserve the order for additions (1) or invert it (0)
## 1   Add this value to template input value (if there is one)
my(%validNames) = ('exename'         => 1,
                   'sharedname'      => 1,
                   'staticname'      => 1,
                   'libpaths'        => 3,
                   'install'         => 1,
                   'includes'        => 3,
                   'after'           => 1,
                   'custom_only'     => 1,
                   'libs'            => 2,
                   'lit_libs'        => 2,
                   'pure_libs'       => 2,
                   'pch_header'      => 1,
                   'pch_source'      => 1,
                   'postbuild'       => 1,
                   'dllout'          => 1,
                   'libout'          => 1,
                   'dynamicflags'    => 3,
                   'staticflags'     => 3,
                   'version'         => 1,
                   'recurse'         => 1,
                   'requires'        => 3,
                   'avoids'          => 3,
                   'tagname'         => 1,
                   'tagchecks'       => 1,
                   'macros'          => 3,
                  );

## Custom definitions only
## Bit  Meaning
## 0    Value is always an array
## 1    Value is an array and name gets 'outputext' converted to 'files'
## 2    Value is always scalar
## 3    Name can also be used in an 'optional' clause
## 4    Needs <%...%> conversion
my(%customDefined) = ('automatic'                   => 0x04,
                      'dependent'                   => 0x14,
                      'command'                     => 0x14,
                      'commandflags'                => 0x14,
                      'precommand'                  => 0x14,
                      'postcommand'                 => 0x14,
                      'inputext'                    => 0x01,
                      'libpath'                     => 0x04,
                      'output_option'               => 0x14,
                      'pch_postrule'                => 0x04,
                      'pre_extension'               => 0x08,
                      'source_pre_extension'        => 0x08,
                      'template_pre_extension'      => 0x08,
                      'header_pre_extension'        => 0x08,
                      'inline_pre_extension'        => 0x08,
                      'documentation_pre_extension' => 0x08,
                      'resource_pre_extension'      => 0x08,
                      'pre_filename'                => 0x08,
                      'source_pre_filename'         => 0x08,
                      'template_pre_filename'       => 0x08,
                      'header_pre_filename'         => 0x08,
                      'inline_pre_filename'         => 0x08,
                      'documentation_pre_filename'  => 0x08,
                      'resource_pre_filename'       => 0x08,
                      'source_outputext'            => 0x0a,
                      'template_outputext'          => 0x0a,
                      'header_outputext'            => 0x0a,
                      'inline_outputext'            => 0x0a,
                      'documentation_outputext'     => 0x0a,
                      'resource_outputext'          => 0x0a,
                      'generic_outputext'           => 0x0a,
                     );

## Custom sections as well as definitions
## Value  Meaning
## 0    No modifications
## 1    Needs <%...%> conversion
my(%custom) = ('command'       => 1,
               'commandflags'  => 1,
               'dependent'     => 1,
               'gendir'        => 0,
               'precommand'    => 1,
               'postcommand'   => 1,
              );

## All matching assignment arrays will get these keywords
my(@default_matching_assignments) = ('recurse',
                                    );

## Deal with these components in a special way
my(%specialComponents) = ('header_files'   => 1,
                          'inline_files'   => 1,
                          'template_files' => 1,
                         );
my(%sourceComponents)  = ('source_files'   => 1,
                          'template_files' => 1,
                         );

my($grouped_key) = 'grouped_';

## Matches with generic_outputext
my($generic_key) = 'generic_files';

# ************************************************************
# C++ Specific Component Settings
# ************************************************************

## Valid component names within a project along with the valid file extensions
my(%cppvc) = ('source_files'        => [ "\\.cpp", "\\.cxx", "\\.cc", "\\.c", "\\.C", ],
              'template_files'      => [ "_T\\.cpp", "_T\\.cxx", "_T\\.cc", "_T\\.c", "_T\\.C", ],
              'header_files'        => [ "\\.h", "\\.hpp", "\\.hxx", "\\.hh", ],
              'inline_files'        => [ "\\.i", "\\.inl", ],
              'documentation_files' => [ "README", "readme", "\\.doc", "\\.txt", "\\.html" ],
              'resource_files'      => [ "\\.rc", ],
             );

## Exclude these extensions when auto generating the component values
my(%cppec) = ('source_files' => $cppvc{'template_files'},
             );

# ************************************************************
# C# Specific Component Settings
# ************************************************************

## Valid component names within a project along with the valid file extensions
my(%csvc) = ('source_files'        => [ "\\.cs" ],
             'config_files'        => [ "\\.config" ],
             'resx_files'          => [ "\\.resx" ],
             'ico_files'           => [ "\\.ico" ],
             'documentation_files' => [ "README", "readme", "\\.doc", "\\.txt", "\\.html" ],
            );

my(%csma) = ('source_files' => [ 'subtype' ],
            );

# ************************************************************
# Java Specific Component Settings
# ************************************************************

## Valid component names within a project along with the valid file extensions
my(%jvc) = ('source_files'        => [ "\\.java" ],
            'documentation_files' => [ "README", "readme", "\\.doc", "\\.txt", "\\.html" ],
           );

# ************************************************************
# Visual Basic Specific Component Settings
# ************************************************************

## Valid component names within a project along with the valid file extensions
my(%vbvc) = ('source_files'        => [ "\\.vb" ],
             'config_files'        => [ "\\.config" ],
             'resx_files'          => [ "\\.resx" ],
             'ico_files'           => [ "\\.ico" ],
             'documentation_files' => [ "README", "readme", "\\.doc", "\\.txt", "\\.html" ],
            );

my(%vbma) = ('source_files' => [ 'subtype' ],
            );

# ************************************************************
# Language Specific Component Settings
# ************************************************************

# Index Description
# ----- -----------
# 0     File types
# 1     Files automatically excluded from source_files
# 2     Assignments available in standard file types
# 3     The entry point for executables
# 4     The language uses a preprocessor
my(%language) = ('cplusplus' => [ \%cppvc, \%cppec, {}    , 'main', 1 ],
                 'csharp'    => [ \%csvc,  {},      \%csma, 'Main', 0 ],
                 'java'      => [ \%jvc,   {},      {}    , 'Main', 0 ],
                 'vb'        => [ \%vbvc,  {},      \%vbma, 'Main', 0 ],
                );

# ************************************************************
# Subroutine Section
# ************************************************************

sub new {
  my($class)      = shift;
  my($global)     = shift;
  my($inc)        = shift;
  my($template)   = shift;
  my($ti)         = shift;
  my($dynamic)    = shift;
  my($static)     = shift;
  my($relative)   = shift;
  my($addtemp)    = shift;
  my($addproj)    = shift;
  my($progress)   = shift;
  my($toplevel)   = shift;
  my($baseprojs)  = shift;
  my($gfeature)   = shift;
  my($feature)    = shift;
  my($features)   = shift;
  my($hierarchy)  = shift;
  my($exclude)    = shift;
  my($makeco)     = shift;
  my($nmod)       = shift;
  my($applypj)    = shift;
  my($genins)     = shift;
  my($into)       = shift;
  my($language)   = shift;
  my($use_env)    = shift;
  my($expandvars) = shift;
  my($self)       = $class->SUPER::new($global, $inc,
                                       $template, $ti, $dynamic, $static,
                                       $relative, $addtemp, $addproj,
                                       $progress, $toplevel, $baseprojs,
                                       $feature, $features,
                                       $hierarchy, $nmod, $applypj,
                                       $into, $language, $use_env,
                                       $expandvars,
                                       'project');

  $self->{$self->{'type_check'}}   = 0;
  $self->{'feature_defined'}       = 0;
  $self->{'project_info'}          = [];
  $self->{'lib_locations'}         = {};
  $self->{'reading_parent'}        = [];
  $self->{'dexe_template_input'}   = undef;
  $self->{'lexe_template_input'}   = undef;
  $self->{'lib_template_input'}    = undef;
  $self->{'dll_template_input'}    = undef;
  $self->{'flag_overrides'}        = {};
  $self->{'custom_special_output'} = {};
  $self->{'special_supplied'}      = {};
  $self->{'pctype'}                = $self->extractType("$self");
  $self->{'verbatim'}              = {};
  $self->{'verbatim_accessed'}     = {$self->{'pctype'} => {}};
  $self->{'defaulted'}             = {};
  $self->{'custom_types'}          = {};
  $self->{'parents_read'}          = {};
  $self->{'inheritance_tree'}      = {};
  $self->{'remove_files'}          = {};
  $self->{'feature_parser'}        = new FeatureParser($gfeature, $feature,
                                                       $features);
  $self->{'convert_slashes'}       = $self->convert_slashes();
  $self->{'sort_files'}            = $self->sort_files();
  $self->{'source_callback'}       = undef;
  $self->{'dollar_special'}        = $self->dollar_special();
  $self->{'generate_ins'}          = $genins;
  $self->{'addtemp_state'}         = undef;
  $self->{'command_subs'}          = $self->get_command_subs();
  $self->{'escape_spaces'}         = $self->escape_spaces();

  $self->add_default_matching_assignments();
  $self->reset_generating_types();

  return $self;
}


sub read_global_configuration {
  my($self)   = shift;
  my($input)  = $self->get_global_cfg();
  my($status) = 1;

  if (defined $input) {
    ## If it doesn't contain a path, search the include path
    if ($input !~ /[\/\\]/) {
      $input = $self->search_include_path($input);
      if (!defined $input) {
        $input = $self->get_global_cfg();
      }
    }

    ## Read and parse the global project file
    $self->{'reading_global'} = 1;
    $status = $self->parse_file($input);
    $self->{'reading_global'} = 0;
  }

  return $status;
}


sub process_assignment {
  my($self)   = shift;
  my($name)   = shift;
  my($value)  = shift;
  my($assign) = shift;

  ## Support the '*' mechanism as in the project name, to allow
  ## the user to correctly depend on another project within the same
  ## directory.
  if ($name eq 'after' && $value =~ /\*/) {
    $value = $self->fill_type_name($value,
                                   $self->get_default_project_name());
  }
  if (defined $value && !$self->{'dollar_special'} && $value =~ /\$\$/) {
    $value =~ s/\$\$/\$/g;
  }
  $self->SUPER::process_assignment($name, $value, $assign);

  ## Support keyword mapping here only at the project level scope. The
  ## scoped keyword mapping is done through the parse_scoped_assignment()
  ## method.
  if (!defined $assign) {
    my($mapped) = $self->{'valid_names'}->{$name};
    if (defined $mapped && UNIVERSAL::isa($mapped, 'ARRAY')) {
      $self->parse_scoped_assignment($$mapped[0], 'assignment',
                                     $$mapped[1], $value,
                                     $self->{'generated_exts'}->{$$mapped[0]});
    }
  }
}


sub get_assignment_for_modification {
  my($self)        = shift;
  my($name)        = shift;
  my($assign)      = shift;
  my($subtraction) = shift;

  ## If we weren't passed an assignment hash, then we need to
  ## look one up that may possibly correctly deal with keyword mappings
  if (!defined $assign) {
    my($mapped) = $self->{'valid_names'}->{$name};

    if (defined $mapped && UNIVERSAL::isa($mapped, 'ARRAY')) {
      $name   = $$mapped[1];
      $assign = $self->{'generated_exts'}->{$$mapped[0]};
    }
  }

  ## Get the assignment value
  my($value) = $self->get_assignment($name, $assign);

  ## If we are involved in a subtraction, we get back a value and
  ## it's a scoped or mapped assignment, then we need to possibly
  ## expand any template variables.  Otherwise, the subtractions
  ## may not work correctly.
  if ($subtraction && defined $value && defined $assign) {
    $value = $self->relative($value, 1);
  }

  return $value;
}


sub begin_project {
  my($self)    = shift;
  my($parents) = shift;
  my($status)  = 1;
  my($error)   = undef;

  ## Deal with the inheritance hierarchy first
  ## Add in the base projects from the command line
  if (!$self->{'reading_global'} &&
      !defined $self->{'reading_parent'}->[0]) {
    my($baseprojs) = $self->get_baseprojs();

    if (defined $parents) {
      foreach my $base (@$baseprojs) {
        my($found) = 0;
        foreach my $parent (@$parents) {
          if ($base eq $parent) {
            $found = 1;
            last;
          }
        }
        if (!$found) {
          push(@$parents, $base);
        }
      }
    }
    else {
      $parents = $baseprojs;
    }
  }

  if (defined $parents) {
    foreach my $parent (@$parents) {
      ## Read in the parent onto ourself
      my($file) = $self->search_include_path(
                           "$parent.$BaseClassExtension");
      if (!defined $file) {
        $file = $self->search_include_path(
                             "$parent.$ProjectCreatorExtension");
      }

      if (defined $file) {
        if (defined $self->{'reading_parent'}->[0]) {
          foreach my $currently (@{$self->{'reading_parent'}}) {
            if ($currently eq $file) {
              $status = 0;
              $error = 'Cyclic inheritance detected: ' .
                       $parent;
            }
          }
        }

        if ($status) {
          if (!defined $self->{'parents_read'}->{$file}) {
            $self->{'parents_read'}->{$file} = 1;

            ## Push the base project file onto the parent stack
            push(@{$self->{'reading_parent'}}, $file);

            ## Collect up some information about the inheritance tree
            my($tree) = $self->{'current_input'};
            if (!defined $self->{'inheritance_tree'}->{$tree}) {
              $self->{'inheritance_tree'}->{$tree} = {};
            }
            my($hash) = $self->{'inheritance_tree'}->{$tree};
            foreach my $p (@{$self->{'reading_parent'}}) {
              if (!defined $$hash{$p}) {
                $$hash{$p} = {};
              }
              $hash = $$hash{$p};
            }

            ## Begin reading the parent
            $status = $self->parse_file($file);

            ## Take the base project file off of the parent stack
            pop(@{$self->{'reading_parent'}});

            if (!$status) {
              $error = "Invalid parent: $parent";
            }
          }
          else {
            ## The base project has already been read.  So, if
            ## we are reading the original project (not a parent base
            ## project), then the current base project is redundant.
            if (!defined $self->{'reading_parent'}->[0]) {
              $file =~ s/\.[^\.]+$//;
              $self->information('Inheriting from \'' . basename($file) .
                                 '\' in ' . $self->{'current_input'} .
                                 ' is redundant at line ' .
                                 $self->get_line_number() . '.');
            }
          }
        }
      }
      else {
        $status = 0;
        $error = "Unable to locate parent: $parent";
      }
    }
  }

  ## Copy each value from global_assign into assign
  if (!$self->{'reading_global'}) {
    foreach my $key (keys %{$self->{'global_assign'}}) {
      if (!defined $self->{'assign'}->{$key}) {
        $self->{'assign'}->{$key} = $self->{'global_assign'}->{$key};
      }
    }
  }

  return $status, $error;
}


sub parse_line {
  my($self)   = shift;
  my($ih)     = shift;
  my($line)   = shift;
  my($status,
     $errorString,
     @values) = $self->parse_known($line);

  ## parse_known() passes back an array of values
  ## that make up the contents of the line parsed.
  ## The array can have 0 to 3 items.  The first,
  ## if defined, is always an identifier of some
  ## sort.

  if ($status && defined $values[0]) {
    if ($values[0] eq $self->{'grammar_type'}) {
      my($name)      = $values[1];
      my($typecheck) = $self->{'type_check'};
      if (defined $name && $name eq '}') {
        ## Project Ending
        my($rp) = $self->{'reading_parent'};
        if (!defined $$rp[0] && !$self->{'reading_global'}) {
          ## Fill in all the default values
          $self->generate_defaults();

          ## Perform any additions, subtractions
          ## or overrides for the project values.
          my($addproj) = $self->get_addproj();
          foreach my $ap (keys %$addproj) {
            if (defined $self->{'valid_names'}->{$ap}) {
              my($val) = $$addproj{$ap};
              if ($$val[0] > 0) {
                $self->process_assignment_add($ap, $$val[1]);
              }
              elsif ($$val[0] < 0) {
                $self->process_assignment_sub($ap, $$val[1]);
              }
              else {
                $self->process_assignment($ap, $$val[1]);
              }
            }
            else {
              $errorString = 'Invalid ' .
                             "assignment modification name: $ap";
              $status = 0;
            }
          }

          if ($status) {
            ## End of project; Write out the file.
            ($status, $errorString) = $self->write_project();

            ## write_project() can return 0 for error, 1 for project
            ## was written and 2 for project was skipped
            if ($status == 1) {
              ## Save the library name and location
              foreach my $name ('sharedname', 'staticname') {
                my($val) = $self->get_assignment($name);
                if (defined $val) {
                  my($cwd)   = $self->getcwd();
                  my($start) = $self->getstartdir();
                  my($amount) = 0;
                  if ($cwd eq $start) {
                    $amount = length($start);
                  }
                  elsif (index($cwd, $start) == 0) {
                    $amount = length($start) + 1;
                  }
                  $self->{'lib_locations'}->{$val} =
                      substr($cwd, $amount);
                  last;
                }
              }

              ## Check for unused verbatim markers
              foreach my $key (keys %{$self->{'verbatim'}}) {
                if (defined $self->{'verbatim_accessed'}->{$key}) {
                  foreach my $ikey (keys %{$self->{'verbatim'}->{$key}}) {
                    if (!defined $self->{'verbatim_accessed'}->{$key}->{$ikey}) {
                      $self->warning("Marker $ikey does not exist.");
                    }
                  }
                }
              }
            }

            ## Reset all of the project specific data
            foreach my $key (keys %{$self->{'valid_components'}}) {
              delete $self->{$key};
              $self->{'defaulted'}->{$key} = 0;
            }
            if (defined $self->{'addtemp_state'}) {
              $self->restore_state($self->{'addtemp_state'}, 'addtemp');
              $self->{'addtemp_state'} = undef;
            }
            $self->{'assign'}                = {};
            $self->{'verbatim'}              = {};
            $self->{'verbatim_accessed'}     = {$self->{'pctype'} => {}};
            $self->{'special_supplied'}      = {};
            $self->{'flag_overrides'}        = {};
            $self->{'parents_read'}          = {};
            $self->{'inheritance_tree'}      = {};
            $self->{'remove_files'}          = {};
            $self->{'custom_special_output'} = {};
            $self->reset_generating_types();
          }
        }
        $self->{$typecheck} = 0;
      }
      else {
        ## Project Beginning
        ($status, $errorString) = $self->begin_project($values[2]);

        ## Set up the default project name
        if ($status) {
          if (defined $name) {
            if ($name =~ /[\/\\]/) {
              $status = 0;
              $errorString = 'Projects can not have a slash ' .
                             'or a back slash in the name';
            }
            else {
              ## We should only set the project name if we are not
              ## reading in a parent project.
              if (!defined $self->{'reading_parent'}->[0]) {
                $name =~ s/^\(\s*//;
                $name =~ s/\s*\)$//;
                $name = $self->transform_file_name($name);

                ## Replace any *'s with the default name
                $name = $self->fill_type_name(
                                    $name,
                                    $self->get_default_project_name());

                $self->set_project_name($name);
              }
              else {
                $self->warning("Ignoring project name in a base project.");
              }
            }
          }
        }

        if ($status) {
          ## Signify that we have a valid project
          $self->{$typecheck} = 1;
        }
      }
    }
    elsif ($values[0] eq 'assignment') {
      my($name)  = $values[1];
      my($value) = $values[2];
      if (defined $self->{'valid_names'}->{$name}) {
        $self->process_assignment($name, $value);
      }
      else {
        $errorString = "Invalid assignment name: $name";
        $status = 0;
      }
    }
    elsif ($values[0] eq 'assign_add') {
      my($name)  = $values[1];
      my($value) = $values[2];
      if (defined $self->{'valid_names'}->{$name}) {
        $self->process_assignment_add($name, $value);
      }
      else {
        $errorString = "Invalid addition name: $name";
        $status = 0;
      }
    }
    elsif ($values[0] eq 'assign_sub') {
      my($name)  = $values[1];
      my($value) = $values[2];
      if (defined $self->{'valid_names'}->{$name}) {
        $self->process_assignment_sub($name, $value);
      }
      else {
        $errorString = "Invalid subtraction name: $name";
        $status = 0;
      }
    }
    elsif ($values[0] eq 'component') {
      my($comp) = $values[1];
      my($name) = $values[2];
      if (defined $name) {
        $name =~ s/^\(\s*//;
        $name =~ s/\s*\)$//;
      }
      else {
        $name = $self->get_default_component_name();
      }

      my($vc) = $self->{'valid_components'};
      if (defined $$vc{$comp}) {
        if (!$self->parse_components($ih, $comp, $name)) {
          $errorString = "Unable to process $comp";
          $status = 0;
        }
      }
      else {
        if ($comp eq 'verbatim') {
          my($type, $loc) = split(/\s*,\s*/, $name);
          ($status, $errorString) = $self->parse_verbatim($ih, $type, $loc);
        }
        elsif ($comp eq 'specific') {
          my($scope_parsed) = 0;
          my($defcomp) = $self->get_default_component_name();
          foreach my $type (split(/\s*,\s*/, $name)) {
            if ($type eq $self->{'pctype'} || $type eq $defcomp) {
              ($status, $errorString) = $self->parse_scope(
                                          $ih, $values[1], $type,
                                          $self->{'valid_names'},
                                          $self->get_assignment_hash(),
                                          {});
              $scope_parsed = 1;
              last;
            }
          }
          if (!$scope_parsed) {
            ## We still need to parse the scope, but we will be
            ## throwing away whatever is processed.  However, it
            ## could still be invalid code that will cause an error.
            ($status, $errorString) = $self->parse_scope(
                                        $ih, $values[1], undef,
                                        $self->{'valid_names'},
                                        undef,
                                        $self->get_assignment_hash());
          }
        }
        elsif ($comp eq 'define_custom') {
          ($status, $errorString) = $self->parse_define_custom($ih, $name);
        }
        else {
          $errorString = "Invalid component name: $comp";
          $status = 0;
        }
      }
    }
    elsif ($values[0] eq 'feature') {
      $self->{'feature_defined'} = 1;
      $self->process_feature($ih, $values[1], $values[2]);
      if ($self->{'feature_defined'}) {
        $errorString = "Did not find the end of the feature";
        $status = 0;
      }
    }
    else {
      $errorString = "Unrecognized line: $line";
      $status = 0;
    }
  }
  elsif ($status == -1) {
    $status = 0;
  }

  return $status, $errorString;
}


sub parse_scoped_assignment {
  my($self)   = shift;
  my($tag)    = shift;
  my($type)   = shift;
  my($name)   = shift;
  my($value)  = shift;
  my($flags)  = shift;
  my($over)   = {};
  my($status) = 0;

  ## Map the assignment name on a scoped assignment
  my($mapped) = $self->{'valid_names'}->{$name};
  if (defined $mapped && UNIVERSAL::isa($mapped, 'ARRAY')) {
    $name = $$mapped[1];
  }

  if (defined $self->{'matching_assignments'}->{$tag}) {
    foreach my $possible (@{$self->{'matching_assignments'}->{$tag}}) {
      if ($possible eq $name) {
        $status = 1;
        last;
      }
    }
  }

  if ($status) {
    if (defined $self->{'flag_overrides'}->{$tag}) {
      $over = $self->{'flag_overrides'}->{$tag};
    }
    else {
      $self->{'flag_overrides'}->{$tag} = $over;
    }

    if ($type eq 'assignment') {
      $self->process_assignment($name, $value, $flags);
    }
    elsif ($type eq 'assign_add') {
      ## If there is no value in $$flags, then we need to get
      ## the outer scope value and put it in there.
      if (!defined $self->get_assignment($name, $flags)) {
        my($outer) = $self->get_assignment($name);
        $self->process_assignment($name, $outer, $flags);
      }
      $self->process_assignment_add($name, $value, $flags);
    }
    elsif ($type eq 'assign_sub') {
      ## If there is no value in $$flags, then we need to get
      ## the outer scope value and put it in there.
      if (!defined $self->get_assignment($name, $flags)) {
        my($outer) = $self->get_assignment($name);
        $self->process_assignment($name, $outer, $flags);
      }
      $self->process_assignment_sub($name, $value, $flags);
    }
  }
  return $status;
}


sub handle_unknown_assignment {
  my($self)   = shift;
  my($type)   = shift;
  my(@values) = @_;

  ## Unknown assignments within a 'specific' section are handled as
  ## template value modifications.  These are handled exactly as the
  ## -value_template option in Options.pm.

  ## If $type is not defined, then we are skipping this section
  if (defined $type) {
    ## Save the addtemp state if we haven't done so before
    if (!defined $self->{'addtemp_state'}) {
      my(%state) = $self->save_state('addtemp');
      $self->{'addtemp_state'} = \%state;
    }

    ## Now modify the addtemp values
    $self->information("'$values[1]' was used as a template modifier.");
    if ($values[0] eq 'assign_add') {
      $values[0] = 1;
    }
    elsif ($values[0] eq 'assign_sub') {
      $values[0] = -1;
    }
    else {
      $values[0] = 0;
    }

    if (!defined $self->get_addtemp()->{$values[1]}) {
      $self->get_addtemp()->{$values[1]} = [];
    }
    push(@{$self->get_addtemp()->{$values[1]}}, [$values[0], $values[2]]);
  }

  return 1, undef;
}


sub process_component_line {
  my($self)    = shift;
  my($tag)     = shift;
  my($line)    = shift;
  my($flags)   = shift;
  my($grname)  = shift;
  my($current) = shift;
  my($excarr)  = shift;
  my($comps)   = shift;
  my($count)   = shift;
  my($status)  = 1;
  my(%exclude) = ();

  my(@values) = ();
  ## If this returns true, then we've found an assignment
  if ($self->parse_assignment($line, \@values)) {
    $status = $self->parse_scoped_assignment($tag, @values, $flags);
  }
  else {
    ## If we successfully remove a '!' from the front, then
    ## the file(s) listed are to be excluded
    my($rem) = ($line =~ s/^\^//);
    my($exc) = $rem || ($line =~ s/^!//);

    ## Convert any $(...) in this line before we process any
    ## wild card characters.  If we do not, scoped assignments will
    ## not work nor will we get the correct wild carded file list.
    ## We also need to make sure that any back slashes are converted to
    ## slashes to ensure that later flag_overrides checks will happen
    ## correctly.
    $line = $self->relative($line);
    if ($self->{'convert_slashes'}) {
      $line =~ s/\\/\//g;
    }

    ## Now look for specially listed files
    if ($line =~ /(.*)\s+>>\s+(.*)/) {
      $line = $1;
      $self->{'custom_special_output'}->{$line} = $self->create_array($2);
    }

    ## Set up the files array.  If the line contains a wild card
    ## character use CORE::glob() to get the files specified.
    my(@files) = ();
    if ($line =~ /^"([^"]+)"$/) {
      push(@files, $1);
    }
    elsif ($line =~ /[\?\*\[\]]/) {
      @files = glob($line);
    }
    else {
      push(@files, $line);
    }

    ## If we want to remove these files at the end too, then
    ## add them to our remove_files hash array.
    if ($rem) {
      if (!defined $self->{'remove_files'}->{$tag}) {
        $self->{'remove_files'}->{$tag} = {};
      }
      foreach my $file (@files) {
        $self->{'remove_files'}->{$tag}->{$file} = 1;
      }
    }

    ## If we're excluding these files, then put them in the hash
    if ($exc) {
      $$grname = $current;
      @exclude{@files} = (@files);
      @$excarr = @files;
    }
    else {
      ## Set the flag overrides for each file
      my($over) = $self->{'flag_overrides'}->{$tag};
      if (defined $over) {
        foreach my $file (@files) {
          $$over{$file} = $flags;
        }
      }

      foreach my $file (@files) {
        ## Add the file if we're not excluding it
        if (!defined $exclude{$file}) {
          push(@{$$comps{$current}}, $file);
        }

        ## The user listed a file explicitly, whether we
        ## excluded it or not.
        ++$$count;
      }
    }
  }

  return $status;
}


sub parse_conditional {
  my($self)    = shift;
  my($fh)      = shift;
  my($types)   = shift;
  my($tag)     = shift;
  my($flags)   = shift;
  my($grname)  = shift;
  my($current) = shift;
  my($exclude) = shift;
  my($comps)   = shift;
  my($count)   = shift;
  my($status)  = 1;
  my($add)     = 0;

  foreach my $type (split(/\s*,\s*/, $types)) {
    if ($type eq $self->{'pctype'}) {
      $add = 1;
      last;
    }
  }

  while(<$fh>) {
    my($line) = $self->preprocess_line($fh, $_);

    if ($line eq '') {
    }
    elsif ($line =~ /^}\s*else\s*{$/) {
      $add ^= 1;
    }
    elsif ($line =~ /^}$/) {
      last;
    }
    elsif ($add) {
      $status = $self->process_component_line($tag, $line, $flags,
                                              $grname, $current,
                                              $exclude, $comps, $count);
      if (!$status) {
        last;
      }
    }
  }

  return $status;
}

sub parse_components {
  my($self)    = shift;
  my($fh)      = shift;
  my($tag)     = shift;
  my($name)    = shift;
  my($defel)   = $self->get_default_element_name();
  my($current) = $defel;
  my($status)  = 1;
  my($names)   = {};
  my($comps)   = {};
  my($set)     = undef;
  my(%flags)   = ();
  my(@exclude) = ();
  my($custom)  = defined $self->{'generated_exts'}->{$tag};
  my($grtag)   = $grouped_key . $tag;
  my($grname)  = undef;

  if ($custom) {
    ## For the custom scoped assignments, we want to put a copy of
    ## the original custom defined values in our flags associative array.
    foreach my $key (keys %custom) {
      if (defined $self->{'generated_exts'}->{$tag}->{$key}) {
        $flags{$key} = $self->{'generated_exts'}->{$tag}->{$key};
      }
    }
  }

  if (defined $self->{$tag}) {
    $names = $self->{$tag};
  }
  else {
    $self->{$tag} = $names;
  }
  if (defined $$names{$name}) {
    $comps = $$names{$name};
  }
  else {
    $$names{$name} = $comps;
  }
  if (!defined $$comps{$current}) {
    $$comps{$current} = [];
  }

  my($count) = 0;
  if (defined $specialComponents{$tag}) {
    $self->{'special_supplied'}->{$tag} = 1;
  }

  while(<$fh>) {
    my($line) = $self->preprocess_line($fh, $_);

    if ($line eq '') {
    }
    elsif ($line =~ /^(\w+)\s*{$/) {
      if (!defined $current || !$set) {
        $current = $1;
        $set = 1;
        if (!defined $$comps{$current}) {
          $$comps{$current} = [];
        }
      }
      else {
        $status = 0;
        last;
      }
    }
    elsif ($line =~ /^conditional\s*(\(([^\)]+)\))\s*{$/) {
      $status = $self->parse_conditional($fh, $2, $tag, \%flags, \$grname,
                                         $current, \@exclude, $comps,
                                         \$count);
      if (!$status) {
        last;
      }
    }
    elsif ($line =~ /^}$/) {
      if (defined $current) {
        if (!defined $$comps{$current}->[0] && !defined $exclude[0]) {
          ## The default components name was never used
          ## so we remove it from the components
          delete $$comps{$current};
        }
        else {
          ## It was used, so we need to add that name to
          ## the set of group names unless it's already been added.
          my($groups)   = $self->get_assignment($grtag);
          my($addgroup) = 1;
          if (defined $groups) {
            foreach my $group (@{$self->create_array($groups)}) {
              if ($current eq $group) {
                $addgroup = 0;
                last;
              }
            }
          }
          if ($addgroup) {
            $self->process_assignment_add($grtag, $current);
          }
        }
      }
      if (defined $current && $set) {
        $current = $defel;
        $set = undef;
      }
      else {
        ## We are at the end of a component.  If the only group
        ## we added was the default group, then we need to remove
        ## the group setting altogether.
        my($groups) = $self->get_assignment($grtag);
        if (defined $groups) {
          my(@grarray) = @{$self->create_array($groups)};
          if ($#grarray == 0 && $grarray[0] eq $defel) {
            $self->process_assignment($grtag, undef);
          }
        }

        ## This is not an error,
        ## this is the end of the components
        last;
      }
    }
    elsif (defined $current) {
      $status = $self->process_component_line($tag, $line, \%flags,
                                              \$grname, $current,
                                              \@exclude, $comps,
                                              \$count);
      if (!$status) {
        last;
      }
    }
    else {
      $status = 0;
      last;
    }
  }

  ## If we didn't encounter an error, didn't have any files explicitly
  ## listed and we attempted to exclude files, then we need to find the
  ## set of files that don't match the excluded files and add them.
  if ($status && $count == 0 && defined $grname) {
    my($alldir) = $self->get_assignment('recurse') || $flags{'recurse'};
    my(@files)  = $self->generate_default_file_list('.', \@exclude, $alldir);
    $self->sift_files(\@files,
                      $self->{'valid_components'}->{$tag},
                      $self->get_assignment('pch_header'),
                      $self->get_assignment('pch_source'),
                      $tag,
                      $$comps{$grname});
  }

  return $status;
}


sub parse_verbatim {
  my($self) = shift;
  my($fh)   = shift;
  my($type) = shift;
  my($loc)  = shift;

  if (!defined $loc) {
    return 0, 'You must provide a location parameter to verbatim';
  }

  ## All types are lower case
  $type = lc($type);

  if (!defined $self->{'verbatim'}->{$type}) {
    $self->{'verbatim'}->{$type} = {};
  }
  $self->{'verbatim'}->{$type}->{$loc} = [];
  my($array) = $self->{'verbatim'}->{$type}->{$loc};

  while(<$fh>) {
    my($line) = $self->preprocess_line($fh, $_);

    if ($line =~ /^}$/) {
      ## This is not an error,
      ## this is the end of the verbatim
      last;
    }
    else {
      push(@$array, $line);
    }
  }

  return 1, undef;
}


sub process_feature {
  my($self)    = shift;
  my($fh)      = shift;
  my($names)   = shift;
  my($parents) = shift;
  my($status)  = 1;
  my($error)   = undef;

  my($requires) = '';
  my($avoids)   = '';
  foreach my $name (@$names) {
    if ($name =~ /^!\s*(.*)$/) {
      if ($avoids ne '') {
        $avoids .= ' ';
      }
      $avoids .= $1;
    }
    else {
      if ($requires ne '') {
        $requires .= ' ';
      }
      $requires .= $name;
    }
  }

  if ($self->check_features($requires, $avoids)) {
    ## The required features are enabled, so we say that
    ## a project has been defined and we allow the parser to
    ## find the data held within the feature.
    ($status, $error) = $self->begin_project($parents);
    if ($status) {
      $self->{'feature_defined'} = 0;
      $self->{$self->{'type_check'}} = 1;
    }
  }
  else {
    ## Otherwise, we read in all the lines until we find the
    ## closing brace for the feature and it appears to the parser
    ## that nothing was defined.
    my($curly) = 1;
    while(<$fh>) {
      my($line) = $self->preprocess_line($fh, $_);

      ## This is a very simplistic way of finding the end of
      ## the feature definition.  It will work as long as no spurious
      ## open curly braces are counted.
      if ($line =~ /{$/) {
        ++$curly;
      }
      elsif ($line =~ /^}$/) {
        --$curly;
      }
      if ($curly == 0) {
        $self->{'feature_defined'} = 0;
        last;
      }
    }
  }

  return $status, $error;
}


sub process_array_assignment {
  my($self)  = shift;
  my($aref)  = shift;
  my($type)  = shift;
  my($array) = shift;

  if (!defined $$aref || $type eq 'assignment') {
    if ($type ne 'assign_sub') {
      $$aref = $array;
    }
  }
  else {
    if ($type eq 'assign_add') {
      push(@{$$aref}, @$array);
    }
    elsif ($type eq 'assign_sub') {
      my($count) = scalar(@{$$aref});
      for(my $i = 0; $i < $count; ++$i) {
        foreach my $val (@$array) {
          if ($$aref->[$i] eq $val) {
            splice(@{$$aref}, $i, 1);
            --$i;
            --$count;
            last;
          }
        }
      }
    }
  }
}


sub parse_define_custom {
  my($self)        = shift;
  my($fh)          = shift;
  my($tag)         = shift;
  my($status)      = 0;
  my($errorString) = "Unable to process $tag";

  ## Make the tag something _files
  $tag = lc($tag) . '_files';

  if ($tag eq $generic_key) {
    $errorString = "$tag is reserved";
  }
  elsif (defined $self->{'valid_components'}->{$tag}) {
    $errorString = "$tag has already been defined";
  }
  else {
    ## Update the custom_types assignment
    $self->process_assignment_add('custom_types', $tag);

    if (!defined $self->{'matching_assignments'}->{$tag}) {
      my(@keys) = keys %custom;
      push(@keys, @default_matching_assignments);
      $self->{'matching_assignments'}->{$tag} = \@keys;
    }

    ## Set up the 'optional' hash table
    $self->{'generated_exts'}->{$tag}->{'optional'} = {};

    my($optname) = undef;
    my($inscope) = 0;
    while(<$fh>) {
      my($line) = $self->preprocess_line($fh, $_);

      if ($line eq '') {
      }
      elsif ($line =~ /optional\s*\(([^\)]+)\)\s*{/) {
        $optname = $1;
        $optname =~ s/^\s+//;
        $optname =~ s/\s+$//;
        if (defined $customDefined{$optname} &&
            ($customDefined{$optname} & 0x08) != 0) {
          ++$inscope;
          if ($inscope != 1) {
            $status = 0;
            $errorString = 'Can not nest \'optional\' sections';
            last;
          }
        }
        else {
          $status = 0;
          $errorString = "Invalid optional name: $optname";
          last;
        }
      }
      elsif ($inscope) {
        if ($line =~ /^}$/) {
          $optname = undef;
          --$inscope;
        }
        else {
          if ($line =~ /(\w+)\s*\(([^\)]+)\)\s*\+=\s*(.*)/) {
            my($name) = lc($1);
            my($opt)  = $2;
            my(@val)  = split(/\s*,\s*/, $3);

            ## Fix $opt spacing
            $opt =~ s/(\&\&|\|\|)/ $1 /g;
            $opt =~ s/!\s+/!/g;

            if (!defined $self->{'generated_exts'}->{$tag}->
                                {'optional'}->{$optname}) {
              $self->{'generated_exts'}->{$tag}->
                     {'optional'}->{$optname} = {};
            }
            if (!defined $self->{'generated_exts'}->{$tag}->
                                {'optional'}->{$optname}->{$name}) {
              $self->{'generated_exts'}->{$tag}->
                     {'optional'}->{$optname}->{$name} = {};
            }
            if (!defined $self->{'generated_exts'}->{$tag}->
                                {'optional'}->{$optname}->{$name}->{$opt}) {
              $self->{'generated_exts'}->{$tag}->
                     {'optional'}->{$optname}->{$name}->{$opt} = [];
            }
            push(@{$self->{'generated_exts'}->{$tag}->{'optional'}->
                    {$optname}->{$name}->{$opt}}, @val);
          }
        }
      }
      elsif ($line =~ /^}$/) {
        $status = 1;
        $errorString = undef;

        ## Propagate the custom defined values into the mapped values
        foreach my $key (keys %{$self->{'valid_names'}}) {
          my($mapped) = $self->{'valid_names'}->{$key};
          if (UNIVERSAL::isa($mapped, 'ARRAY')) {
            my($value) = $self->{'generated_exts'}->{$tag}->{$$mapped[1]};
            if (defined $value) {
              ## Bypass the process_assignment() defined in this class
              ## to avoid unwanted keyword mapping.
              $self->SUPER::process_assignment($key, $value);
            }
          }
        }

        ## Set some defaults (if they haven't already been set)
        if (!defined $self->{'generated_exts'}->{$tag}->{'pre_filename'}) {
          $self->{'generated_exts'}->{$tag}->{'pre_filename'} = [ '' ];
        }
        if (!defined $self->{'generated_exts'}->{$tag}->{'pre_extension'}) {
          $self->{'generated_exts'}->{$tag}->{'pre_extension'} = [ '' ];
        }
        if (!defined $self->{'generated_exts'}->{$tag}->{'automatic'}) {
          $self->{'generated_exts'}->{$tag}->{'automatic'} = 1;
        }
        if (!defined $self->{'valid_components'}->{$tag}) {
          $self->{'valid_components'}->{$tag} = [];
        }
        last;
      }
      else {
        my(@values) = ();
        ## If this returns true, then we've found an assignment
        if ($self->parse_assignment($line, \@values)) {
          my($type)  = $values[0];
          my($name)  = $values[1];
          my($value) = $values[2];
          if (defined $customDefined{$name}) {
            if (($customDefined{$name} & 0x01) != 0) {
              $value = $self->escape_regex_special($value);
              my(@array) = split(/\s*,\s*/, $value);
              $self->process_array_assignment(
                        \$self->{'valid_components'}->{$tag}, $type, \@array);
            }
            else {
              if (!defined $self->{'generated_exts'}->{$tag}) {
                $self->{'generated_exts'}->{$tag} = {};
              }
              ## Try to convert the value into a relative path
              $value = $self->relative($value);

              if (($customDefined{$name} & 0x04) != 0) {
                if ($type eq 'assignment') {
                  $self->process_assignment(
                                     $name, $value,
                                     $self->{'generated_exts'}->{$tag});
                }
                elsif ($type eq 'assign_add') {
                  $self->process_assignment_add(
                                     $name, $value,
                                     $self->{'generated_exts'}->{$tag});
                }
                elsif ($type eq 'assign_sub') {
                  $self->process_assignment_sub(
                                     $name, $value,
                                     $self->{'generated_exts'}->{$tag});
                }
              }
              else {
                if (($customDefined{$name} & 0x02) != 0) {
                  ## Transform the name from something outputext to
                  ## something files.  We expect this to match the
                  ## names of valid_assignments.
                  $name =~ s/outputext/files/g;
                }

                ## Get it ready for regular expressions
                $value = $self->escape_regex_special($value);

                ## Process the array assignment
                my(@array) = split(/\s*,\s*/, $value);
                $self->process_array_assignment(
                            \$self->{'generated_exts'}->{$tag}->{$name},
                            $type, \@array);
              }
            }
          }
          else {
            $status = 0;
            $errorString = "Invalid assignment name: $name";
            last;
          }
        }
        elsif ($line =~ /^(\w+)\s+(\w+)(\s*=\s*(\w+)?)?/) {
          ## Check for keyword mapping here
          my($keyword) = $1;
          my($newkey)  = $2;
          my($mapkey)  = $4;
          if ($keyword eq 'keyword') {
            if (defined $self->{'valid_names'}->{$newkey}) {
              $status = 0;
              $errorString = "Cannot map $newkey onto an " .
                             "existing keyword";
              last;
            }
            elsif (!defined $mapkey) {
              $self->{'valid_names'}->{$newkey} = 1;
            }
            elsif ($newkey ne $mapkey) {
              if (defined $customDefined{$mapkey}) {
                $self->{'valid_names'}->{$newkey} = [ $tag, $mapkey ];
              }
              else {
                $status = 0;
                $errorString = "Cannot map $newkey to an " .
                               "undefined custom keyword: $mapkey";
                last;
              }
            }
            else {
              $status = 0;
              $errorString = "Cannot map $newkey to $mapkey";
              last;
            }
          }
          else {
            $status = 0;
            $errorString = "Unrecognized line: $line";
            last;
          }
        }
        else {
          $status = 0;
          $errorString = "Unrecognized line: $line";
          last;
        }
      }
    }
  }

  return $status, $errorString;
}


sub remove_duplicate_addition {
  my($self)    = shift;
  my($name)    = shift;
  my($value)   = shift;
  my($nval)    = shift;

  ## If we are modifying the libs, libpaths, macros or includes
  ## assignment with either addition or subtraction, we are going to
  ## perform a little fix on the value to avoid multiple
  ## libraries and to try to insure the correct linking order
  if ($name eq 'macros'   ||
      $name eq 'libpaths' || $name eq 'includes' || $name =~ /libs$/) {
    if (defined $nval) {
      my($allowed) = '';
      my(%parts)   = ();

      ## Convert the array into keys for a hash table
      @parts{@{$self->create_array($nval)}} = ();

      foreach my $val (@{$self->create_array($value)}) {
        if (!exists $parts{$val}) {
          $allowed .= $val . ' ';
        }
      }
      $allowed =~ s/\s+$//;
      return $allowed;
    }
  }

  return $value;
}


sub read_template_input {
  my($self)        = shift;
  my($status)      = 1;
  my($errorString) = undef;
  my($file)        = undef;
  my($tag)         = undef;
  my($ti)          = $self->get_ti_override();
  my($override)    = undef;

  if ($self->exe_target()) {
    if ($self->get_static() == 1) {
      $tag = 'lexe_template_input';
      if (!defined $self->{$tag}) {
        if (defined $$ti{'lib_exe'}) {
          $file = $$ti{'lib_exe'};
          $override = 1;
        }
        else {
          $file = $self->get_lib_exe_template_input_file();
        }
      }
    }
    else {
      $tag = 'dexe_template_input';
      if (!defined $self->{$tag}) {
        if (defined $$ti{'dll_exe'}) {
          $file = $$ti{'dll_exe'};
          $override = 1;
        }
        else {
          $file = $self->get_dll_exe_template_input_file();
        }
      }
    }
  }
  else {
    if ($self->get_static() == 1) {
      $tag = 'lib_template_input';
      if (!defined $self->{$tag}) {
        if (defined $$ti{'lib'}) {
          $file = $$ti{'lib'};
          $override = 1;
        }
        else {
          $file = $self->get_lib_template_input_file();
        }
      }
    }
    else {
      $tag = 'dll_template_input';
      if (!defined $self->{$tag}) {
        if (defined $$ti{'dll'}) {
          $file = $$ti{'dll'};
          $override = 1;
        }
        else {
          $file = $self->get_dll_template_input_file();
        }
      }
    }
  }

  if (defined $file) {
    my($file) = $self->search_include_path("$file.$TemplateInputExtension");
    if (defined $file) {
      $self->{$tag} = new TemplateInputReader($self->get_include_path());
      ($status, $errorString) = $self->{$tag}->cached_file_read($file);
    }
    else {
      if ($override) {
        $status = 0;
        $errorString = 'Unable to locate template input file.';
      }
    }
  }

  return $status, $errorString;
}


sub already_added {
  my($self)  = shift;
  my($array) = shift;
  my($name)  = shift;

  ## This method expects that the file
  ## name will be unix style
  $name =~ s/\\/\//g;

  foreach my $file (@$array) {
    if ($file eq $name) {
      return 1;
    }
  }

  ## If we haven't matched the name yet and the name
  ## begins with ./, we will remove it and try again.
  if ($name =~ s/^\.\///) {
    return $self->already_added($array, $name);
  }

  return 0;
}


sub get_applied_custom_keyword {
  my($self)  = shift;
  my($name)  = shift;
  my($type)  = shift;
  my($file)  = shift;
  my($value) = undef;

  if (defined $self->{'flag_overrides'}->{$type}->{$file}->{$name}) {
    $value = $self->{'flag_overrides'}->{$type}->{$file}->{$name};
  }
  else {
    $value = $self->get_assignment($name,
                                   $self->{'generated_exts'}->{$type});
  }
  return $self->relative($value, 1);
}


sub evaluate_optional_option {
  my($self)  = shift;
  my($opt)   = shift;
  my($value) = shift;

  if ($opt =~ /^!\s*(.*)/) {
    return (!exists $$value{$1} ? 1 : 0);
  }
  else {
    return (exists $$value{$opt} ? 1 : 0);
  }

  return 0;
}


sub process_optional_option {
  my($self)   = shift;
  my($opt)    = shift;
  my($value)  = shift;
  my($status) = undef;
  my(@parts)  = grep(!/^$/, split(/\s+/, $opt));

  for(my $i = 0; $i <= $#parts; $i++) {
    if ($parts[$i] eq '&&' || $parts[$i] eq '||') {
      if (defined $status) {
        if (defined $parts[$i + 1]) {
          if ($parts[$i] eq '&&') {
            $status &&= $self->evaluate_optional_option($parts[$i + 1],
                                                        $value);
          }
          else {
            $status ||= $self->evaluate_optional_option($parts[$i + 1],
                                                        $value);
          }
        }
        else {
          $self->warning("Expected token in optional after $parts[$i]");
        }
      }
      else {
        $self->warning("Unexpected token in optional: $parts[$i]");
      }
      ++$i;
    }
    else {
      if (!defined $status) {
        $status = $self->evaluate_optional_option($parts[$i], $value);
      }
      else {
        $self->warning("Unexpected token in optional: $parts[$i]");
      }
    }
  }

  return $status;
}


sub add_optional_filename_portion {
  my($self)    = shift;
  my($gentype) = shift;
  my($tag)     = shift;
  my($file)    = shift;
  my($array)   = shift;

  foreach my $name (keys %{$self->{'generated_exts'}->{$gentype}->{'optional'}->{$tag}}) {
    foreach my $opt (keys %{$self->{'generated_exts'}->{$gentype}->{'optional'}->{$tag}->{$name}}) {
      ## Get the name value
      my($value) = $self->get_applied_custom_keyword($name,
                                                     $gentype, $file);

      ## Convert the value into a hash map for easy lookup
      my(%values) = ();
      if (defined $value) {
        @values{split(/\s+/, $value)} = ();
      }

      ## See if the option or options are contained in the value
      if ($self->process_optional_option($opt, \%values)) {
        ## Add the optional portion
        push(@$array, @{$self->{'generated_exts'}->{$gentype}->{'optional'}->{$tag}->{$name}->{$opt}});
      }
    }
  }
}


sub get_pre_keyword_array {
  my($self)    = shift;
  my($keyword) = shift;
  my($gentype) = shift;
  my($tag)     = shift;
  my($file)    = shift;

  ## Get the general pre extension array
  my(@array) = @{$self->{'generated_exts'}->{$gentype}->{$keyword}};

  ## Add the component specific pre extension array
  my(@additional) = ();
  $tag =~ s/files$/$keyword/;
  if (defined $self->{'generated_exts'}->{$gentype}->{$tag}) {
    push(@additional, @{$self->{'generated_exts'}->{$gentype}->{$tag}});
  }

  ## Add in any optional portion to the array
  foreach my $itag ($keyword, $tag) {
    $self->add_optional_filename_portion($gentype, $itag,
                                         $file, \@additional);
  }

  ## If the current array only has the default,
  ## then we need to remove it
  if ($#array == 0 && $array[0] eq '' && $#additional >= 0) {
    pop(@array);
  }
  push(@array, @additional);

  return @array;
}


sub generated_filename_arrays {
  my($self)  = shift;
  my($part)  = shift;
  my($type)  = shift;
  my($tag)   = shift;
  my($file)  = shift;
  my($rmesc) = shift;
  my($noext) = shift;
  my(@array) = ();
  my(@pearr) = $self->get_pre_keyword_array('pre_extension',
                                            $type, $tag, $file);
  my(@pfarr) = $self->get_pre_keyword_array('pre_filename',
                                            $type, $tag, $file);
  my(@exts)  = (defined $self->{'generated_exts'}->{$type}->{$tag} ?
                  @{$self->{'generated_exts'}->{$type}->{$tag}} : ());

  if ($#exts == -1) {
    my($backtag) = $tag;
    if ($backtag =~ s/files$/outputext/) {
      $self->add_optional_filename_portion($type, $backtag,
                                           $file, \@exts);
    }
  }

  if ($#pearr == 0 && $#pfarr == 0 && $#exts == -1 &&
      $pearr[0] eq '' && $pfarr[0] eq '') {
    ## If both arrays are defined to be the defaults, then there
    ## is nothing for us to do.
  }
  else {
    my($dir)  = '';
    my($base) = undef;

    ## Correctly deal with pre filename and directories
    if ($part =~ /(.*[\/\\])([^\/\\]+)$/) {
      $dir = $1;
      $base = $2;
    }
    else {
      $base = $part;
    }

    ## If gendir was specified, then we need to account for that
    if (defined $self->{'flag_overrides'}->{$type} &&
        defined $self->{'flag_overrides'}->{$type}->{$file} &&
        defined $self->{'flag_overrides'}->{$type}->{$file}->{'gendir'}) {
      if ($self->{'flag_overrides'}->{$type}->{$file}->{'gendir'} eq '.') {
        $dir = '';
      }
      else {
        $dir = $self->{'flag_overrides'}->{$type}->{$file}->{'gendir'} . '/';
      }
    }

    ## Loop through creating all of the possible file names
    foreach my $pe (@pearr) {
      push(@array, []);
      if ($rmesc) {
        $pe =~ s/\\\././g;
      }
      foreach my $pf (@pfarr) {
        if ($rmesc) {
          $pf =~ s/\\\././g;
        }
        if ($noext) {
          push(@{$array[$#array]}, "$dir$pf$base$pe");
        }
        else {
          foreach my $ext (@exts) {
            if ($rmesc) {
              $ext =~ s/\\\././g;
            }
            push(@{$array[$#array]}, "$dir$pf$base$pe$ext");
          }
        }
      }
    }
  }

  return @array;
}


sub generated_filenames {
  my($self)  = shift;
  my($part)  = shift;
  my($type)  = shift;
  my($tag)   = shift;
  my($file)  = shift;
  my($rmesc) = shift;
  my($noext) = shift;
  my(@files) = ();
  my(@array) = $self->generated_filename_arrays($part, $type, $tag,
                                                $file, $rmesc, $noext);

  foreach my $array (@array) {
    push(@files, @$array);
  }

  return @files;
}


sub add_generated_files {
  my($self)    = shift;
  my($gentype) = shift;
  my($tag)     = shift;
  my($arr)     = shift;

  my($wanted) = $self->{'valid_components'}->{$gentype}->[0];
  if (defined $wanted) {
    ## Remove the escape sequences for the wanted extension.  It doesn't
    ## matter if the first valid extension is not the same as the actual
    ## input file (ex. input = car.y and first ext is .yy).  The extension
    ## is immediately removed in generated_filename_arrays.
    $wanted =~ s/\\//g;
  }
  else {
    $wanted = '';
  }

  ## Get the generated filenames
  my(@added) = ();
  foreach my $file (@$arr) {
    foreach my $gen ($self->generated_filenames($file, $gentype, $tag,
                                                "$file$wanted", 1, 1)) {
      $self->list_generated_file($gentype, $tag, \@added, $gen, $file);
    }
  }

  if ($#added >= 0) {
    my($names) = $self->{$tag};

    ## Get all files in one list and save the directory
    ## and component group in a hashed array.
    my(@all) = ();
    my(%dircomp) = ();
    foreach my $name (keys %$names) {
      foreach my $key (keys %{$$names{$name}}) {
        push(@all, @{$$names{$name}->{$key}});
        foreach my $file (@{$$names{$name}->{$key}}) {
          $dircomp{$self->mpc_dirname($file)} = $key;
        }
      }
    }

    ## Create a small array of only the files we want to add.
    ## We put them all together so we can keep them in order when
    ## we put them at the front of the main file list.
    my(@oktoadd) = ();
    foreach my $file (@added) {
      if (!$self->already_added(\@all, $file)) {
        push(@oktoadd, $file);
      }
    }

    ## If we have files to add, make sure we add them to a group
    ## that has the same directory location as the files we're adding.
    if ($#oktoadd >= 0) {
      my($key) = $dircomp{$self->mpc_dirname($oktoadd[0])};
      if (!defined $key) {
        my($defel) = $self->get_default_element_name();
        my($check) = $oktoadd[0];
        foreach my $regext (@{$self->{'valid_components'}->{$tag}}) {
          if ($check =~ s/$regext$//) {
            last;
          }
        }
        foreach my $vc (keys %{$self->{'valid_components'}}) {
          if ($vc ne $tag) {
            foreach my $name (keys %{$self->{$vc}}) {
              foreach my $ckey (keys %{$self->{$vc}->{$name}}) {
                if ($ckey ne $defel) {
                  foreach my $ofile (@{$self->{$vc}->{$name}->{$ckey}}) {
                    my($file) = $ofile;
                    foreach my $regext (@{$self->{'valid_components'}->{$vc}}) {
                      if ($file =~ s/$regext//) {
                        last;
                      }
                    }
                    if ($file eq $check) {
                      $key = $ckey;
                      last;
                    }
                  }
                }
                last if (defined $key);
              }
            }
            last if (defined $key);
          }
        }
        if (!defined $key) {
          $key = $defel;
        }
      }
      foreach my $name (keys %$names) {
        unshift(@{$$names{$name}->{$key}}, @oktoadd);
      }
    }
  }
}


sub search_for_entry {
  my($self)    = shift;
  my($file)    = shift;
  my($main)    = shift;
  my($preproc) = shift;
  my($name)    = undef;
  my($fh)      = new FileHandle();

  if (open($fh, $file)) {
    my($poundifed) = 0;
    my($commented) = 0;

    while(<$fh>) {
      if (!$preproc || !$commented) {
        ## Remove c++ style comments
        $_ =~ s/\/\/.*//;
      }

      ## If the current language supports a c preprocessor, we
      ## will perform a minimal check for #if 0 and c style comments.
      if ($preproc) {
        ## Remove one line c style comments
        $_ =~ s/\/\*.*\*\///g;

        if ($commented) {
          if (/\*\//) {
            ## Found the end of a multi-line c style comment
            --$commented;
          }
        }
        else {
          if (/\/\*/) {
            ## Found the beginning of a multi-line c style comment
            ++$commented;
          }
          elsif (/#\s*if\s+0/) {
            ## Found the beginning of a #if 0
            ++$poundifed;
          }
          elsif ($poundifed) {
            if (/#\s*if/) {
              ## We need to keep track of any other #if directives
              ## to be sure that when we see an #endif we don't
              ## count the wrong one.
              ++$poundifed;
            }
            elsif (/#\s*endif/) {
              ## Found a #endif, so decrement our count
              --$poundifed;
            }
          }
        }
      }

      ## Check for main; Make sure it's not #if 0'ed and not commented out
      if (!$poundifed && !$commented &&
          (/\s+$main\s*\(/ || /^\s*$main\s*\(/)) {
        ## If we've found a main, set the exename to the basename
        ## of the cpp file with the extension removed
        $name = basename($file);
        $name =~ s/\.[^\.]+$//;
        last;
      }
    }
    close($fh);
  }
  return $name;
}


sub generate_default_target_names {
  my($self) = shift;

  if (!$self->exe_target()) {
    my($sharedname) = $self->get_assignment('sharedname');
    if (defined $sharedname &&
        !defined $self->get_assignment('staticname')) {
      $self->process_assignment('staticname', $sharedname);
    }
    my($staticname) = $self->get_assignment('staticname');
    if (defined $staticname &&
        !defined $self->get_assignment('sharedname')) {
      $self->process_assignment('sharedname', $staticname);
      $sharedname = $staticname;
    }

    ## If it's neither an exe or library target, we will search
    ## through the source files for a main()
    if (!$self->lib_target()) {
      my($exename) = undef;
      my(@sources) = $self->get_component_list('source_files', 1);
      my($main)    = $language{$self->get_language()}->[3];
      my($preproc) = $language{$self->get_language()}->[4];

      foreach my $file (@sources) {
        $exename = $self->search_for_entry($file, $main, $preproc);

        ## Set the exename assignment
        if (defined $exename) {
          $self->process_assignment('exename', $exename);
          last;
        }
      }

      ## If we still don't have a project type, then we will
      ## default to a library if there are source files
      if (!$self->exe_target()) {
        if ($#sources < 0) {
          @sources = $self->get_component_list('resource_files', 1);
        }
        if ($#sources >= 0) {
          $self->process_assignment('sharedname',
                                    $self->{'unmodified_project_name'});
          $self->process_assignment('staticname',
                                    $self->{'unmodified_project_name'});
        }
      }
    }
  }

  ## If we are generating only static projects, then we need to
  ## unset the sharedname, so that we can insure that projects of
  ## various types only generate static targets.
  if ($self->get_static() == 1) {
    my($sharedname) = $self->get_assignment('sharedname');
    if (defined $sharedname) {
      $self->process_assignment('sharedname', undef);
    }
  }

  ## Check for the use of an asterisk in the name
  foreach my $key ('exename', 'sharedname', 'staticname') {
    my($value) = $self->get_assignment($key);
    if (defined $value && $value =~ /\*/) {
      $value = $self->fill_type_name($value,
                                     $self->{'unmodified_project_name'});
      $self->process_assignment($key, $value);
    }
  }
}


sub generate_default_pch_filenames {
  my($self)    = shift;
  my($files)   = shift;
  my($pchhdef) = (defined $self->get_assignment('pch_header'));
  my($pchcdef) = (defined $self->get_assignment('pch_source'));

  if (!$pchhdef || !$pchcdef) {
    my($pname)     = $self->escape_regex_special(
                             $self->get_assignment('project_name'));
    my($hcount)    = 0;
    my($ccount)    = 0;
    my($hmatching) = undef;
    my($cmatching) = undef;
    foreach my $file (@$files) {
      ## If the file doesn't even contain _pch, then there's no point
      ## in looping through all of the extensions
      if ($file =~ /_pch/) {
        if (!$pchhdef) {
          foreach my $ext (@{$self->{'valid_components'}->{'header_files'}}) {
            if ($file =~ /(.*_pch$ext)$/) {
              $self->process_assignment('pch_header', $1);
              ++$hcount;
              if ($file =~ /$pname/) {
                $hmatching = $file;
              }
              last;
            }
          }
        }
        if (!$pchcdef) {
          foreach my $ext (@{$self->{'valid_components'}->{'source_files'}}) {
            if ($file =~ /(.*_pch$ext)$/) {
              $self->process_assignment('pch_source', $1);
              ++$ccount;
              if ($file =~ /$pname/) {
                $cmatching = $file;
              }
              last;
            }
          }
        }
      }
    }
    if (!$pchhdef && $hcount > 1 && defined $hmatching) {
      $self->process_assignment('pch_header', $hmatching);
    }
    if (!$pchcdef && $ccount > 1 && defined $cmatching) {
      $self->process_assignment('pch_source', $cmatching);
    }
  }
}


sub fix_pch_filenames {
  my($self) = shift;
  foreach my $type ('pch_header', 'pch_source') {
    my($pch) = $self->get_assignment($type);
    if (defined $pch && $pch eq '') {
      $self->process_assignment($type, undef);
    }
  }
}


sub remove_extra_pch_listings {
  my($self) = shift;
  my(@pchs) = ('pch_header', 'pch_source');
  my(@tags) = ('header_files', 'source_files');

  for(my $j = 0; $j <= $#pchs; ++$j) {
    my($pch) = $self->get_assignment($pchs[$j]);

    if (defined $pch) {
      ## If we are converting slashes, then we need to
      ## convert the pch file back to forward slashes
      if ($self->{'convert_slashes'}) {
        $pch =~ s/\\/\//g;
      }

      ## Find out which files are duplicated
      my($names) = $self->{$tags[$j]};
      foreach my $name (keys %$names) {
        my($comps) = $$names{$name};
        foreach my $key (keys %$comps) {
          my($array) = $$comps{$key};
          my($count) = scalar(@$array);
          for(my $i = 0; $i < $count; ++$i) {
            if ($pch eq $$array[$i]) {
              splice(@$array, $i, 1);
              --$count;
            }
          }
        }
      }
    }
  }
}


sub sift_files {
  my($self)   = shift;
  my($files)  = shift;
  my($exts)   = shift;
  my($pchh)   = shift;
  my($pchc)   = shift;
  my($tag)    = shift;
  my($array)  = shift;
  my($alldir) = shift;
  my(@saved)  = ();
  my($ec)     = $self->{'exclude_components'};

  foreach my $file (@$files) {
    foreach my $ext (@$exts) {
      ## Always exclude the precompiled header and cpp
      if ($file =~ /$ext$/ && (!defined $pchh || $file ne $pchh) &&
                              (!defined $pchc || $file ne $pchc)) {
        my($exclude) = 0;
        if (defined $$ec{$tag}) {
          foreach my $exc (@{$$ec{$tag}}) {
            if ($file =~ /$exc$/) {
              $exclude = 1;
              last;
            }
          }
        }
        elsif (!$alldir && $tag eq 'resource_files') {
          ## Save these files for later.  There may
          ## be more than one and we want to try and
          ## find the one that corresponds to this project
          $exclude = 1;
          push(@saved, $file);
        }

        if (!$exclude && !$self->already_added($array, $file)) {
          push(@$array, $file);
        }
        last;
      }
    }
  }

  ## Now deal with the saved files
  if (defined $saved[0]) {
    if ($#saved == 0) {
      ## Theres only one rc file, take it
      push(@$array, $saved[0]);
    }
    else {
      my($pjname) = $self->escape_regex_special(
                              $self->transform_file_name(
                                  $self->get_assignment('project_name')));
      my($found)  = 0;
      foreach my $save (@saved) {
        if ($save =~ /$pjname/) {
          if (!$self->already_added($array, $save)) {
            push(@$array, $save);
            $found = 1;
          }
        }
      }

      ## If we didn't find an rc file, try a case insensitive search.
      ## After all, these are a Windows specific file type.
      if (!$found) {
        foreach my $save (@saved) {
          if ($save =~ /$pjname/i) {
            if (!$self->already_added($array, $save)) {
              push(@$array, $save);
            }
          }
        }
      }
    }
  }
}


sub generate_default_components {
  my($self)    = shift;
  my($files)   = shift;
  my($passed)  = shift;
  my($vc)      = $self->{'valid_components'};
  my(@tags)    = (defined $passed ? $passed : keys %$vc);
  my($pchh)    = $self->get_assignment('pch_header');
  my($pchc)    = $self->get_assignment('pch_source');
  my($recurse) = $self->get_assignment('recurse');

  ## The order of @tags may make a difference in the way that generated
  ## files get added.  And since the tags are user definable, there may be
  ## a problem with that.  I can not confirm that this can actually cause a
  ## problem, so I am leaving it alone.
  foreach my $tag (@tags) {
    if (!defined $self->{'generated_exts'}->{$tag} ||
        $self->{'generated_exts'}->{$tag}->{'automatic'}) {
      my($exts) = $$vc{$tag};
      if (defined $$exts[0]) {
        if (defined $self->{$tag}) {
          ## If the tag is defined, then process directories
          my($names) = $self->{$tag};
          foreach my $name (keys %$names) {
            my($comps) = $$names{$name};
            foreach my $comp (keys %$comps) {
              my($array) = $$comps{$comp};
              if (defined $passed) {
                $self->sift_files($files, $exts, $pchh, $pchc, $tag, $array);
              }
              else {
                my(@built) = ();
                foreach my $file (@$array) {
                  if (-d $file) {
                    my($alldir) = $recurse ||
                        $self->{'flag_overrides'}->{$tag}->{$file}->{'recurse'};
                    my(@gen) = $self->generate_default_file_list(
                                        $file, [], $alldir);
                    $self->sift_files(\@gen, $exts, $pchh,
                                      $pchc, $tag, \@built, $alldir);
                  }
                  else {
                    if (!$self->already_added(\@built, $file)) {
                      push(@built, $file);
                    }
                  }
                }
                $$comps{$comp} = \@built;
              }
            }
          }
        }
        else {
          ## Generate default values for undefined tags
          my($defcomp) = $self->get_default_element_name();
          my($names) = {};
          $self->{$tag} = $names;
          my($comps) = {};
          $$names{$self->get_default_component_name()} = $comps;
          $$comps{$defcomp} = [];
          my($array) = $$comps{$defcomp};

          $self->{'defaulted'}->{$tag} = 1;

          if (!defined $specialComponents{$tag}) {
            $self->sift_files($files, $exts, $pchh, $pchc, $tag, $array);
            if (defined $sourceComponents{$tag}) {
              foreach my $gentype (keys %{$self->{'generated_exts'}}) {
                ## If we are auto-generating the source_files, then
                ## we need to make sure that any generated source
                ## files that are added are put at the front of the list.
                my(@front)  = ();
                my(@copy)   = @$array;
                my(@input)  = $self->get_component_list($gentype, 1);

                @$array = ();
                foreach my $file (@copy) {
                  my($found) = 0;
                  foreach my $input (@input) {
                    my($part) = $input;
                    foreach my $wanted (@{$self->{'valid_components'}->{$gentype}}) {
                      if ($part =~ s/$wanted$//) {
                        last;
                      }
                    }
                    $part = $self->escape_regex_special($part);
                    foreach my $re ($self->generated_filenames($part, $gentype,
                                                               $tag, $input,
                                                               0)) {
                      if ($file =~ /$re$/) {
                        ## No need to check for previously added files
                        ## here since there are none.
                        push(@front, $file);
                        $found = 1;
                        last;
                      }
                    }
                    if ($found) {
                      last;
                    }
                  }
                  if (!$found) {
                    ## No need to check for previously added files
                    ## here since there are none.
                    push(@$array, $file);
                  }
                }

                if (defined $front[0]) {
                  unshift(@$array, @front);
                }
              }
            }
          }
        }
      }
    }
  }
}


sub remove_duplicated_files {
  my($self)   = shift;
  my($dest)   = shift;
  my($source) = shift;
  my($names)  = $self->{$dest};
  my(@slist)  = $self->get_component_list($source, 1);
  my(%shash)  = ();

  ## Convert the array into keys for a hash table
  @shash{@slist} = ();

  ## Find out which source files are listed
  foreach my $name (keys %$names) {
    foreach my $key (keys %{$$names{$name}}) {
      my($array) = $$names{$name}->{$key};
      my($count) = scalar(@$array);
      for(my $i = 0; $i < $count; ++$i) {
        ## Is the source file in the component array?
        if (exists $shash{$$array[$i]}) {
          ## Remove the element and fix the index and count
          splice(@$array, $i, 1);
          --$count;
          --$i;
        }
      }
    }
  }
}


sub generated_source_listed {
  my($self)  = shift;
  my($gent)  = shift;
  my($tag)   = shift;
  my($arr)   = shift;
  my($sext)  = shift;
  my($names) = $self->{$tag};

  ## Find out which generated source files are listed
  foreach my $name (keys %$names) {
    my($comps) = $$names{$name};
    foreach my $key (keys %$comps) {
      foreach my $val (@{$$comps{$key}}) {
        foreach my $i (@$arr) {
          my($ifile) = $self->escape_regex_special($i);
          foreach my $wanted (@$sext) {
            ## Remove any escape characters from the extension
            my($oext) = $wanted;
            $oext =~ s/\\//g;
            foreach my $re ($self->generated_filenames($ifile, $gent,
                                                       $tag, "$i$oext", 0)) {
              if ($val =~ /$re$/) {
                return 1;
              }
            }
          }
        }
      }
    }
  }

  return 0;
}


sub list_default_generated {
  my($self)    = shift;
  my($gentype) = shift;
  my($tags)    = shift;

  if ($self->{'generated_exts'}->{$gentype}->{'automatic'}) {
    ## After all source and headers have been defaulted, see if we
    ## need to add the generated files
    if (defined $self->{$gentype}) {
      ## Build up the list of files
      my(@arr)    = ();
      my($names)  = $self->{$gentype};
      foreach my $name (keys %$names) {
        my($comps) = $$names{$name};
        foreach my $key (keys %$comps) {
          my($array) = $$comps{$key};
          foreach my $val (@$array) {
            my($f) = $val;
            foreach my $wanted (@{$self->{'valid_components'}->{$gentype}}) {
              if ($f =~ s/$wanted$//) {
                last;
              }
            }

            ## If the user provided file does not match any of the
            ## extensions specified by the custom definition, we need
            ## to remove the extension or else this file will not be
            ## added to the project.
            if ($f eq $val) {
              $f =~ s/\.[^\.]+$//;
            }

            push(@arr, $f);
          }
        }
      }

      foreach my $type (@$tags) {
        ## Do not add generated files if they are "special"
        ## unless they haven't been explicitly supplied.
        if (!$specialComponents{$type} ||
            !$self->{'special_supplied'}->{$type}) {
          if (!$self->generated_source_listed(
                                $gentype, $type, \@arr,
                                $self->{'valid_components'}->{$gentype})) {
            $self->add_generated_files($gentype, $type, \@arr);
          }
        }
      }
    }
  }
}


sub prepend_gendir {
  my($self)    = shift;
  my($created) = shift;
  my($ofile)   = shift;
  my($gentype) = shift;
  my($key)     = undef;

  foreach my $ext (@{$self->{'valid_components'}->{$gentype}}) {
    my($e) = $ext;
    $e =~ s/\\//g;
    $key = "$ofile$e";
    if (defined $self->{'flag_overrides'}->{$gentype}->{$key}) {
      last;
    }
    else {
      $key = undef;
    }
  }

  if (defined $key) {
    foreach my $ma (@{$self->{'matching_assignments'}->{$gentype}}) {
      if ($ma eq 'gendir') {
        if (defined $self->{'flag_overrides'}->{$gentype}->{$key}->{$ma}) {
          ## Convert the file to unix style for basename
          $created =~ s/\\/\//g;
          return "$self->{'flag_overrides'}->{$gentype}->{$key}->{$ma}/" .
                 basename($created);
        }
      }
    }
  }

  return $created;
}


sub list_generated_file {
  my($self)    = shift;
  my($gentype) = shift;
  my($tag)     = shift;
  my($array)   = shift;
  my($file)    = shift;
  my($ofile)   = shift;

  $file = $self->escape_regex_special($file);

  foreach my $gen ($self->get_component_list($gentype, 1)) {
    my($input) = $gen;
    foreach my $ext (@{$self->{'valid_components'}->{$gentype}}) {
      ## Remove the extension.
      ## If it works, then we can exit this loop.
      if ($gen =~ s/$ext$//) {
        last;
      }
    }

    ## If the user provided file does not match any of the
    ## extensions specified by the custom definition, we need
    ## to remove the extension or else this file will not be
    ## added to the project.
    if ($gen eq $input) {
      $gen =~ s/\.[^\.]+$//;
    }

    ## See if we need to add the file.  We only need to bother
    ## if the length of $gen is less than or equal to the length of
    ## $file because they couldn't possibly match if they weren't.
    if (length(basename($gen)) <= length(basename($file))) {
      foreach my $re ($self->generated_filenames($gen, $gentype,
                                                 $tag, $input, 1)) {
        if ($re =~ /$file(.*)?$/) {
          my($created) = $re;
          if (defined $ofile) {
            $created = $self->prepend_gendir($created, $ofile, $gentype);
          }
          if (!$self->already_added($array, $created)) {
            push(@$array, $created);
          }
          last;
        }
      }
    }
  }
}


sub add_corresponding_component_files {
  my($self)   = shift;
  my($ftags)  = shift;
  my($tag)    = shift;
  my($names)  = undef;
  my($grname) = $grouped_key . $tag;
  my($defel)  = $self->get_default_element_name();

  ## Collect up all of the files that have already been listed
  ## with the extension removed.
  my(%filecomp) = ();
  foreach my $filetag (@$ftags) {
    $names = $self->{$filetag};
    foreach my $name (keys %$names) {
      foreach my $comp (keys %{$$names{$name}}) {
        foreach my $sfile (@{$$names{$name}->{$comp}}) {
          my($mod) = $sfile;
          $mod =~ s/\.[^\.]+$//;
          $filecomp{$mod} = $comp;
        }
      }
    }
  }

  ## Create a hash array keyed off of the existing files of the type
  ## that we plan on adding.
  my($fexist)  = 0;
  my(%scfiles) = ();
  $names = $self->{$tag};
  foreach my $name (keys %$names) {
    ## Check to see if files exist in the default group
    if (defined $$names{$name}->{$defel} &&
        defined $$names{$name}->{$defel}->[0]) {
      $fexist = 1;
    }
    foreach my $comp (keys %{$$names{$name}}) {
      @scfiles{@{$$names{$name}->{$comp}}} = ();
    }
  }

  ## Create an array of extensions for the files we want to add
  my(@exts) = ();
  foreach my $ext (@{$self->{'valid_components'}->{$tag}}) {
    push(@exts, $ext);
    $exts[$#exts] =~ s/\\//g;
  }

  ## Check each file against a possible new file addition
  my($adddefaultgroup) = 0;
  my($oktoadddefault)  = 0;
  foreach my $sfile (keys %filecomp) {
    my($found) = 0;
    foreach my $ext (@exts) {
      if (exists $scfiles{"$sfile$ext"}) {
        $found = 1;
        last;
      }
    }

    if (!$found) {
      ## Get the array of files for the selected component name
      my($array) = [];
      my($comp)  = $filecomp{$sfile};
      foreach my $name (keys %$names) {
        if (defined $$names{$name}->{$comp}) {
          $array = $$names{$name}->{$comp};
        }
      }

      ## First check to see if the file exists
      foreach my $ext (@exts) {
        if (-r "$sfile$ext") {
          push(@$array, "$sfile$ext");
          $found = 1;
          last;
        }
      }

      ## If it doesn't exist, see if it will be generated
      if (!$found) {
        foreach my $gentype (keys %{$self->{'generated_exts'}}) {
          $self->list_generated_file($gentype, $tag, $array, $sfile);
        }
      }

      ## If we have any files at all in the component array, check
      ## to see if we need to add a new group name
      if (defined $$array[0]) {
        my($compexists) = undef;
        my($grval)      = $self->get_assignment($grname);
        if (defined $grval) {
          foreach my $grkey (@{$self->create_array($grval)}) {
            if ($grkey eq $comp) {
              $compexists = 1;
              last;
            }
          }
        }

        if (!$compexists) {
          if ($comp eq $defel) {
            $adddefaultgroup = 1;
          }
          else {
            $self->process_assignment_add($grname, $comp);
            $oktoadddefault = 1;
            $adddefaultgroup |= $fexist;
          }
        }

        ## Put the array back into the component list
        foreach my $name (keys %$names) {
          $$names{$name}->{$comp} = $array;
        }
      }
    }
  }

  ## We only need to add the default group name if we wanted to
  ## add the default group when adding new files and we added a group
  ## by some other name.  Otherwise, defaulted files would always be
  ## in a group, which is not what we want.
  if ($adddefaultgroup && $oktoadddefault) {
    $self->process_assignment_add($grname, $defel);
  }
}


sub get_default_project_name {
  my($self) = shift;
  my($name) = $self->{'current_input'};

  if ($name eq '') {
    $name = $self->transform_file_name($self->base_directory());
  }
  else {
    ## Since files on UNIX can have back slashes, we transform them
    ## into underscores.
    $name =~ s/\\/_/g;

    ## Convert the name to a usable name
    $name = $self->transform_file_name($name);

    ## Take off the extension
    $name =~ s/\.[^\.]+$//;
  }

  return $name;
}


sub remove_excluded {
  my($self) = shift;
  my(@tags) = @_;

  ## Process each file type and remove the excluded files
  foreach my $tag (@tags) {
    my($names) = $self->{$tag};
    foreach my $name (keys %$names) {
      foreach my $comp (keys %{$$names{$name}}) {
        my($count) = scalar(@{$$names{$name}->{$comp}});
        for(my $i = 0; $i < $count; ++$i) {
          my($file) = $$names{$name}->{$comp}->[$i];
          if (defined $self->{'remove_files'}->{$tag}->{$file}) {
            splice(@{$$names{$name}->{$comp}}, $i, 1);
            --$i;
            --$count;
          }
        }
      }
    }
    delete $self->{'remove_files'}->{$tag};
  }
}

sub generate_defaults {
  my($self) = shift;

  ## Generate default project name
  if (!defined $self->get_assignment('project_name')) {
    $self->set_project_name($self->get_default_project_name());
  }

  ## Generate the default pch file names (if needed)
  my(@files) = $self->generate_default_file_list(
                                 '.', [], $self->get_assignment('recurse'));
  $self->generate_default_pch_filenames(\@files);

  ## If the pch file names are empty strings then we need to fix that
  $self->fix_pch_filenames();

  ## Generate default components, but %specialComponents
  ## are skipped in the initial default components generation
  $self->generate_default_components(\@files);

  ## Remove source files that are also listed in the template files
  ## If we do not do this, then generated projects can be invalid.
  $self->remove_duplicated_files('source_files', 'template_files');

  ## If pch files are listed in header_files or source_files more than
  ## once, we need to remove the extras
  $self->remove_extra_pch_listings();

  ## Generate the default generated list of files
  ## only if we defaulted the generated file list
  my(@vc) = keys %{$self->{'valid_components'}};
  foreach my $gentype (keys %{$self->{'generated_exts'}}) {
    $self->list_default_generated($gentype, \@vc);
  }

  ## Now that all of the source files have been added
  ## we need to remove those that have need to be removed
  $self->remove_excluded('source_files');

  ## Add %specialComponents files based on the
  ## source_components (i.e. .h and .i or .inl based on .cpp)
  my(@scomp) = keys %sourceComponents;
  foreach my $tag (keys %specialComponents) {
    $self->add_corresponding_component_files(\@scomp, $tag);
  }

  ## Now, if the %specialComponents are still empty
  ## then take any file that matches the components extension
  foreach my $tag (keys %specialComponents) {
    if (!$self->{'special_supplied'}->{$tag}) {
      my($names) = $self->{$tag};
      if (defined $names) {
        ## We only want to generate default components if we have
        ## defaulted the source files or we have no files listed
        ## in the current special component.
        my($ok) = $self->{'defaulted'}->{'source_files'};
        if (!$ok) {
          my(@all) = ();
          foreach my $name (keys %$names) {
            foreach my $key (keys %{$$names{$name}}) {
              push(@all, @{$$names{$name}->{$key}});
            }
          }
          $ok = ($#all == -1);
        }
        if ($ok) {
          $self->generate_default_components(\@files, $tag);
        }
      }
    }
  }

  ## Now that all of the other files have been added
  ## we need to remove those that have need to be removed
  my(@rmkeys) = keys %{$self->{'remove_files'}};
  if ($#rmkeys != -1) {
    $self->remove_excluded(@rmkeys);
  }

  ## Generate default target names after all source files are added
  $self->generate_default_target_names();
}


sub set_project_name {
  my($self) = shift;
  my($name) = shift;

  ## Save the unmodified project name so that when we
  ## need to determine the default target name, we can use
  ## what is expected by the user.
  $self->{'unmodified_project_name'} = $name;

  ## If we are applying the name modifier to the project
  ## then we will modify the project name
  if ($self->get_apply_project()) {
    my($nmod) = $self->get_name_modifier();

    if (defined $nmod) {
      $nmod =~ s/\*/$name/g;
      $name = $nmod;
    }
  }

  ## Set the project_name assignment so that the TemplateParser
  ## can get the project name.
  $self->process_assignment('project_name', $name);
}


sub project_name {
  my($self) = shift;
  return $self->get_assignment('project_name');
}


sub lib_target {
  my($self) = shift;
  return (defined $self->get_assignment('sharedname') ||
          defined $self->get_assignment('staticname'));
}


sub exe_target {
  my($self) = shift;
  return (defined $self->get_assignment('exename'));
}


sub get_component_list {
  my($self)      = shift;
  my($tag)       = shift;
  my($noconvert) = shift;
  my($names)     = $self->{$tag};
  my(@list)      = ();

  foreach my $name (keys %$names) {
    foreach my $key (keys %{$$names{$name}}) {
      push(@list, @{$$names{$name}->{$key}});
    }
  }

  ## By default, if 'convert_slashes' is true, then we convert slashes
  ## to backslashes.  There are cases where we do not want to convert
  ## the slashes, in that case get_component_list() was called with
  ## an additional parameter indicating this.
  if (!$noconvert && $self->{'convert_slashes'}) {
    for(my $i = 0; $i <= $#list; $i++) {
      $list[$i] = $self->slash_to_backslash($list[$i]);
    }
  }

  if ($self->{'sort_files'}) {
    @list = sort { $self->file_sorter($a, $b) } @list;
  }

  return @list;
}


sub check_custom_output {
  my($self)    = shift;
  my($based)   = shift;
  my($cinput)  = shift;
  my($ainput)  = shift;
  my($type)    = shift;
  my($comps)   = shift;
  my(@outputs) = ();

  foreach my $array ($self->generated_filename_arrays($cinput, $based,
                                                      $type, $ainput, 1)) {
    foreach my $built (@$array) {
      if (@$comps == 0) {
        push(@outputs, $built);
        last;
      }
      elsif (defined $specialComponents{$type} &&
             !$self->{'special_supplied'}->{$type}) {
        push(@outputs, $built);
        last;
      }
      else {
        my($base) = $built;
        if ($self->{'convert_slashes'}) {
          $base =~ s/\\/\//g;
        }
        my($re) = $self->escape_regex_special(basename($base));
        foreach my $c (@$comps) {
          ## We only match if the built file name matches from
          ## beginning to end or from a slash to the end.
          if ($c =~ /^$re$/ || $c =~ /[\/\\]$re$/) {
            push(@outputs, $built);
            last;
          }
        }
      }
    }
  }

  return @outputs;
}


sub get_special_value {
  my($self)   = shift;
  my($type)   = shift;
  my($cmd)    = shift;
  my($based)  = shift;
  my(@params) = @_;

  if ($type =~ /^custom_type/) {
    return $self->get_custom_value($cmd, $based, @params);
  }
  elsif ($type =~ /^$grouped_key/) {
    return $self->get_grouped_value($type, $cmd, $based);
  }

  return undef;
}


sub get_grouped_value {
  my($self)  = shift;
  my($type)  = shift;
  my($cmd)   = shift;
  my($based) = shift;
  my($value) = undef;

  ## Make it all lower case
  $type = lc($type);

  ## Remove the grouped_ part
  $type =~ s/^$grouped_key//;

  ## Add the s if it isn't there
  if ($type !~ /s$/) {
    $type .= 's';
  }

  my($names) = $self->{$type};
  if ($cmd eq 'files') {
    foreach my $name (keys %$names) {
      my($comps) = $$names{$name};
      foreach my $comp (keys %$comps) {
        if ($comp eq $based) {
          if ($self->{'convert_slashes'}) {
            my(@converted) = ();
            foreach my $file (@{$$comps{$comp}}) {
              push(@converted, $self->slash_to_backslash($file));
            }
            $value = \@converted;
          }
          else {
            $value = $$comps{$comp};
          }
          if ($self->{'sort_files'}) {
            my(@sorted) = sort { $self->file_sorter($a, $b) } @$value;
            $value = \@sorted;
          }
          last;
        }
      }
    }
  }
  elsif ($cmd eq 'component_name') {
    ## If there is more than one name, then we will need
    ## to deal with that at a later time.
    foreach my $name (keys %$names) {
      $value = $name;
    }
  }

  return $value;
}


sub get_command_subs {
  my($self)  = shift;
  my(%valid) = ();

  ## Add the built-in OS compatibility commands
  if ($self->{'convert_slashes'}) {
    $valid{'cat'}   = 'type';
    $valid{'cp'}    = 'copy /y';
    $valid{'mkdir'} = 'mkdir';
    $valid{'mv'}    = 'move /y';
    $valid{'rm'}    = 'del /f/s/q';
    $valid{'nul'}   = 'nul';
  }
  else {
    $valid{'cat'}   = 'cat';
    $valid{'cp'}    = 'cp -f';
    $valid{'mkdir'} = 'mkdir -p';
    $valid{'mv'}    = 'mv -f';
    $valid{'rm'}    = 'rm -rf';
    $valid{'nul'}   = '/dev/null';
  }

  ## Add the project specific compatibility commands
  $valid{'gt'}    = $self->get_gt_symbol();
  $valid{'lt'}    = $self->get_lt_symbol();
  $valid{'and'}   = $self->get_and_symbol();
  $valid{'or'}    = $self->get_or_symbol();
  $valid{'quote'} = $self->get_quote_symbol();

  return \%valid;
}


sub convert_command_parameters {
  my($self)   = shift;
  my($str)    = shift;
  my($input)  = shift;
  my($output) = shift;
  my(%nowarn) = ();
  my(%valid)  = %{$self->{'command_subs'}};

  ## Add in the values that change for every call to this function
  $valid{'input'}     = $input;
  $valid{'output'}    = $output;
  $valid{'temporary'} = 'temp.$$$$.' . int(rand(0xffffffff));

  if (defined $input) {
    $valid{'input_basename'} = basename($input);
    $valid{'input_noext'}    = $input;
    $valid{'input_noext'}    =~ s/(\.[^\.]+)$//;
    $valid{'input_ext'}      = $1;
  }

  if (defined $output) {
    $valid{'output_basename'} = basename($output);
    $valid{'output_noext'}    = $output;
    $valid{'output_noext'}    =~ s/(\.[^\.]+)$//;
    $valid{'output_ext'}      = $1;
  }

  ## Add in the specific types of output files
  if (defined $output) {
    foreach my $type (keys %{$self->{'valid_components'}}) {
      my($key) = $type;
      $key =~ s/s$//gi;
      $nowarn{$key} = 1;
      $nowarn{$key . '_noext'} = 1;
      foreach my $ext (@{$self->{'valid_components'}->{$type}}) {
        if ($output =~ /$ext$/) {
          $valid{$key} = $output;
          $valid{$key . '_noext'} = $output;
          $valid{$key . '_noext'} =~ s/\.[^\.]+$//;
          last;
        }
      }
    }
  }

  while ($str =~ /<%(\w+)(\(\w+\))?%>/) {
    my($name)     = $1;
    my($modifier) = $2;
    if (defined $modifier) {
      my($tmp) = $name;
      $name = $modifier;
      $name =~ s/[\(\)]//g;
      $modifier = $tmp;
    }

    if (exists $valid{$name}) {
      if (defined $valid{$name}) {
        my($replace) = $valid{$name};
        if (defined $modifier) {
          if ($modifier eq 'noextension') {
            $replace =~ s/\.[^\.]+$//;
          }
          else {
            $self->warning("Uknown parameter modifier $modifier.");
          }
        }
        $str =~ s/<%\w+(\(\w+\))?%>/$replace/;
      }
      else {
        $str =~ s/<%\w+(\(\w+\))?%>//;
      }
    }
    else {
      $str =~ s/<%\w+(\(\w+\))?%>//;

      ## We only want to warn the user that we did not recognize the
      ## pseudo template parameter if there was an input and an output
      ## file passed to this function.  If this variable was used
      ## without the parenthesis (as in an if statement), then we don't
      ## want to warn the user.
      if (defined $input && defined $output) {
        if (!defined $nowarn{$name}) {
          $self->warning("<%$name%> was not recognized.");
        }

        ## If we didn't recognize the pseudo template parameter then
        ## we don't want to return anything back.
        return undef;
      }
    }
  }

  return $str;
}


sub get_custom_value {
  my($self)   = shift;
  my($cmd)    = shift;
  my($based)  = shift;
  my(@params) = @_;
  my($value)  = undef;

  if ($cmd eq 'input_files') {
    my(@array) = $self->get_component_list($based);
    $value = \@array;

    $self->{'custom_output_files'} = {};
    my(%vcomps) = ();
    foreach my $vc (keys %{$self->{'valid_components'}}) {
      my(@comps) = $self->get_component_list($vc);
      $vcomps{$vc} = \@comps;
    }
    $vcomps{$generic_key} = [];

    foreach my $input (@array) {
      my(@outputs) = ();
      my($ainput)  = $input;
      my($cinput)  = $input;

      ## Remove the extension
      $cinput =~ s/\.[^\.]+$//;

      ## If we are converting slashes,
      ## change them back for this parameter
      if ($self->{'convert_slashes'}) {
        $ainput =~ s/\\/\//g;
      }

      ## Add all of the output files
      foreach my $vc (keys %{$self->{'valid_components'}}, $generic_key) {
        push(@outputs,
             $self->check_custom_output($based, $cinput,
                                        $ainput, $vc, $vcomps{$vc}));
      }

      ## Add specially listed files avoiding duplicates
      if (defined $self->{'custom_special_output'}->{$ainput}) {
        foreach my $file (@{$self->{'custom_special_output'}->{$ainput}}) {
          my($found) = 0;
          foreach my $output (@outputs) {
            if ($output eq $file) {
              $found = 1;
              last;
            }
          }
          if (!$found) {
            push(@outputs, $file);
          }
        }
      }
      $self->{'custom_output_files'}->{$input} = \@outputs;
    }
  }
  elsif ($cmd eq 'output_files') {
    # Generate output files based on $based
    if (defined $self->{'custom_output_files'}) {
      $value = $self->{'custom_output_files'}->{$based};
    }
  }
  elsif ($cmd eq 'source_output_files') {
    # Generate source output files based on $based
    if (defined $self->{'custom_output_files'}) {
      $value = [];
      foreach my $file (@{$self->{'custom_output_files'}->{$based}}) {
        foreach my $ext (@{$self->{'valid_components'}->{'source_files'}}) {
          if ($file =~ /$ext$/) {
            push(@$value, $file);
            last;
          }
        }
      }
    }
  }
  elsif ($cmd eq 'non_source_output_files') {
    # Generate non source output files based on $based
    if (defined $self->{'custom_output_files'}) {
      $value = [];
      foreach my $file (@{$self->{'custom_output_files'}->{$based}}) {
        my($source) = 0;
        foreach my $ext (@{$self->{'valid_components'}->{'source_files'}}) {
          if ($file =~ /$ext$/) {
            $source = 1;
            last;
          }
        }
        if (!$source) {
          push(@$value, $file);
        }
      }
    }
  }
  elsif ($cmd eq 'inputexts') {
    my(@array) = @{$self->{'valid_components'}->{$based}};
    foreach my $val (@array) {
      $val =~ s/\\\.//g;
    }
    $value = \@array;
  }
  elsif (defined $customDefined{$cmd} &&
         ($customDefined{$cmd} & 0x04) != 0) {
    $value = $self->get_assignment($cmd,
                                   $self->{'generated_exts'}->{$based});
    if (defined $value && ($customDefined{$cmd} & 0x10) != 0) {
      $value = $self->convert_command_parameters($value, @params);
    }
  }
  elsif (defined $custom{$cmd}) {
    $value = $self->get_assignment($cmd,
                                   $self->{'generated_exts'}->{$based});
  }

  return $value;
}


sub check_features {
  my($self)     = shift;
  my($requires) = shift;
  my($avoids)   = shift;
  my($info)     = shift;
  my($status)   = 1;
  my($why)      = undef;

  if (defined $requires) {
    foreach my $require (split(/\s+/, $requires)) {
      my($fval) = $self->{'feature_parser'}->get_value($require);

      ## By default, if the feature is not listed, then it is enabled.
      if (defined $fval && !$fval) {
        $why = "requires $require";
        $status = 0;
        last;
      }
    }
  }

  ## If it passes the requires, then check the avoids
  if ($status) {
    if (defined $avoids) {
      foreach my $avoid (split(/\s+/, $avoids)) {
        my($fval) = $self->{'feature_parser'}->get_value($avoid);

        ## By default, if the feature is not listed, then it is enabled.
        if (!defined $fval || $fval) {
          $why = "avoids $avoid";
          $status = 0;
          last;
        }
      }
    }
  }

  if ($info && !$status) {
    $self->diagnostic("Skipping " . $self->get_assignment('project_name') .
                      " ($self->{'current_input'}), it $why.");
  }

  return $status;
}


sub need_to_write_project {
  my($self) = shift;

  foreach my $key ('source_files', 'resource_files',
                   keys %{$self->{'generated_exts'}}) {
    my($names) = $self->{$key};
    foreach my $name (keys %$names) {
      foreach my $key (keys %{$names->{$name}}) {
        if (defined $names->{$name}->{$key}->[0]) {
          return 1;
        }
      }
    }
  }

  return 0;
}


sub write_output_file {
  my($self)     = shift;
  my($name)     = shift;
  my($status)   = 0;
  my($error)    = undef;
  my($tover)    = $self->get_template_override();
  my($template) = (defined $tover ? $tover : $self->get_template());

  ## If the template files does not end in the template extension
  ## then we will add it on.
  if ($template !~ /$TemplateExtension$/) {
    $template = $template . ".$TemplateExtension";
  }

  ## If the template file does not contain a full path, then we
  ## will search through the include paths for it.
  my($tfile) = undef;
  if ($template =~ /^([a-z]:)?[\/\\]/i) {
    $tfile = $template;
  }
  else {
    $tfile = $self->search_include_path($template);
  }

  if (defined $tfile) {
    ## Read in the template values for the
    ## specific target and project type
    ($status, $error) = $self->read_template_input();

    if ($status) {
      my($tp) = new TemplateParser($self);

      ## Set the project_file assignment for the template parser
      $self->process_assignment('project_file', $name);

      ($status, $error) = $tp->parse_file($tfile);

      if ($status) {
        if (defined $self->{'source_callback'}) {
          my($cb)     = $self->{'source_callback'};
          my($pjname) = $self->get_assignment('project_name');
          my(@list)   = $self->get_component_list('source_files');
          if (UNIVERSAL::isa($cb, 'ARRAY')) {
            my(@copy) = @$cb;
            my($s) = shift(@copy);
            &$s(@copy, $name, $pjname, @list);
          }
          elsif (UNIVERSAL::isa($cb, 'CODE')) {
            &$cb($name, $pjname, @list);
          }
          else {
            $self->warning("Ignoring callback: $cb.");
          }
        }

        if ($self->get_toplevel()) {
          my($outdir) = $self->get_outdir();
          my($oname)  = $name;

          $name = "$outdir/$name";

          my($fh)  = new FileHandle();
          my($dir) = $self->mpc_dirname($name);

          if ($dir ne '.') {
            mkpath($dir, 0, 0777);
          }

          if ($self->compare_output()) {
            ## First write the output to a temporary file
            my($tmp) = "$outdir/MPC$>.$$";
            my($different) = 1;
            if (open($fh, ">$tmp")) {
              my($lines) = $tp->get_lines();
              foreach my $line (@$lines) {
                print $fh $line;
              }
              close($fh);

              if (-r $name &&
                  -s $tmp == -s $name && compare($tmp, $name) == 0) {
                $different = 0;
              }
            }
            else {
              $error = "Unable to open $tmp for output.";
              $status = 0;
            }

            if ($status) {
              ## If they are different, then rename the temporary file
              if ($different) {
                unlink($name);
                if (rename($tmp, $name)) {
                  $self->add_file_written($oname);
                }
                else {
                  $error = "Unable to open $name for output.";
                  $status = 0;
                }
              }
              else {
                ## We will pretend that we wrote the file
                unlink($tmp);
                $self->add_file_written($oname);
              }
            }
          }
          else {
            if (open($fh, ">$name")) {
              my($lines) = $tp->get_lines();
              foreach my $line (@$lines) {
                print $fh $line;
              }
              close($fh);
              $self->add_file_written($oname);
            }
            else {
              $error = "Unable to open $name for output.";
              $status = 0;
            }
          }
        }
      }
    }
  }
  else {
    $error = "Unable to locate the template file: $template.";
    $status = 0;
  }

  return $status, $error;
}


sub write_install_file {
  my($self)    = shift;
  my($fh)      = new FileHandle();
  my($insfile) = $self->transform_file_name(
                           $self->get_assignment('project_name')) .
                 '.ins';
  my($outdir)  = $self->get_outdir();

  $insfile = "$outdir/$insfile";

  unlink($insfile);
  if (open($fh, ">$insfile")) {
    foreach my $vc (keys %{$self->{'valid_components'}}) {
      my($names) = $self->{$vc};
      foreach my $name (keys %$names) {
        foreach my $key (keys %{$$names{$name}}) {
          my($array) = $$names{$name}->{$key};
          if (defined $$array[0]) {
            print $fh "$vc:\n";
            foreach my $file (@$array) {
              print $fh "$file\n";
            }
            print $fh "\n";
          }
        }
      }
    }
    if ($self->exe_target()) {
      my($install) = $self->get_assignment('install');
      print $fh "exe_output:\n",
                (defined $install ? $self->relative($install) : ''),
                ' ', $self->get_assignment('exename'), "\n";
    }
    elsif ($self->lib_target()) {
      my($shared) = $self->get_assignment('sharedname');
      my($static) = $self->get_assignment('staticname');
      my($dllout) = $self->relative($self->get_assignment('dllout'));
      my($libout) = $self->relative($self->get_assignment('libout'));

      print $fh "lib_output:\n";

      if (defined $shared && $shared ne '') {
        print $fh (defined $dllout ? $dllout : $libout), " $shared\n";
      }
      if ((defined $static && $static ne '') &&
          (defined $dllout || !defined $shared ||
               (defined $shared && $shared ne $static))) {
        print $fh "$libout $static\n";
      }
    }

    close($fh);
    return 1, undef;
  }

  return 0, 'Unable write to ' . $insfile;
}


sub write_project {
  my($self)      = shift;
  my($status)    = 1;
  my($error)     = undef;
  my($progress)  = $self->get_progress_callback();

  if (defined $progress) {
    &$progress();
  }

  if ($self->check_features($self->get_assignment('requires'),
                            $self->get_assignment('avoids'),
                            1)) {
    if ($self->need_to_write_project()) {
      if ($self->get_assignment('custom_only')) {
        $self->remove_non_custom_settings();
      }

      if ($self->{'escape_spaces'}) {
        foreach my $key (keys %{$self->{'valid_components'}}) {
          my($names) = $self->{$key};
          foreach my $name (keys %$names) {
            foreach my $key (keys %{$$names{$name}}) {
              foreach my $file (@{$$names{$name}->{$key}}) {
                $file =~ s/(\s)/\\$1/g;
              }
            }
          }
        }
      }

      ($status, $error) = $self->write_output_file(
                                   $self->transform_file_name(
                                            $self->project_file_name()));
      if ($self->{'generate_ins'} && $status) {
        ($status, $error) = $self->write_install_file();
      }
    }
    else {
      my($msg) = $self->transform_file_name($self->project_file_name()) .
                 " has no useful targets.";

      if ($self->{'current_input'} eq '') {
        $self->information($msg);
      }
      else {
        $self->warning($msg);
      }
    }
  }
  else {
    $status = 2;
  }

  return $status, $error;
}


sub get_project_info {
  my($self) = shift;
  return $self->{'project_info'};
}


sub get_lib_locations {
  my($self) = shift;
  return $self->{'lib_locations'};
}


sub get_inheritance_tree {
  my($self) = shift;
  return $self->{'inheritance_tree'};
}


sub set_component_extensions {
  my($self) = shift;
  my($vc)   = $self->{'valid_components'};
  my($ec)   = $self->{'exclude_components'};

  foreach my $key (keys %$vc) {
    my($ov) = $self->override_valid_component_extensions($key);
    if (defined $ov) {
      $$vc{$key} = $ov;
    }
  }

  foreach my $key (keys %$ec) {
    my($ov) = $self->override_exclude_component_extensions($key);
    if (defined $ov) {
      $$ec{$key} = $ov;
    }
  }
}


sub set_source_listing_callback {
  my($self) = shift;
  my($cb)   = shift;
  $self->{'source_callback'} = $cb;
}


sub reset_values {
  my($self) = shift;

  ## Only put data structures that need to be cleared
  ## out when the mpc file is done being read, not at the
  ## end of each project within the mpc file.
  $self->{'project_info'}  = [];
  $self->{'lib_locations'} = {};
}


sub add_default_matching_assignments {
  my($self) = shift;
  my($lang) = $self->get_language();
  foreach my $key (keys %{$language{$lang}->[0]}) {
    if (!defined $language{$lang}->[2]->{$key}) {
       $language{$lang}->[2]->{$key} = [];
      foreach my $keyword (@default_matching_assignments) {
        push(@{$language{$lang}->[2]->{$key}}, $keyword);
      }
    }
  }
}


sub reset_generating_types {
  my($self)  = shift;
  my($lang)  = $self->get_language();
  my(%reset) = ('valid_components'     => $language{$lang}->[0],
                'custom_only_removed'  => $language{$lang}->[0],
                'exclude_components'   => $language{$lang}->[1],
                'matching_assignments' => $language{$lang}->[2],
                'generated_exts'       => {},
                'valid_names'          => \%validNames,
               );

  foreach my $r (keys %reset) {
    $self->{$r} = {};
    foreach my $key (keys %{$reset{$r}}) {
      $self->{$r}->{$key} = $reset{$r}->{$key};
    }
  }

  $self->{'custom_types'} = {};

  ## Allow subclasses to override the default extensions
  $self->set_component_extensions();
}


sub get_template_input {
  my($self) = shift;

  ## This follows along the same logic as read_template_input() by
  ## checking for exe target and then defaulting to a lib target
  if ($self->exe_target()) {
    if ($self->get_static() == 1) {
      return $self->{'lexe_template_input'};
    }
    else {
      return $self->{'dexe_template_input'};
    }
  }

  if ($self->get_static() == 1) {
    return $self->{'lib_template_input'};
  }
  else {
    return $self->{'dll_template_input'};
  }
}


sub update_project_info {
  my($self)    = shift;
  my($tparser) = shift;
  my($append)  = shift;
  my($names)   = shift;
  my($sep)     = shift;
  my($pi)      = $self->get_project_info();
  my($value)   = '';
  my($arr)     = ($append && defined $$pi[0] ? pop(@$pi) : []);

  ## Set up the hash table when we are starting a new project_info
  if ($append == 0) {
    $self->{'project_info_hash_table'} = {};
  }

  ## Append the values of all names into one string
  my(@narr) = @$names;
  for(my $i = 0; $i <= $#narr; $i++) {
    my($key) = $narr[$i];
    $value .= $self->translate_value($key,
                                     $tparser->get_value_with_default($key)) .
              (defined $sep && $i != $#narr ? $sep : '');
  }

  ## If we haven't seen this value yet, put it on the array
  if (!defined $self->{'project_info_hash_table'}->{"@narr $value"}) {
    $self->{'project_info_hash_table'}->{"@narr $value"} = 1;
    #$self->save_project_value("@narr", $value);
    push(@$arr, $value);
  }

  ## Always push the array back onto the project_info
  push(@$pi, $arr);

  return $value;
}


sub adjust_value {
  my($self)  = shift;
  my($names) = shift;
  my($value) = shift;
  my($atemp) = $self->get_addtemp();

  ## Perform any additions, subtractions
  ## or overrides for the template values.
  foreach my $name (@$names) {
    if (defined $name && defined $atemp->{lc($name)}) {
      my($addtemparr) = $atemp->{lc($name)};
      foreach my $val (@$addtemparr) {
        my($arr) = $self->create_array($$val[1]);
        if ($$val[0] > 0) {
          if (UNIVERSAL::isa($value, 'ARRAY')) {
            ## We need to make $value a new array reference ($arr)
            ## to avoid modifying the array reference pointed to by $value
            unshift(@$arr, @$value);
            $value = $arr;
          }
          else {
            $value .= " $$val[1]";
          }
        }
        elsif ($$val[0] < 0) {
          my($parts) = undef;
          if (UNIVERSAL::isa($value, 'ARRAY')) {
            $parts = $value;
          }
          else {
            $parts = $self->create_array($value);
          }

          $value = [];
          foreach my $part (@$parts) {
            if ($part ne '') {
              my($found) = 0;
              foreach my $ae (@$arr) {
                if ($part eq $ae) {
                  $found = 1;
                  last;
                }
              }
              if (!$found) {
                push(@$value, $part);
              }
            }
          }
        }
        else {
          $value = $arr;
        }
      }
      last;
    }
  }

  return $value;
}


sub relative {
  my($self)            = shift;
  my($value)           = shift;
  my($expand_template) = shift;
  my($scope)           = shift;

  if (defined $value) {
    if (UNIVERSAL::isa($value, 'ARRAY')) {
      my(@built) = ();
      foreach my $val (@$value) {
        push(@built, $self->relative($val, $expand_template, $scope));
      }
      $value = \@built;
    }
    elsif ($value =~ /\$/) {
      my($useenv) = $self->get_use_env();
      my($expand) = $self->get_expand_vars();
      my($rel)    = ($useenv ? \%ENV : $self->get_relative());
      my(@keys)   = keys %$rel;

      if (defined $keys[0]) {
        my($cwd)   = $self->getcwd();
        my($start) = 0;

        while(substr($value, $start) =~ /(\$\(([^)]+)\))/) {
          my($whole)  = $1;
          my($name)   = $2;
          my($val)    = $$rel{$name};

          if (defined $val) {
            if ($expand) {
              if ($self->{'convert_slashes'}) {
                $val = $self->slash_to_backslash($val);
              }
              substr($value, $start) =~ s/\$\([^)]+\)/$val/;
              $whole = $val;
            }
            else {
              ## Fix up the value for Windows switch the \\'s to /
              if ($self->{'convert_slashes'}) {
                $val =~ s/\\/\//g;
              }

              ## Here we make an assumption that if we convert slashes to
              ## back-slashes, we also have a case-insensitive file system.
              my($icwd) = ($self->{'convert_slashes'} ? lc($cwd) : $cwd);
              my($ival) = ($self->{'convert_slashes'} ? lc($val) : $val);
              my($iclen) = length($icwd);
              my($ivlen) = length($ival);

              ## If the relative value contains the current working
              ## directory plus additional subdirectories, we must pull
              ## off the additional directories into a temporary where
              ## it can be put back after the relative replacement is done.
              my($append) = undef;
              if (index($ival, $icwd) == 0 && $iclen != $ivlen &&
                  substr($ival, $iclen, 1) eq '/') {
                my($diff) = $ivlen - $iclen;
                $append = substr($ival, $iclen);
                substr($ival, $iclen, $diff) = '';
                $ivlen -= $diff;
              }

              if (index($icwd, $ival) == 0 &&
                  ($iclen == $ivlen || substr($icwd, $ivlen, 1) eq '/')) {
                my($current) = $icwd;
                substr($current, 0, $ivlen) = '';

                my($dircount) = ($current =~ tr/\///);
                if ($dircount == 0) {
                  $ival = '.';
                }
                else {
                  $ival = '../' x $dircount;
                  $ival =~ s/\/$//;
                }
                if (defined $append) {
                  $ival .= $append;
                }
                if ($self->{'convert_slashes'}) {
                  $ival = $self->slash_to_backslash($ival);
                }
                substr($value, $start) =~ s/\$\([^)]+\)/$ival/;
                $whole = $ival;
              }
            }
          }
          elsif ($expand_template ||
                 $self->expand_variables_from_template_values()) {
            my($ti) = $self->get_template_input();
            if (defined $ti) {
              $val = $ti->get_value($name);
            }
            my($sname) = (defined $scope ? $scope . "::$name" : undef);
            my($arr) = $self->adjust_value([$sname, $name],
                                           (defined $val ? $val : []));
            if (defined $$arr[0]) {
              $val = "@$arr";
              if ($self->{'convert_slashes'}) {
                $val = $self->slash_to_backslash($val);
              }
              substr($value, $start) =~ s/\$\([^)]+\)/$val/;

              ## We have replaced the template value, but that template
              ## value may contain a $() construct that may need to get
              ## replaced too.
              $whole = '';
            }
            else {
              if ($expand) {
                $self->warning("Unable to expand $name.");
              }
            }
          }
          $start += length($whole);
        }
      }
    }
  }

  return $value;
}


sub get_verbatim {
  my($self)   = shift;
  my($marker) = shift;
  my($str)    = undef;
  my($thash)  = $self->{'verbatim'}->{$self->{'pctype'}};

  if (defined $thash) {
    if (defined $thash->{$marker}) {
      my($crlf) = $self->crlf();
      foreach my $line (@{$thash->{$marker}}) {
        if (!defined $str) {
          $str = '';
        }
        $str .= $self->process_special($line) . $crlf;
      }
      if (defined $str) {
        $str .= $crlf;
        $self->{'verbatim_accessed'}->{$self->{'pctype'}}->{$marker} = 1;
      }
    }
  }

  return $str;
}


sub generate_recursive_input_list {
  my($self)    = shift;
  my($dir)     = shift;
  my($exclude) = shift;
  return $self->extension_recursive_input_list($dir,
                                               $exclude,
                                               $ProjectCreatorExtension);
}


sub get_default_element_name {
  #my($self) = shift;
  return 'default_group';
}


sub get_modified_project_file_name {
  my($self) = shift;
  my($name) = shift;
  my($ext)  = shift;
  my($nmod) = $self->get_name_modifier();

  ## We don't apply the name modifier to the project file
  ## name if we have already applied it to the project name
  ## since the project file name comes from the project name.
  if (defined $nmod && !$self->get_apply_project()) {
    $nmod =~ s/\*/$name/g;
    $name = $nmod;
  }
  return "$name$ext";
}


sub get_valid_names {
  my($self) = shift;
  return $self->{'valid_names'};
}


sub preserve_assignment_order {
  my($self) = shift;
  my($name) = shift;
  my($mapped) = $self->{'valid_names'}->{$name};

  ## Only return the value stored in the valid_names hash map if it's
  ## defined and it's not an array reference.  The array reference is
  ## a keyword mapping and all mapped keywords should have preserved
  ## assignment order.
  if (defined $mapped && !UNIVERSAL::isa($mapped, 'ARRAY')) {
    return ($mapped & 1);
  }

  return 1;
}


sub add_to_template_input_value {
  my($self) = shift;
  my($name) = shift;
  my($mapped) = $self->{'valid_names'}->{$name};

  ## Only return the value stored in the valid_names hash map if it's
  ## defined and it's not an array reference.  The array reference is
  ## a keyword mapping and no mapped keywords should be added to
  ## template input variables.
  if (defined $mapped && !UNIVERSAL::isa($mapped, 'ARRAY')) {
    return ($mapped & 2);
  }

  return 0;
}


sub dependency_combined_static_library {
  #my($self) = shift;
  return defined $ENV{MPC_DEPENDENCY_COMBINED_STATIC_LIBRARY};
}


sub translate_value {
  my($self) = shift;
  my($key)  = shift;
  my($val)  = shift;

  if ($key eq 'after' && $val ne '') {
    my($arr) = $self->create_array($val);
    $val = '';

    if ($self->require_dependencies()) {
      foreach my $entry (@$arr) {
        if ($self->get_apply_project()) {
          my($nmod) = $self->get_name_modifier();
          if (defined $nmod) {
            $nmod =~ s/\*/$entry/g;
            $entry = $nmod;
          }
        }
        $val .= '"' . ($self->dependency_is_filename() ?
                          $self->project_file_name($entry) : $entry) . '" ';
      }
      $val =~ s/\s+$//;
    }
  }
  return $val;
}


sub requires_parameters {
  my($self) = shift;
  my($name) = shift;
  return $custom{$name};
}


sub project_file_name {
  my($self) = shift;
  my($name) = shift;

  if (!defined $name) {
    $name = $self->project_name();
  }

  return $self->get_modified_project_file_name(
                                     $name,
                                     $self->project_file_extension());
}


sub remove_non_custom_settings {
  my($self) = shift;

  ## Remove any files that may have automatically been added
  ## to this project
  foreach my $key (keys %{$self->{'custom_only_removed'}}) {
    $self->{$key} = {};
  }

  ## Unset the exename, sharedname and staticname
  $self->process_assignment('exename',    undef);
  $self->process_assignment('sharedname', undef);
  $self->process_assignment('staticname', undef);
}

# ************************************************************
# Virtual Methods To Be Overridden
# ************************************************************

sub escape_spaces {
  #my($self) = shift;
  return 0;
}


sub validated_directory {
  my($self) = shift;
  my($dir)  = shift;
  return $dir;
}

sub get_quote_symbol {
  #my($self) = shift;
  return '"';
}

sub get_gt_symbol {
  #my($self) = shift;
  return '>';
}


sub get_lt_symbol {
  #my($self) = shift;
  return '<';
}


sub get_and_symbol {
  #my($self) = shift;
  return '&&';
}


sub get_or_symbol {
  #my($self) = shift;
  return '||';
}


sub dollar_special {
  #my($self) = shift;
  return 0;
}


sub expand_variables_from_template_values {
  #my($self) = shift;
  return 1;
}


sub require_dependencies {
  #my($self) = shift;
  return 1;
}


sub dependency_is_filename {
  #my($self) = shift;
  return 1;
}


sub fill_value {
  #my($self) = shift;
  #my($name) = shift;
  return undef;
}


sub project_file_extension {
  #my($self) = shift;
  return '';
}


sub override_valid_component_extensions {
  #my($self) = shift;
  #my($comp) = shift;
  return undef;
}


sub override_exclude_component_extensions {
  #my($self) = shift;
  #my($comp) = shift;
  return undef;
}


sub get_dll_exe_template_input_file {
  #my($self) = shift;
  return undef;
}


sub get_lib_exe_template_input_file {
  my($self) = shift;
  return $self->get_dll_exe_template_input_file();
}


sub get_lib_template_input_file {
  my($self) = shift;
  return $self->get_dll_template_input_file();
}


sub get_dll_template_input_file {
  #my($self) = shift;
  return undef;
}


sub get_template {
  #my($self) = shift;
  return undef;
}


1;
