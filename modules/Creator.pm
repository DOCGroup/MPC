package Creator;

# ************************************************************
# Description   : Base class for workspace and project creators
# Author        : Chad Elliott
# Create Date   : 5/13/2002
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;
use FileHandle;

use Parser;

use vars qw(@ISA);
@ISA = qw(Parser);

# ************************************************************
# Data Section
# ************************************************************

my($assign_key)  = 'assign';
my($gassign_key) = 'global_assign';
my(%non_convert) = ('prebuild' => 1,
                    'postbuild' => 1,
                   );
my(@statekeys) = ('global', 'include', 'template', 'ti',
                  'dynamic', 'static', 'relative', 'addtemp',
                  'addproj', 'progress', 'toplevel', 'baseprojs',
                  'features', 'feature_file', 'hierarchy',
                  'name_modifier', 'apply_project', 'into', 'use_env',
                  'expand_vars', 'language',
                 );

my(%all_written) = ();
my($onVMS) = DirectoryManager::onVMS();

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
  my($feature)    = shift;
  my($features)   = shift;
  my($hierarchy)  = shift;
  my($nmodifier)  = shift;
  my($applypj)    = shift;
  my($into)       = shift;
  my($language)   = shift;
  my($use_env)    = shift;
  my($expandvars) = shift;
  my($type)       = shift;
  my($self)       = Parser::new($class, $inc);

  $self->{'relative'}        = $relative;
  $self->{'template'}        = $template;
  $self->{'ti'}              = $ti;
  $self->{'global'}          = $global;
  $self->{'grammar_type'}    = $type;
  $self->{'type_check'}      = $type . '_defined';
  $self->{'global_read'}     = 0;
  $self->{'current_input'}   = '';
  $self->{'progress'}        = $progress;
  $self->{'addtemp'}         = $addtemp;
  $self->{'addproj'}         = $addproj;
  $self->{'toplevel'}        = $toplevel;
  $self->{'files_written'}   = {};
  $self->{'real_fwritten'}   = [];
  $self->{'reading_global'}  = 0;
  $self->{$gassign_key}      = {};
  $self->{$assign_key}       = {};
  $self->{'baseprojs'}       = $baseprojs;
  $self->{'dynamic'}         = $dynamic;
  $self->{'static'}          = $static;
  $self->{'feature_file'}    = $feature;
  $self->{'features'}        = $features;
  $self->{'hierarchy'}       = $hierarchy;
  $self->{'name_modifier'}   = $nmodifier;
  $self->{'apply_project'}   = $applypj;
  $self->{'into'}            = $into;
  $self->{'language'}        = $language;
  $self->{'use_env'}         = $use_env;
  $self->{'expand_vars'}     = $expandvars;
  $self->{'convert_slashes'} = $self->convert_slashes();
  $self->{'case_tolerant'}   = $self->case_insensitive();

  return $self;
}


sub preprocess_line {
  my($self) = shift;
  my($fh)   = shift;
  my($line) = shift;

  $line = $self->strip_line($line);
  while ($line =~ /\\$/) {
    $line =~ s/\s*\\$/ /;
    my($next) = $fh->getline();
    if (defined $next) {
      $line .= $self->strip_line($next);
    }
  }
  return $line;
}


sub generate_default_input {
  my($self)  = shift;
  my($status,
     $error) = $self->parse_line(undef, "$self->{'grammar_type'} {");

  if ($status) {
    ($status, $error) = $self->parse_line(undef, '}');
  }

  if (!$status) {
    $self->error($error);
  }

  return $status;
}


sub parse_file {
  my($self)  = shift;
  my($input) = shift;
  my($oline) = $self->get_line_number();

  ## Read the input file and get the last line number
  my($status, $errorString) = $self->read_file($input);

  if (!$status) {
    $self->error($errorString,
                 "$input: line " . $self->get_line_number() . ':');
  }
  elsif ($self->{$self->{'type_check'}}) {
    ## If we are at the end of the file and the type we are looking at
    ## is still defined, then we have an error
    $self->error("Did not " .
                 "find the end of the $self->{'grammar_type'}",
                 "$input: line " . $self->get_line_number() . ':');
    $status = 0;
  }
  $self->set_line_number($oline);

  return $status;
}


sub generate {
  my($self)   = shift;
  my($input)  = shift;
  my($status) = 1;

  ## Reset the files_written hash array between processing each file
  $self->{'files_written'} = {};
  $self->{'real_fwritten'} = [];

  ## Allow subclasses to reset values before
  ## each call to generate().
  $self->reset_values();

  ## Read the global configuration file
  if (!$self->{'global_read'}) {
    $status = $self->read_global_configuration();
    $self->{'global_read'} = 1;
  }

  if ($status) {
    $self->{'current_input'} = $input;

    ## An empty input file name says that we
    ## should generate a default input file and use that
    if ($input eq '') {
      $status = $self->generate_default_input();
    }
    else {
      $status = $self->parse_file($input);
    }
  }

  return $status;
}


sub parse_known {
  my($self)        = shift;
  my($line)        = shift;
  my($status)      = 1;
  my($errorString) = undef;
  my($type)        = $self->{'grammar_type'};
  my(@values)      = ();

  ##
  ## Each regexp that looks for the '{' looks for it at the
  ## end of the line.  It is purposely this way to decrease
  ## the amount of extra lines in each file.  This
  ## allows for the most compact file as human readably
  ## possible.
  ##
  if ($line eq '') {
  }
  elsif ($line =~ /^$type\s*(\([^\)]+\))?\s*(:.*)?\s*{$/) {
    my($name)    = $1;
    my($parents) = $2;
    if ($self->{$self->{'type_check'}}) {
      $errorString = "Did not find the end of the $type";
      $status = 0;
    }
    else {
      if (defined $parents) {
        $parents =~ s/^:\s*//;
        $parents =~ s/\s+$//;
        my(@parents) = split(/\s*,\s*/, $parents);
        if (!defined $parents[0]) {
          ## The : was used, but no parents followed.  This
          ## is an error.
          $errorString = 'No parents listed';
          $status = 0;
        }
        $parents = \@parents;
      }
      push(@values, $type, $name, $parents);
    }
  }
  elsif ($line =~ /^}$/) {
    if ($self->{$self->{'type_check'}}) {
      push(@values, $type, $line);
    }
    else {
      $errorString = "Did not find the beginning of the $type";
      $status = 0;
    }
  }
  elsif ($line =~ /^(feature)\s*\(([^\)]+)\)\s*(:.*)?\s*{$/) {
    my($type)    = $1;
    my($name)    = $2;
    my($parents) = $3;
    my(@names)   = split(/\s*,\s*/, $name);

    if (defined $parents) {
      $parents =~ s/^:\s*//;
      $parents =~ s/\s+$//;
      my(@parents) = split(/\s*,\s*/, $parents);
      if (!defined $parents[0]) {
        ## The : was used, but no parents followed.  This
        ## is an error.
        $errorString = 'No parents listed';
        $status = 0;
      }
      $parents = \@parents;
    }
    push(@values, $type, \@names, $parents);
  }
  elsif (!$self->{$self->{'type_check'}}) {
    $errorString = "No $type was defined";
    $status = 0;
  }
  elsif ($self->parse_assignment($line, \@values)) {
    ## If this returns true, then we've found an assignment
  }
  elsif ($line =~ /^(\w+)\s*(\([^\)]+\))?\s*{$/) {
    my($comp) = lc($1);
    my($name) = $2;

    if (defined $name) {
      $name =~ s/^\(\s*//;
      $name =~ s/\s*\)$//;
    }
    else {
      $name = $self->get_default_component_name();
    }
    push(@values, 'component', $comp, $name);
  }
  else {
    $errorString = "Unrecognized line: $line";
    $status = -1;
  }

  return $status, $errorString, @values;
}


sub parse_scope {
  my($self)        = shift;
  my($fh)          = shift;
  my($name)        = shift;
  my($type)        = shift;
  my($validNames)  = shift;
  my($flags)       = shift;
  my($elseflags)   = shift;
  my($status)      = 0;
  my($errorString) = "Unable to process $name";

  if (!defined $flags) {
    $flags = {};
  }

  while(<$fh>) {
    my($line) = $self->preprocess_line($fh, $_);

    if ($line eq '') {
    }
    elsif ($line =~ /^}$/) {
      ($status, $errorString) = $self->handle_scoped_end($type, $flags);
      last;
    }
    elsif ($line =~ /^}\s*else\s*{$/) {
      if (defined $elseflags) {
        ## From here on out anything after this goes into the $elseflags
        $flags = $elseflags;
        $elseflags = undef;

        ## We need to adjust the type also.  If there was a type
        ## then the first part of the clause was used.  If there was
        ## no type, then the first part was ignored and the second
        ## part will be used.
        if (defined $type) {
          $type = undef;
        }
        else {
          $type = $self->get_default_component_name();
        }
      }
      else {
        $status = 0;
        $errorString = 'An else is not allowed in this context';
        last;
      }
    }
    else {
      my(@values) = ();
      if (defined $validNames && $self->parse_assignment($line, \@values)) {
        if (defined $$validNames{$values[1]}) {
          ## If $type is not defined, we don't even need to bother with
          ## processing the assignment as we will be throwing the value
          ## away anyway.
          if (defined $type) {
            if ($values[0] == 0) {
              $self->process_assignment($values[1], $values[2], $flags);
            }
            elsif ($values[0] == 1) {
              $self->process_assignment_add($values[1], $values[2], $flags);
            }
            elsif ($values[0] == -1) {
              $self->process_assignment_sub($values[1], $values[2], $flags);
            }
          }
        }
        else {
          ($status,
           $errorString) = $self->handle_unknown_assignment($type,
                                                            @values);
          if (!$status) {
            last;
          }
        }
      }
      else {
        ($status, $errorString) = $self->handle_scoped_unknown($fh,
                                                               $type,
                                                               $flags,
                                                               $line);
        if (!$status) {
          last;
        }
      }
    }
  }
  return $status, $errorString;
}


sub base_directory {
  my($self) = shift;
  return $self->mpc_basename($self->getcwd());
}


sub generate_default_file_list {
  my($self)    = shift;
  my($dir)     = shift;
  my($exclude) = shift;
  my($fileexc) = shift;
  my($recurse) = shift;
  my($dh)      = new FileHandle();
  my(@files)   = ();

  if (opendir($dh, $dir)) {
    my($prefix)   = ($dir ne '.' ? "$dir/" : '');
    my($have_exc) = (defined $$exclude[0]);
    my($skip)     = 0;
    foreach my $file (grep(!/^\.\.?$/,
                           ($onVMS ? map {$_ =~ s/\.dir$//; $_} readdir($dh) :
                                     readdir($dh)))) {
      ## Prefix each file name with the directory only if it's not '.'
      my($full) = $prefix . $file;

      if ($have_exc) {
        foreach my $exc (@$exclude) {
          if ($full eq $exc) {
            $skip = 1;
            last;
          }
        }
      }

      if ($skip) {
        $skip = 0;
        $$fileexc = 1 if (defined $fileexc);
      }
      else {
        if ($recurse && -d $full) {
          push(@files,
               $self->generate_default_file_list($full, $exclude,
                                                 $fileexc, $recurse));
        }
        else {
          push(@files, $full);
        }
      }
    }

    if ($self->sort_files()) {
      @files = sort { $self->file_sorter($a, $b) } @files;
    }

    closedir($dh);
  }
  return @files;
}


sub transform_file_name {
  my($self) = shift;
  my($name) = shift;

  $name =~ s/[\s\-]/_/g;
  return $name;
}


sub file_written {
  my($self) = shift;
  my($file) = shift;
  return (defined $all_written{$self->getcwd() . '/' . $file});
}


sub add_file_written {
  my($self) = shift;
  my($file) = shift;
  my($key)  = lc($file);

  if (defined $self->{'files_written'}->{$key}) {
    $self->warning("$self->{'grammar_type'} $file " .
                   ($self->{'case_tolerant'} ?
                           "has been overwritten." :
                           "of differing case has been processed."));
  }
  else {
    $self->{'files_written'}->{$key} = $file;
    push(@{$self->{'real_fwritten'}}, $file);
  }

  $all_written{$self->getcwd() . '/' . $file} = 1;
}


sub extension_recursive_input_list {
  my($self)    = shift;
  my($dir)     = shift;
  my($exclude) = shift;
  my($ext)     = shift;
  my($fh)      = new FileHandle();
  my(@files)   = ();

  if (opendir($fh, $dir)) {
    my($prefix) = ($dir ne '.' ? "$dir/" : '');
    my($skip)   = 0;
    foreach my $file (grep(!/^\.\.?$/,
                           ($onVMS ? map {$_ =~ s/\.dir$//; $_} readdir($fh) :
                                     readdir($fh)))) {
      my($full) = $prefix . $file;

      ## Check for command line exclusions
      if (defined $$exclude[0]) {
        foreach my $exc (@$exclude) {
          if ($full eq $exc) {
            $skip = 1;
            last;
          }
        }
      }

      ## If we are not skipping this directory or file, then check it out
      if ($skip) {
        $skip = 0;
      }
      else {
        if (-d $full) {
          push(@files, $self->extension_recursive_input_list($full,
                                                             $exclude,
                                                             $ext));
        }
        elsif ($full =~ /$ext$/) {
          push(@files, $full);
        }
      }
    }
    closedir($fh);
  }

  return @files;
}


sub modify_assignment_value {
  my($self)  = shift;
  my($name)  = shift;
  my($value) = shift;

  if ($self->{'convert_slashes'} &&
      index($name, 'flags') == -1 && !defined $non_convert{$name}) {
    $value =~ s/\//\\/g;
  }
  return $value;
}


sub get_assignment_hash {
  ## NOTE: If anything in this block changes, then you must make the
  ## same change in process_assignment.
  my($self) = shift;
  return $self->{$self->{'reading_global'} ? $gassign_key : $assign_key};
}


sub process_assignment {
  my($self)   = shift;
  my($name)   = shift;
  my($value)  = shift;
  my($assign) = shift;

  ## If no hash table was passed in
  if (!defined $assign) {
    ## NOTE: If anything in this block changes, then you must make the
    ## same change in get_assignment_hash.
    $assign = $self->{$self->{'reading_global'} ?
                               $gassign_key : $assign_key};
  }

  if (defined $value) {
    $value =~ s/^\s+//;
    $value =~ s/\s+$//;

    ## Modify the assignment value before saving it
    $$assign{$name} = $self->modify_assignment_value($name, $value);
  }
  else {
    $$assign{$name} = undef;
  }
}


sub addition_core {
  my($self)   = shift;
  my($name)   = shift;
  my($value)  = shift;
  my($nval)   = shift;
  my($assign) = shift;

  if (defined $nval) {
    if ($self->preserve_assignment_order($name)) {
      $nval .= " $value";
    }
    else {
      $nval = "$value $nval";
    }
  }
  else {
    $nval = $value;
  }
  $self->process_assignment($name, $nval, $assign, 1);
}


sub process_assignment_add {
  my($self)   = shift;
  my($name)   = shift;
  my($value)  = shift;
  my($assign) = shift;
  my($nval)   = $self->get_assignment_for_modification($name, $assign);

  ## Remove all duplicate parts from the value to be added.
  ## Whether anything gets removed or not is up to the implementation
  ## of the sub classes.
  $value = $self->remove_duplicate_addition($name, $value, $nval);

  ## If there is anything to add, then do so
  if ($value ne '') {
    $self->addition_core($name, $value, $nval, $assign);
  }
}


sub subtraction_core {
  my($self)   = shift;
  my($name)   = shift;
  my($value)  = shift;
  my($nval)   = shift;
  my($assign) = shift;

  if (defined $nval) {
    my($last)  = 1;
    my($found) = undef;

    ## Escape any regular expression special characters
    $value = $self->escape_regex_special($value);

    for(my $i = 0; $i <= $last; $i++) {
      if ($i == $last) {
        ## If we did not find the string to subtract in the original
        ## value, try again after expanding template variables for
        ## subtraction.
        $nval = $self->get_assignment_for_modification($name, $assign, 1);
      }
      for(my $j = 0; $j <= $last; $j++) {
        ## First try with quotes, then try again without them
        my($re) = ($j == 0 ? '"' . $value . '"' : $value);

        if ($nval =~ s/\s+$re\s+/ / || $nval =~ s/\s+$re$// ||
            $nval =~ s/^$re\s+//    || $nval =~ s/^$re$//) {
          $self->process_assignment($name, $nval, $assign, -1);
          $found = 1;
          last;
        }
      }
      last if ($found);
    }
  }
}


sub process_assignment_sub {
  my($self)   = shift;
  my($name)   = shift;
  my($value)  = shift;
  my($assign) = shift;
  my($nval)   = $self->get_assignment_for_modification($name, $assign);

  ## Remove double quotes if there are any
  $value =~ s/^\"(.*)\"$/$1/;

  $self->subtraction_core($name, $value, $nval, $assign);
}


sub fill_type_name {
  my($self)  = shift;
  my($names) = shift;
  my($def)   = shift;
  my($array) = ($names =~ /\s/ ? $self->create_array($names) : [$names]);

  $names = '';
  foreach my $name (@$array) {
    if ($name =~ /\*/) {
      my($pre)  = $def . '_';
      my($mid)  = '_' . $def . '_';
      my($post) = '_' . $def;

      ## Replace the beginning and end first then the middle
      $name =~ s/^\*/$pre/;
      $name =~ s/\*$/$post/;
      $name =~ s/\*/$mid/g;

      ## Remove any trailing underscore or any underscore that is followed
      ## by a space.  This value could be a space separated list.
      $name =~ s/_$//;
      $name =~ s/_\s/ /g;
      $name =~ s/\s_/ /g;

      ## If any one word is capitalized then capitalize each word
      if ($name =~ /[A-Z][0-9a-z_]+/) {
        ## Do the first word
        if ($name =~ /^([a-z])([^_]+)/) {
          my($first) = uc($1);
          my($rest)  = $2;
          $name =~ s/^[a-z][^_]+/$first$rest/;
        }
        ## Do subsequent words
        while($name =~ /(_[a-z])([^_]+)/) {
          my($first) = uc($1);
          my($rest)  = $2;
          $name =~ s/_[a-z][^_]+/$first$rest/;
        }
      }
    }

    $names .= $name . ' ';
  }
  $names =~ s/\s+$//;

  return $names;
}


sub save_state {
  my($self)     = shift;
  my($selected) = shift;
  my(%state)    = ();

  ## Make a deep copy of each state value.  That way our array
  ## references and hash references do not get accidentally modified.
  foreach my $skey (defined $selected ? $selected : @statekeys) {
    if (defined $self->{$skey}) {
      if (UNIVERSAL::isa($self->{$skey}, 'ARRAY')) {
        $state{$skey} = [];
        foreach my $element (@{$self->{$skey}}) {
          push(@{$state{$skey}}, $element);
        }
      }
      elsif (UNIVERSAL::isa($self->{$skey}, 'HASH')) {
        $state{$skey} = {};
        foreach my $key (keys %{$self->{$skey}}) {
          $state{$skey}->{$key} = $self->{$skey}->{$key};
        }
      }
      else {
        $state{$skey} = $self->{$skey};
      }
    }
  }

  return %state;
}


sub restore_state {
  my($self)     = shift;
  my($state)    = shift;
  my($selected) = shift;

  ## Make a deep copy of each state value.  That way our array
  ## references and hash references do not get accidentally modified.
  foreach my $skey (defined $selected ? $selected : @statekeys) {
    my($old) = $self->{$skey};
    if (defined $state->{$skey} &&
        UNIVERSAL::isa($state->{$skey}, 'ARRAY')) {
      my(@arr) = @{$state->{$skey}};
      $self->{$skey} = \@arr;
    }
    elsif (defined $state->{$skey} &&
           UNIVERSAL::isa($state->{$skey}, 'HASH')) {
      my(%hash) = %{$state->{$skey}};
      $self->{$skey} = \%hash;
    }
    else {
      $self->{$skey} = $state->{$skey};
    }
    $self->restore_state_helper($skey, $old, $self->{$skey});
  }
}


sub get_global_cfg {
  my($self) = shift;
  return $self->{'global'};
}


sub get_template_override {
  my($self) = shift;
  return $self->{'template'};
}


sub get_ti_override {
  my($self) = shift;
  return $self->{'ti'};
}


sub get_relative {
  my($self) = shift;
  return $self->{'relative'};
}


sub get_progress_callback {
  my($self) = shift;
  return $self->{'progress'};
}


sub get_addtemp {
  my($self) = shift;
  return $self->{'addtemp'};
}


sub get_addproj {
  my($self) = shift;
  return $self->{'addproj'};
}


sub get_toplevel {
  my($self) = shift;
  return $self->{'toplevel'};
}


sub get_into {
  my($self) = shift;
  return $self->{'into'};
}


sub get_use_env {
  my($self) = shift;
  return $self->{'use_env'};
}


sub get_expand_vars {
  my($self) = shift;
  return $self->{'expand_vars'};
}


sub get_files_written {
  my($self)  = shift;
  return $self->{'real_fwritten'};
}


sub get_assignment {
  my($self)   = shift;
  my($name)   = $self->resolve_alias(shift);
  my($assign) = shift;

  ## If no hash table was passed in
  if (!defined $assign) {
    $assign = $self->{$self->{'reading_global'} ?
                              $gassign_key : $assign_key};
  }

  return $$assign{$name};
}


sub get_assignment_for_modification {
  my($self)        = shift;
  my($name)        = shift;
  my($assign)      = shift;
  my($subtraction) = shift;
  return $self->get_assignment($name, $assign);
}


sub get_baseprojs {
  my($self) = shift;
  return $self->{'baseprojs'};
}


sub get_dynamic {
  my($self) = shift;
  return $self->{'dynamic'};
}


sub get_static {
  my($self) = shift;
  return $self->{'static'};
}


sub get_default_component_name {
  #my($self) = shift;
  return 'default';
}


sub get_features {
  my($self) = shift;
  return $self->{'features'};
}


sub get_hierarchy {
  my($self) = shift;
  return $self->{'hierarchy'};
}


sub get_name_modifier {
  my($self) = shift;
  return $self->{'name_modifier'};
}


sub get_apply_project {
  my($self) = shift;
  return $self->{'apply_project'};
}


sub get_language {
  my($self) = shift;
  return $self->{'language'};
}


sub get_outdir {
  my($self) = shift;
  if (defined $self->{'into'}) {
    my($outdir) = $self->getcwd();
    my($re)     = $self->escape_regex_special($self->getstartdir());

    $outdir =~ s/^$re//;
    return $self->{'into'} . $outdir;
  }
  else {
    return '.';
  }
}


sub expand_variables {
  my($self)            = shift;
  my($value)           = shift;
  my($rel)             = shift;
  my($expand_template) = shift;
  my($scope)           = shift;
  my($expand)          = shift;
  my($warn)            = shift;
  my($cwd)             = $self->getcwd();
  my($start)           = 0;

  ## Fix up the value for Windows switch the \\'s to /
  $cwd =~ s/\\/\//g if ($self->{'convert_slashes'});

  while(substr($value, $start) =~ /(\$\(([^)]+)\))/) {
    my($whole) = $1;
    my($name)  = $2;
    if (defined $$rel{$name}) {
      my($val) = $$rel{$name};
      if ($expand) {
        $val =~ s/\//\\/g if ($self->{'convert_slashes'});
        substr($value, $start) =~ s/\$\([^)]+\)/$val/;
        $whole = $val;
      }
      else {
        ## Fix up the value for Windows switch the \\'s to /
        $val =~ s/\\/\//g if ($self->{'convert_slashes'});

        my($icwd) = ($self->{'case_tolerant'} ? lc($cwd) : $cwd);
        my($ival) = ($self->{'case_tolerant'} ? lc($val) : $val);
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
          $ival =~ s/\//\\/g if ($self->{'convert_slashes'});
          substr($value, $start) =~ s/\$\([^)]+\)/$ival/;
          $whole = $ival;
        }
        elsif ($self->convert_all_variables()) {
          ## The user did not choose to expand $() variables directly,
          ## but we could not convert it into a relative path.  So,
          ## instead of leaving it we will expand it.
          $val =~ s/\//\\/g if ($self->{'convert_slashes'});
          substr($value, $start) =~ s/\$\([^)]+\)/$val/;
          $whole = $val;
        }
      }
    }
    elsif ($expand_template ||
           $self->expand_variables_from_template_values()) {
      my($ti) = $self->get_template_input();
      my($val) = (defined $ti ? $ti->get_value($name) : undef);
      my($sname) = (defined $scope ? $scope . "::$name" : undef);
      my($arr) = $self->adjust_value([$sname, $name],
                                     (defined $val ? $val : []));
      if (UNIVERSAL::isa($arr, 'HASH')) {
        $self->warning("$name conflicts with a template variable scope");
      }
      elsif (UNIVERSAL::isa($arr, 'ARRAY') && defined $$arr[0]) {
        $val = $self->modify_assignment_value(lc($name), "@$arr");
        substr($value, $start) =~ s/\$\([^)]+\)/$val/;

        ## We have replaced the template value, but that template
        ## value may contain a $() construct that may need to get
        ## replaced too.  However, if the name of the template variable
        ## is the same as the original $() variable name, we need to 
        ## leave it alone to avoid looping infinitely.
        $whole = '' if ($whole ne $val);
      }
      else {
        if ($expand && $warn) {
          $self->warning("Unable to expand $name.");
        }
      }
    }
    elsif ($self->convert_all_variables()) {
      substr($value, $start) =~ s/\$\([^)]+\)//;
      $whole = '';
    }
    $start += length($whole);
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
        my($rel) = $self->relative($val, $expand_template, $scope);
        if (UNIVERSAL::isa($rel, 'ARRAY')) {
          push(@built, @$rel);
        }
        else {
          push(@built, $rel);
        }
      }
      return \@built;
    }
    elsif (index($value, '$') >= 0) {
      my($ovalue)   = $value;
      my($rel, $how) = $self->get_initial_relative_values();
      $value = $self->expand_variables($value, $rel,
                                       $expand_template, $scope, $how);

      if ($ovalue eq $value) {
        ($rel, $how) = $self->get_secondary_relative_values();
        $value = $self->expand_variables($value, $rel,
                                         $expand_template, $scope,
                                         $how, 1);
      }
    }
  }

  ## Values that have strings enclosed in double quotes are to
  ## be interpreted as elements of an array
  if (defined $value && $value =~ /^"[^"]+"(\s+"[^"]+")+$/) {
    $value = $self->create_array($value);
  }

  return $value;
}

# ************************************************************
# Virtual Methods To Be Overridden
# ************************************************************

sub restore_state_helper {
  #my($self) = shift;
  #my($skey) = shift;
  #my($old)  = shift;
  #my($new)  = shift;
}


sub get_initial_relative_values {
  #my($self) = shift;
  return {}, 0;
}


sub get_secondary_relative_values {
  my($self) = shift;
  return ($self->{'use_env'} ? \%ENV :
                               $self->{'relative'}), $self->{'expand_vars'};
}


sub convert_all_variables {
  #my($self) = shift;
  return 0;
}


sub expand_variables_from_template_values {
  #my($self) = shift;
  return 0;
}


sub preserve_assignment_order {
  #my($self) = shift;
  #my($name) = shift;
  return 1;
}


sub compare_output {
  #my($self) = shift;
  return 0;
}


sub handle_scoped_end {
  #my($self)  = shift;
  #my($type)  = shift;
  #my($flags) = shift;
  return 1, undef;
}


sub handle_unknown_assignment {
  my($self)   = shift;
  my($type)   = shift;
  my(@values) = @_;
  return 0, "Invalid assignment name: '$values[1]'";
}


sub handle_scoped_unknown {
  my($self)  = shift;
  my($fh)    = shift;
  my($type)  = shift;
  my($flags) = shift;
  my($line)  = shift;
  return 0, "Unrecognized line: $line";
}


sub remove_duplicate_addition {
  my($self)    = shift;
  my($name)    = shift;
  my($value)   = shift;
  my($current) = shift;
  return $value;
}


sub generate_recursive_input_list {
  #my($self)    = shift;
  #my($dir)     = shift;
  #my($exclude) = shift;
  return ();
}


sub reset_values {
  #my($self) = shift;
}


sub sort_files {
  #my($self) = shift;
  return 1;
}


sub file_sorter {
  #my($self)  = shift;
  #my($left)  = shift;
  #my($right) = shift;
  return $_[1] cmp $_[2];
}


sub read_global_configuration {
  #my($self)  = shift;
  #my($input) = shift;
  return 1;
}


sub set_verbose_ordering {
  #my($self)  = shift;
  #my($value) = shift;
}


1;
