package TemplateParser;

# ************************************************************
# Description   : Parses the template and fills in missing values
# Author        : Chad Elliott
# Create Date   : 5/17/2002
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use Parser;
use WinVersionTranslator;

use vars qw(@ISA);
@ISA = qw(Parser);

# ************************************************************
# Data Section
# ************************************************************

# Valid keywords for use in template files.  Each has a handle_
# method available, but some have other methods too.
# Bit  Meaning
# 0 means there is a get_ method available (used by if)
# 1 means there is a perform_ method available (used by foreach)
# 2 means there is a doif_ method available (used by if)
my(%keywords) = ('if'              => 0,
                 'else'            => 0,
                 'endif'           => 0,
                 'noextension'     => 2,
                 'dirname'         => 5,
                 'basename'        => 0,
                 'basenoextension' => 0,
                 'foreach'         => 0,
                 'forfirst'        => 0,
                 'fornotfirst'     => 0,
                 'fornotlast'      => 0,
                 'forlast'         => 0,
                 'endfor'          => 0,
                 'eval'            => 0,
                 'comment'         => 0,
                 'marker'          => 0,
                 'uc'              => 0,
                 'lc'              => 0,
                 'ucw'             => 0,
                 'normalize'       => 2,
                 'flag_overrides'  => 1,
                 'reverse'         => 2,
                 'sort'            => 2,
                 'uniq'            => 3,
                 'multiple'        => 5,
                 'starts_with'     => 5,
                 'ends_with'       => 5,
                 'contains'        => 5,
                 'compares'        => 5,
                 'duplicate_index' => 5,
                );

# ************************************************************
# Subroutine Section
# ************************************************************

sub new {
  my($class) = shift;
  my($prjc)  = shift;
  my($self)  = $class->SUPER::new();

  $self->{'prjc'}       = $prjc;
  $self->{'ti'}         = $prjc->get_template_input();
  $self->{'cslashes'}   = $prjc->convert_slashes();
  $self->{'crlf'}       = $prjc->crlf();
  $self->{'cmds'}       = $prjc->get_command_subs();
  $self->{'vnames'}     = $prjc->get_valid_names();
  $self->{'values'}     = {};
  $self->{'defaults'}   = {};
  $self->{'lines'}      = [];
  $self->{'built'}      = '';
  $self->{'sstack'}     = [];
  $self->{'lstack'}     = [];
  $self->{'if_skip'}    = 0;
  $self->{'eval'}       = 0;
  $self->{'eval_str'}   = '';
  $self->{'dupfiles'}   = {};

  $self->{'foreach'}  = {};
  $self->{'foreach'}->{'count'}      = -1;
  $self->{'foreach'}->{'nested'}     = 0;
  $self->{'foreach'}->{'name'}       = [];
  $self->{'foreach'}->{'vars'}       = [];
  $self->{'foreach'}->{'text'}       = [];
  $self->{'foreach'}->{'scope'}      = [];
  $self->{'foreach'}->{'scope_name'} = [];
  $self->{'foreach'}->{'temp_scope'} = [];
  $self->{'foreach'}->{'processing'} = 0;

  return $self;
}


sub basename {
  my($self) = shift;
  my($file) = shift;

  if ($self->{'cslashes'}) {
    $file =~ s/.*[\/\\]//;
  }
  else {
    $file =~ s/.*\///;
  }
  return $file;
}


sub tp_dirname {
  my($self)  = shift;
  my($file)  = shift;
  my($index) = rindex($file, ($self->{'cslashes'} ? '\\' : '/'));

  if ($index >= 0) {
    return $self->{'prjc'}->validated_directory(substr($file, 0, $index));
  }
  else {
    return '.';
  }
}


sub strip_line {
  #my($self) = shift;
  #my($line) = shift;

  ## Override strip_line() from Parser.
  ## We need to preserve leading space and
  ## there is no comment string in templates.
  ++$_[0]->{'line_number'};
  $_[1] =~ s/\s+$//;

  return $_[1];
}


## Append the current value to the line that is being
## built.  This line may be a foreach line or a general
## line without a foreach.
sub append_current {
#  my($self)  = shift;
#  my($value) = shift;

  if ($_[0]->{'foreach'}->{'count'} >= 0) {
    $_[0]->{'foreach'}->{'text'}->[$_[0]->{'foreach'}->{'count'}] .= $_[1];
  }
  elsif ($_[0]->{'eval'}) {
    $_[0]->{'eval_str'} .= $_[1];
  }
  else {
    $_[0]->{'built'} .= $_[1];
  }
}


sub split_parameters {
  my($self)   = shift;
  my($str)    = shift;
  my(@params) = ();

  while($str =~ /(\w+\([^\)]+\))\s*,\s*(.*)/) {
    push(@params, $1);
    $str = $2;
  }
  while($str =~ /([^,]+)\s*,\s*(.*)/) {
    push(@params, $1);
    $str = $2;
  }

  ## Return the parameters (which includes whatever is left in the
  ## string).  Just return it instead of pushing it onto @params.
  return @params, $str;
}


sub set_current_values {
  my($self) = shift;
  my($name) = shift;
  my($set)  = 0;

  ## If any value within a foreach matches the name
  ## of a hash table within the template input we will
  ## set the values of that hash table in the current scope
  if (defined $self->{'ti'}) {
    my($counter) = $self->{'foreach'}->{'count'};
    if ($counter >= 0) {
      ## Variable names are case-insensitive in MPC, however this can
      ## cause problems when dealing with template variable values that
      ## happen to match HASH names only by case-insensitivity.  So, we
      ## now make HASH names match with case-sensitivity.
      my($value) = $self->{'ti'}->get_value($name);
      if (defined $value && UNIVERSAL::isa($value, 'HASH') &&
          $self->{'ti'}->get_realname($name) eq $name) {
        $self->{'foreach'}->{'scope_name'}->[$counter] = $name;
        my(%copy) = ();
        foreach my $key (keys %$value) {
          $copy{$key} = $self->{'prjc'}->adjust_value(
                    [$name . '::' . $key, $name], $$value{$key});
        }
        $self->{'foreach'}->{'temp_scope'}->[$counter] = \%copy;
        $set = 1;
      }
    }
  }
  return $set;
}


sub get_value {
  my($self)    = shift;
  my($name)    = shift;
  my($value)   = undef;
  my($counter) = $self->{'foreach'}->{'count'};
  my($fromprj) = 0;
  my($scope)   = undef;
  my($sname)   = undef;
  my($adjust)  = 1;

  ## First, check the temporary scope (set inside a foreach)
  if ($counter >= 0) {
    ## Find the outer most scope for our variable name
    for(my $index = $counter; $index >= 0; --$index) {
      if (defined $self->{'foreach'}->{'scope_name'}->[$index]) {
        $scope = $self->{'foreach'}->{'scope_name'}->[$index];
        $sname = $scope . '::' . $name;
        last;
      }
    }
    while(!defined $value && $counter >= 0) {
      $value = $self->{'foreach'}->{'temp_scope'}->[$counter]->{$name};
      --$counter;
    }
    $counter = $self->{'foreach'}->{'count'};
  }

  if (!defined $value) {
    if ($name =~ /^flag_overrides\((.*)\)$/) {
      $value = $self->get_flag_overrides($1);
    }

    if (!defined $value) {
      ## Next, check for a template value
      if (defined $self->{'ti'}) {
        $value = $self->{'ti'}->get_value($name);
      }

      if (!defined $value) {
        ## Calling adjust_value here allows us to pick up template
        ## overrides before getting values elsewhere.
        my($uvalue) = $self->{'prjc'}->adjust_value([$sname, $name], []);
        if (defined $$uvalue[0]) {
          $value = $uvalue;
          $adjust = 0;
        }

        if (!defined $value) {
          ## Next, check the inner to outer foreach
          ## scopes for overriding values
          while(!defined $value && $counter >= 0) {
            $value = $self->{'foreach'}->{'scope'}->[$counter]->{$name};
            --$counter;
          }

          ## Then get the value from the project creator
          if (!defined $value) {
            $fromprj = 1;
            $value = $self->{'prjc'}->get_assignment($name);

            ## Then get it from our known values
            if (!defined $value) {
              $value = $self->{'values'}->{$name};
              if (!defined $value) {
                ## Call back onto the project creator to allow
                ## it to fill in the value before defaulting to undef.
                $value = $self->{'prjc'}->fill_value($name);
                if (!defined $value && $name =~ /^(.*)\->(\w+)/) {
                  my($pre)  = $1;
                  my($post) = $2;
                  my($base) = $self->get_value($pre);

                  if (defined $base) {
                    $value = $self->{'prjc'}->get_special_value(
                               $pre, $post, $base,
                               ($self->{'prjc'}->requires_parameters($post) ?
                                   $self->prepare_parameters($pre) : undef));
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  ## Adjust the value even if we haven't obtained one from an outside
  ## source.
  if ($adjust && defined $value) {
    $value = $self->{'prjc'}->adjust_value([$sname, $name], $value);
  }

  ## If the value did not come from the project creator, we
  ## check the variable name.  If it is a project keyword we then
  ## check to see if we need to add the project value to the template
  ## variable value.  If so, we make a copy of the value array and
  ## push the project value onto that (to avoid modifying the original).
  if (!$fromprj && defined $self->{'vnames'}->{$name} &&
      $self->{'prjc'}->add_to_template_input_value($name)) {
    my($pjval) = $self->{'prjc'}->get_assignment($name);
    if (defined $pjval) {
      my(@copy) = @$value;
      if (!UNIVERSAL::isa($pjval, 'ARRAY')) {
        $pjval = $self->create_array($pjval);
      }
      push(@copy, @$pjval);
      $value = \@copy;
    }
  }

  return $self->{'prjc'}->relative($value, undef, $scope);
}


sub get_value_with_default {
  my($self)  = shift;
  my($name)  = shift;
  my($value) = $self->get_value($name);

  if (!defined $value) {
    $value = $self->{'defaults'}->{$name};
    if (defined $value) {
      my($counter) = $self->{'foreach'}->{'count'};
      my($sname)   = undef;

      if ($counter >= 0) {
        ## Find the outer most scope for our variable name
        for(my $index = $counter; $index >= 0; --$index) {
          if (defined $self->{'foreach'}->{'scope_name'}->[$index]) {
            $sname = $self->{'foreach'}->{'scope_name'}->[$index] .
                     '::' . $name;
            last;
          }
        }
      }
      $value = $self->{'prjc'}->relative(
                    $self->{'prjc'}->adjust_value([$sname, $name], $value));

      ## If the user set the variable to empty, we will go ahead and use
      ## the default value (since we know we have one at this point).
      if (!defined $value) {
        $value = $self->{'defaults'}->{$name};
      }
    }
    else {
      #$self->warning("$name defaulting to empty string.");
      $value = '';
    }
  }

  if (UNIVERSAL::isa($value, 'ARRAY')) {
    $value = "@$value";
  }

  return $value;
}


sub process_foreach {
  my($self)   = shift;
  my($index)  = $self->{'foreach'}->{'count'};
  my($text)   = $self->{'foreach'}->{'text'}->[$index];
  my($status) = 1;
  my($error)  = undef;
  my(@values) = ();
  my($name)   = $self->{'foreach'}->{'name'}->[$index];
  my(@cmds)   = ();
  my($val)    = $self->{'foreach'}->{'vars'}->[$index];

  if ($val =~ /^((\w+),\s*)?flag_overrides\((.*)\)$/) {
    my($over) = $self->get_flag_overrides($3);
    $name = $2;
    if (defined $over) {
      $val = $self->create_array($over);
      @values = @$val;
    }
    if (!defined $name) {
      $name = '__unnamed__';
    }
  }
  else {
    ## Pull out modifying commands first
    while ($val =~ /(\w+)\((.+)\)/) {
      my($cmd) = $1;
      $val     = $2;
      if (($keywords{$cmd} & 0x02) != 0) {
        push(@cmds, 'perform_' . $cmd);
      }
      else {
        $self->warning("Unable to use $cmd in foreach (no perform_ method).");
      }
    }

    ## Get the values for all of the variable names
    ## contained within the foreach
    my($names) = $self->create_array($val);
    foreach my $n (@$names) {
      my($vals) = $self->get_value($n);
      if (defined $vals && $vals ne '') {
        if (!UNIVERSAL::isa($vals, 'ARRAY')) {
          $vals = $self->create_array($vals);
        }
        push(@values, @$vals);
      }
      if (!defined $name) {
        $name = $n;
        $name =~ s/s$//;
      }
    }
  }

  ## Perform the commands on the built up @values
  foreach my $cmd (reverse @cmds) {
    @values = $self->$cmd(\@values);
  }

  ## Reset the text (it will be regenerated by calling parse_line
  $self->{'foreach'}->{'text'}->[$index] = '';

  if (defined $values[0]) {
    my($scope) = $self->{'foreach'}->{'scope'}->[$index];

    $$scope{'forlast'}     = '';
    $$scope{'fornotlast'}  = 1;
    $$scope{'forfirst'}    = 1;
    $$scope{'fornotfirst'} = '';

    ## If the foreach values are mixed (HASH and SCALAR), then
    ## remove the SCALAR values.
    my(%mixed) = ();
    my($mixed) = 0;
    for(my $i = 0; $i <= $#values; ++$i) {
      $mixed{$values[$i]} = $self->set_current_values($values[$i]);
      $mixed |= $mixed{$values[$i]};
    }
    if ($mixed) {
      @values = ();
      foreach my $key (sort keys %mixed) {
        if ($mixed{$key}) {
          push(@values, $key);
        }
      }
    }

    for(my $i = 0; $i <= $#values; ++$i) {
      my($value) = $values[$i];

      ## Set the corresponding values in the temporary scope
      $self->set_current_values($value);

      ## Set the special values that only exist
      ## within a foreach
      if ($i != 0) {
        $$scope{'forfirst'}    = '';
        $$scope{'fornotfirst'} = 1;
      }
      if ($i == $#values) {
        $$scope{'forlast'}    = 1;
        $$scope{'fornotlast'} = '';
      }
      $$scope{'forcount'} = $i + 1;

      ## We don't use adjust_value here because these names
      ## are generated from a foreach and should not be adjusted.
      $$scope{$name} = $value;

      ## A tiny hack for VC7
      if ($name eq 'configuration') {
        $self->{'prjc'}->update_project_info($self, 1,
                                             ['configuration', 'platform'],
                                             '|');
      }

      ## Now parse the line of text, each time
      ## with different values
      ++$self->{'foreach'}->{'processing'};
      ($status, $error) = $self->parse_line(undef, $text);
      --$self->{'foreach'}->{'processing'};
      if (!$status) {
        last;
      }
    }
  }

  return $status, $error;
}


sub handle_endif {
  my($self) = shift;
  my($name) = shift;
  my($end)  = pop(@{$self->{'sstack'}});
  pop(@{$self->{'lstack'}});

  if (!defined $end) {
    return 0, "Unmatched $name";
  }
  else {
    my($in) = index($end, $name);
    if ($in == 0) {
      $self->{'if_skip'} = 0;
    }
    elsif ($in == -1) {
      return 0, "Unmatched $name";
    }
  }

  return 1, undef;
}


sub handle_endfor {
  my($self) = shift;
  my($name) = shift;
  my($end)  = pop(@{$self->{'sstack'}});
  pop(@{$self->{'lstack'}});

  if (!defined $end) {
    return 0, "Unmatched $name";
  }
  else {
    my($in) = index($end, $name);
    if ($in == 0) {
      my($index) = $self->{'foreach'}->{'count'};
      my($status, $error) = $self->process_foreach();
      if ($status) {
        --$self->{'foreach'}->{'count'};
        $self->append_current($self->{'foreach'}->{'text'}->[$index]);
      }
      return $status, $error;
    }
    elsif ($in == -1) {
      return 0, "Unmatched $name";
    }
  }

  return 1, undef;
}


sub get_flag_overrides {
  my($self)  = shift;
  my($name)  = shift;
  my($type)  = '';

  ## Split the name and type parameters
  ($name, $type) = split(/,\s*/, $name);

  my($file) = $self->get_value($name);
  if (defined $file) {
    my($value) = undef;
    my($prjc)  = $self->{'prjc'};
    my($fo)    = $prjc->{'flag_overrides'};

    ## Save the name prefix (if there is one) for
    ## command parameter conversion at the end
    my($pre) = undef;
    if ($name =~ /(\w+)->/) {
      $pre = $1;
    }

    ## Replace the custom_type key with the actual custom type
    if ($name =~ /^custom_type\->/) {
      my($ct) = $self->get_value('custom_type');
      if (defined $ct) {
        $name = $ct;
      }
    }

    my($key) = (defined $$fo{$name} ? $name :
                   (defined $$fo{$name . 's'} ? $name . 's' : undef));
    if (defined $key) {
      if (defined $prjc->{'matching_assignments'}->{$key}) {
        ## Convert the file name into a unix style file name
        my($ustyle) = $file;
        $ustyle =~ s/\\/\//g;

        ## Save the directory portion for checking in the foreach
        my($dir) = $self->mpc_dirname($ustyle);

        my($of) = (defined $$fo{$key}->{$ustyle} ? $ustyle :
                      (defined $$fo{$key}->{$dir} ? $dir : undef));
        if (defined $of) {
          foreach my $aname (@{$prjc->{'matching_assignments'}->{$key}}) {
            if ($aname eq $type && defined $$fo{$key}->{$of}->{$aname}) {
              $value = $$fo{$key}->{$of}->{$aname};
              last;
            }
          }
        }
      }
    }

    ## If the name that we're overriding has a value and
    ## requires parameters, then we will convert all of the
    ## pseudo variables and provide parameters.
    if (defined $pre &&
        defined $value && $prjc->requires_parameters($type)) {
      $value = $prjc->convert_command_parameters(
                              $value,
                              $self->prepare_parameters($pre));
    }

    return $prjc->relative($value);
  }

  return undef;
}


sub get_multiple {
  my($self)  = shift;
  my($name)  = shift;
  my($value) = $self->get_value_with_default($name);
  return (defined $value ?
              $self->doif_multiple($self->create_array($value)) :
              undef);
}


sub doif_multiple {
  my($self)  = shift;
  my($value) = shift;

  if (defined $value) {
    return (scalar(@$value) > 1);
  }
  return undef;
}


sub handle_multiple {
  my($self) = shift;
  my($name) = shift;
  my($val)  = $self->get_value_with_default($name);

  if (defined $val) {
    my($array) = $self->create_array($val);
    $self->append_current(scalar(@$array));
  }
  else {
    $self->append_current(0);
  }
}


sub get_starts_with {
  my($self) = shift;
  my($str)  = shift;
  return $self->doif_starts_with([$str]);
}


sub doif_starts_with {
  my($self) = shift;
  my($val)  = shift;

  if (defined $val) {
    my($name, $pattern) = $self->split_parameters("@$val");
    if (defined $name && defined $pattern) {
      return ($self->get_value_with_default($name) =~ /^$pattern/);
    }
  }
  return undef;
}


sub handle_starts_with {
  my($self) = shift;
  my($str)  = shift;

  if (defined $str) {
    my($val) = $self->doif_starts_with([$str]);

    if (defined $val) {
      $self->append_current($val);
    }
    else {
      $self->append_current(0);
    }
  }
}


sub get_ends_with {
  my($self) = shift;
  my($str)  = shift;
  return $self->doif_ends_with([$str]);
}


sub doif_ends_with {
  my($self) = shift;
  my($val)  = shift;

  if (defined $val) {
    my($name, $pattern) = $self->split_parameters("@$val");
    if (defined $name && defined $pattern) {
      return ($self->get_value_with_default($name) =~ /$pattern$/);
    }
  }
  return undef;
}


sub handle_ends_with {
  my($self) = shift;
  my($str)  = shift;

  if (defined $str) {
    my($val) = $self->doif_ends_with([$str]);

    if (defined $val) {
      $self->append_current($val);
    }
    else {
      $self->append_current(0);
    }
  }
}


sub get_contains {
  my($self) = shift;
  my($str)  = shift;
  return $self->doif_contains([$str]);
}


sub doif_contains {
  my($self) = shift;
  my($val)  = shift;

  if (defined $val) {
    my($name, $pattern) = $self->split_parameters("@$val");
    if (defined $name && defined $pattern) {
      return ($self->get_value_with_default($name) =~ /$pattern/);
    }
  }
  return undef;
}


sub handle_contains {
  my($self) = shift;
  my($str)  = shift;

  if (defined $str) {
    my($val) = $self->doif_contains([$str]);

    if (defined $val) {
      $self->append_current($val);
    }
    else {
      $self->append_current(0);
    }
  }
}


sub get_compares {
  my($self) = shift;
  my($str)  = shift;
  return $self->doif_compares([$str]);
}


sub doif_compares {
  my($self) = shift;
  my($val)  = shift;

  if (defined $val) {
    my($name, $pattern) = $self->split_parameters("@$val");
    if (defined $name && defined $pattern) {
      return ($self->get_value_with_default($name) eq $pattern);
    }
  }
  return undef;
}


sub handle_compares {
  my($self) = shift;
  my($str)  = shift;

  if (defined $str) {
    my($val) = $self->doif_compares([$str]);

    if (defined $val) {
      $self->append_current($val);
    }
    else {
      $self->append_current(0);
    }
  }
}


sub perform_reverse {
  my($self)  = shift;
  my($value) = shift;
  return reverse(@$value);
}


sub handle_reverse {
  my($self) = shift;
  my($name) = shift;
  my($val)  = $self->get_value_with_default($name);

  if (defined $val) {
    my(@array) = $self->perform_reverse($self->create_array($val));
    $self->append_current("@array");
  }
}


sub perform_sort {
  my($self)  = shift;
  my($value) = shift;
  return sort(@$value);
}


sub handle_sort {
  my($self) = shift;
  my($name) = shift;
  my($val)  = $self->get_value_with_default($name);

  if (defined $val) {
    my(@array) = $self->perform_sort($self->create_array($val));
    $self->append_current("@array");
  }
}


sub get_uniq {
  my($self)  = shift;
  my($name)  = shift;
  my($value) = $self->get_value_with_default($name);

  if (defined $value) {
    my(@array) = $self->perform_uniq($self->create_array($value));
    return \@array;
  }

  return undef;
}


sub perform_uniq {
  my($self)  = shift;
  my($value) = shift;
  my(%value) = ();
  @value{@$value} = ();
  return sort(keys %value);
}


sub handle_uniq {
  my($self) = shift;
  my($name) = shift;
  my($val)  = $self->get_value_with_default($name);

  if (defined $val) {
    my(@array) = $self->perform_uniq($self->create_array($val));
    $self->append_current("@array");
  }
}


sub process_compound_if {
  my($self)   = shift;
  my($str)    = shift;
  my($status) = 0;

  if ($str =~ /\|\|/) {
    my($ret) = 0;
    foreach my $v (split(/\s*\|\|\s*/, $str)) {
      $ret |= $self->process_compound_if($v);
      if ($ret != 0) {
        return 1;
      }
    }
  }
  elsif ($str =~ /\&\&/) {
    my($ret) = 1;
    foreach my $v (split(/\s*\&\&\s*/, $str)) {
      $ret &&= $self->process_compound_if($v);
      if ($ret == 0) {
        return 0;
      }
    }
    $status = 1;
  }
  else {
    ## See if we need to reverse the return value
    my($not) = 0;
    if ($str =~ /^!(.*)/) {
      $not = 1;
      $str = $1;
    }

    ## Get the value based on the string
    my(@cmds) = ();
    my($val)  = undef;
    while ($str =~ /(\w+)\((.+)\)(.*)/) {
      if ($3 eq '') {
        push(@cmds, $1);
        $str = $2;
      }
      else {
        ## If there is something trailing the closing parenthesis then
        ## the whole thing is considered a parameter to the first
        ## function.
        last;
      }
    }

    if (defined $cmds[0]) {
      ## Start out calling get_xxx on the string
      my($type) = 0x01;
      my($prefix) = 'get_';

      $val = $str;
      foreach my $cmd (reverse @cmds) {
        if (defined $keywords{$cmd} && ($keywords{$cmd} & $type) != 0) {
          my($func) = "$prefix$cmd";
          $val = $self->$func($val);

          ## Now that we have a value, we need to switch over
          ## to calling doif_xxx
          $type = 0x04;
          $prefix = 'doif_';
        }
        else {
          $self->warning("Unable to use $cmd in if (no $prefix method).");
        }
      }
    }
    else {
      $val = $self->get_value($str);
    }

    ## See if any portion of the value is defined and not empty
    my($ret) = 0;
    if (defined $val) {
      if (UNIVERSAL::isa($val, 'ARRAY')) {
        foreach my $v (@$val) {
          if ($v ne '') {
            $ret = 1;
            last;
          }
        }
      }
      elsif ($val ne '') {
        $ret = 1;
      }
    }
    return ($not ? !$ret : $ret);
  }

  return $status;
}


sub handle_if {
  my($self)   = shift;
  my($val)    = shift;
  my($name)   = 'endif';

  push(@{$self->{'lstack'}}, $self->get_line_number() . " $val");
  if ($self->{'if_skip'}) {
    push(@{$self->{'sstack'}}, "*$name");
  }
  else {
    ## Determine if we are skipping the portion of this if statement
    ## $val will always be defined since we won't get into this method
    ## without properly parsing the if statement.
    $self->{'if_skip'} = !$self->process_compound_if($val);
    push(@{$self->{'sstack'}}, $name);
  }
}


sub handle_else {
  my($self)  = shift;
  my(@scopy) = @{$self->{'sstack'}};

  if (defined $scopy[$#scopy]) {
    my($index) = index($scopy[$#scopy], 'endif');
    if ($index >= 0) {
      if ($index == 0) {
        $self->{'if_skip'} ^= 1;
      }
      $self->{'sstack'}->[$#scopy] .= ':';
    }

    if (($self->{'sstack'}->[$#scopy] =~ tr/:/:/) > 1) {
      return 0, 'Unmatched else';
    }
  }

  return 1, undef;
}


sub handle_foreach {
  my($self)        = shift;
  my($val)         = shift;
  my($name)        = 'endfor';
  my($status)      = 1;
  my($errorString) = undef;

  push(@{$self->{'lstack'}}, $self->get_line_number());
  if (!$self->{'if_skip'}) {
    my($vname) = undef;
    if ($val =~ /flag_overrides\([^\)]+\)/) {
    }
    elsif ($val =~ /([^,]+),(.*)/) {
      $vname = $1;
      $val   = $2;
      $vname =~ s/^\s+//;
      $vname =~ s/\s+$//;
      $val   =~ s/^\s+//;
      $val   =~ s/\s+$//;

      ## Due to the way flag_overrides works, we can't allow
      ## the user to name the foreach variable when dealing
      ## with custom types.
      if ($val =~ /^custom_type\->/ || $val eq 'custom_types') {
        $status = 0;
        $errorString = 'The foreach variable can not be ' .
                       'named when dealing with custom types';
      }
      elsif ($val =~ /^grouped_.*_file\->/ || $val =~ /^grouped_.*files$/) {
        $status = 0;
        $errorString = 'The foreach variable can not be ' .
                       'named when dealing with grouped files';
      }
    }

    push(@{$self->{'sstack'}}, $name);
    my($index) = ++$self->{'foreach'}->{'count'};

    $self->{'foreach'}->{'name'}->[$index]  = $vname;
    $self->{'foreach'}->{'vars'}->[$index]  = $val;
    $self->{'foreach'}->{'text'}->[$index]  = '';
    $self->{'foreach'}->{'scope'}->[$index] = {};
    $self->{'foreach'}->{'scope_name'}->[$index] = undef;
  }
  else {
    push(@{$self->{'sstack'}}, "*$name");
  }

  return $status, $errorString;
}


sub handle_special {
  my($self) = shift;
  my($name) = shift;
  my($val)  = shift;

  ## If $name (fornotlast, forfirst, etc.) is set to 1
  ## Then we append the $val onto the current string that's
  ## being built.
  if ($self->get_value($name)) {
    $self->append_current($val);
  }
}


sub handle_uc {
  my($self) = shift;
  my($name) = shift;

  $self->append_current(uc($self->get_value_with_default($name)));
}


sub handle_lc {
  my($self) = shift;
  my($name) = shift;

  $self->append_current(lc($self->get_value_with_default($name)));
}


sub handle_ucw {
  my($self) = shift;
  my($name) = shift;
  my($val)  = $self->get_value_with_default($name);

  substr($val, 0, 1) = uc(substr($val, 0, 1));
  while($val =~ /[_\s]([a-z])/) {
    my($uc) = uc($1);
    $val =~ s/[_\s][a-z]/ $uc/;
  }
  $self->append_current($val);
}


sub perform_normalize {
  my($self)  = shift;
  my($value) = shift;
  $value =~ tr/\/\\\-$()./_/;
  return $value;
}


sub handle_normalize {
  my($self) = shift;
  my($name) = shift;
  my($val)  = $self->get_value_with_default($name);

  $self->append_current($self->perform_normalize($val));
}


sub perform_noextension {
  my($self)  = shift;
  my($value) = shift;
  $value =~ s/\.[^\.]+$//;
  return $value;
}


sub handle_noextension {
  my($self) = shift;
  my($name) = shift;
  my($val)  = $self->get_value_with_default($name);

  $self->append_current($self->perform_noextension($val));
}


sub get_dirname {
  my($self)  = shift;
  my($name)  = shift;
  my($value) = $self->get_value_with_default($name);
  return (defined $value ?
              $self->doif_dirname($value) : undef);
}


sub doif_dirname {
  my($self)  = shift;
  my($value) = shift;

  if (defined $value) {
    $value = $self->tp_dirname($value);
    return ($value ne '.');
  }
  return undef;
}


sub handle_dirname {
  my($self) = shift;
  my($name) = shift;

  if (!$self->{'if_skip'}) {
    $self->append_current(
              $self->tp_dirname($self->get_value_with_default($name)));
  }
}


sub handle_basename {
  my($self) = shift;
  my($name) = shift;

  if (!$self->{'if_skip'}) {
    $self->append_current(
              $self->basename($self->get_value_with_default($name)));
  }
}


sub handle_basenoextension {
  my($self) = shift;
  my($name) = shift;
  my($val)  = $self->basename($self->get_value_with_default($name));

  $val =~ s/\.[^\.]+$//;
  $self->append_current($val);
}


sub handle_flag_overrides {
  my($self)  = shift;
  my($name)  = shift;
  my($value) = $self->get_flag_overrides($name);

  if (defined $value) {
    $self->append_current($value);
  }
}


sub handle_marker {
  my($self) = shift;
  my($name) = shift;
  my($val)  = $self->{'prjc'}->get_verbatim($name);

  if (defined $val) {
    $self->append_current($val);
  }
}


sub handle_eval {
  my($self) = shift;
  my($name) = shift;
  my($val)  = $self->get_value_with_default($name);

  if (defined $val) {
    if ($val =~ /<%eval\($name\)%>/) {
      $self->warning("Infinite recursion detected in '$name'.");
    }
    else {
      ## Enter the eval state
      ++$self->{'eval'};

      ## Parse the eval line
      my($status, $error) = $self->parse_line(undef, $val);
      if ($status) {
        $self->{'built'} .= $self->{'eval_str'};
      }
      else {
        $self->warning($error);
      }

      ## Leave the eval state
      --$self->{'eval'};
      $self->{'eval_str'} = '';
    }
  }
}


sub handle_pseudo {
  my($self) = shift;
  my($name) = shift;
  $self->append_current($self->{'cmds'}->{$name});
}


sub get_duplicate_index {
  my($self) = shift;
  my($name) = shift;
  return $self->doif_duplicate_index($self->get_value_with_default($name));
}


sub doif_duplicate_index {
  my($self)  = shift;
  my($value) = shift;

  if (defined $value) {
    my($base) = $self->basename($value);
    my($path) = $self->tp_dirname($value);

    if (!defined $self->{'dupfiles'}->{$base}) {
      $self->{'dupfiles'}->{$base} = [$path];
    }
    else {
      my($index) = 1;
      foreach my $file (@{$self->{'dupfiles'}->{$base}}) {
        if ($file eq $path) {
          return $index;
        }
        ++$index;
      }

      push(@{$self->{'dupfiles'}->{$base}}, $path);
      return 1;
    }
  }

  return undef;
}


sub handle_duplicate_index {
  my($self) = shift;
  my($name) = shift;

  if (!$self->{'if_skip'}) {
    my($value) = $self->doif_duplicate_index(
                          $self->get_value_with_default($name));
    if (defined $value) {
      $self->append_current($value);
    }
  }
}


sub prepare_parameters {
  my($self)   = shift;
  my($prefix) = shift;
  my($input)  = $self->get_value($prefix . '->input_file');
  my($output) = undef;

  if (defined $input) {
    if ($self->{'cslashes'}) {
      $input = $self->{'prjc'}->slash_to_backslash($input);
    }
    $output = $self->get_value($prefix . '->input_file->output_file');

    if (defined $output) {
      my($fo) = $self->get_flag_overrides($prefix . '->input_file, gendir');
      if (defined $fo) {
        $output = $fo . '/' . File::Basename::basename($output);
      }
      if ($self->{'cslashes'}) {
        $output = $self->{'prjc'}->slash_to_backslash($output);
      }
    }
  }

  ## Set the parameters array with the determined input and output files
  return $input, $output;
}


sub process_name {
  my($self)        = shift;
  my($line)        = shift;
  my($length)      = 0;
  my($status)      = 1;
  my($errorString) = undef;

  if ($line eq '') {
  }
  elsif ($line =~ /^\w+(\(([^\)]+|\".*\"|[!]?(\w+\s*,\s*)?\w+\(.+\))\)|\->\w+([\w\-\>]+)?)?%>/) {
    ## Split the line into a name and value
    my($name, $val) = ();
    if ($line =~ /([^%\(]+)(\(([^%]+)\))?%>/) {
      $name = lc($1);
      $val  = $3;
    }

    $length += length($name);
    if (defined $val) {
      ## Check for the parenthesis
      if (($val =~ tr/(//) != ($val =~ tr/)//)) {
        $status = 0;
        $errorString = 'Missing the closing parenthesis';
      }

      ## Add the length of the value plus 2 for the surrounding ()
      $length += length($val) + 2;
    }

    if ($status) {
      if (defined $keywords{$name}) {
        if ($name eq 'endif') {
          ($status, $errorString) = $self->handle_endif($name);
        }
        elsif ($name eq 'if') {
          $self->handle_if($val);
        }
        elsif ($name eq 'endfor') {
          ($status, $errorString) = $self->handle_endfor($name);
        }
        elsif ($name eq 'foreach') {
          ($status, $errorString) = $self->handle_foreach($val);
        }
        elsif ($name eq 'fornotlast'  || $name eq 'forlast' ||
               $name eq 'fornotfirst' || $name eq 'forfirst') {
          if (!$self->{'if_skip'}) {
            $self->handle_special($name, $self->process_special($val));
          }
        }
        elsif ($name eq 'else') {
          ($status, $errorString) = $self->handle_else();
        }
        elsif ($name eq 'comment') {
          ## Ignore the contents of the comment
        }
        else {
          if (!$self->{'if_skip'}) {
            my($func) = 'handle_' . $name;
            $self->$func($val);
          }
        }
      }
      elsif (defined $self->{'cmds'}->{$name}) {
        if (!$self->{'if_skip'}) {
          $self->handle_pseudo($name);
        }
      }
      else {
        if (!$self->{'if_skip'}) {
          if (defined $val && !defined $self->{'defaults'}->{$name}) {
            $self->{'defaults'}->{$name} = $self->process_special($val);
          }
          $self->append_current($self->get_value_with_default($name));
        }
      }
    }
  }
  else {
    my($error)  = $line;
    my($length) = length($line);
    for(my $i = 0; $i < $length; ++$i) {
      my($part) = substr($line, $i, 2);
      if ($part eq '%>') {
        $error = substr($line, 0, $i + 2);
        last;
      }
    }
    $status = 0;
    $errorString = "Unable to parse line starting at '$error'";
  }

  return $status, $errorString, $length;
}


sub collect_data {
  my($self)  = shift;
  my($prjc)  = $self->{'prjc'};
  my($cwd)   = $self->getcwd();

  ## Set the current working directory
  if ($self->{'cslashes'}) {
    $cwd = $prjc->slash_to_backslash($cwd);
  }
  $self->{'values'}->{'cwd'} = $cwd;

  ## Collect the components into {'values'} somehow
  foreach my $key (keys %{$prjc->{'valid_components'}}) {
    my(@list) = $prjc->get_component_list($key);
    if (defined $list[0]) {
      $self->{'values'}->{$key} = \@list;
    }
  }

  ## If there is a staticname and no sharedname then this project
  ## 'type_is_static'.  If we are generating static projects, let
  ## all of the templates know that we 'need_staticflags'.
  ## If there is a sharedname then this project 'type_is_dynamic'.
  my($sharedname) = $prjc->get_assignment('sharedname');
  my($staticname) = $prjc->get_assignment('staticname');
  if (!defined $sharedname && defined $staticname) {
    $self->{'values'}->{'type_is_static'}   = 1;
    $self->{'values'}->{'need_staticflags'} = 1;
  }
  elsif ($prjc->get_static() == 1) {
    $self->{'values'}->{'need_staticflags'} = 1;
  }
  elsif (defined $sharedname) {
    $self->{'values'}->{'type_is_dynamic'} = 1;
  }

  ## If there is a sharedname or exename then this project
  ## 'type_is_binary'.
  if (defined $sharedname ||
      defined $prjc->get_assignment('exename')) {
    $self->{'values'}->{'type_is_binary'} = 1;
  }

  ## A tiny hack (mainly for VC6 projects)
  ## for the workspace creator.  It needs to know the
  ## target names to match up with the project name.
  $prjc->update_project_info($self, 0, ['project_name']);

  ## This is for all projects
  $prjc->update_project_info($self, 1, ['after']);

  ## VC7 Projects need to know the GUID.
  ## We need to save this value in our known values
  ## since each guid generated will be different.  We need
  ## this to correspond to the same guid used in the workspace.
  my($guid) = $prjc->update_project_info($self, 1, ['guid']);
  $self->{'values'}->{'guid'} = $guid;

  ## Some Windows based projects can't deal with certain version
  ## values.  So, for those we provide a translated version.
  my($version) = $prjc->get_assignment('version');
  if (defined $version) {
    $self->{'values'}->{'win_version'} =
                        WinVersionTranslator::translate($version);
  }
}


sub parse_line {
  my($self)        = shift;
  my($ih)          = shift;
  my($line)        = shift;
  my($status)      = 1;
  my($errorString) = undef;
  my($startempty)  = (length($line) == 0 ? 1 : 0);

  ## If processing a foreach or the line only
  ## contains a keyword, then we do
  ## not need to add a newline to the end.
  if (!$self->{'eval'} && $self->{'foreach'}->{'processing'} == 0) {
    if ($line !~ /^[ ]*<%(\w+)(\(((\w+\s*,\s*)?\w+\(.+\)|[^\)]+)\))?%>$/ ||
        !defined $keywords{$1}) {
      $line .= $self->{'crlf'};
    }
  }

  if (!$self->{'eval'} && $self->{'foreach'}->{'count'} < 0) {
    $self->{'built'} = '';
  }

  my($start) = index($line, '<%');
  if ($start >= 0) {
    my($append_name) = 0;
    if ($start > 0) {
      if (!$self->{'if_skip'}) {
        $self->append_current(substr($line, 0, $start));
      }
      $line = substr($line, $start);
    }
    foreach my $item (split('<%', $line)) {
      my($name)   = 1;
      my($length) = length($item);
      for(my $i = 0; $i < $length; ++$i) {
        my($part) = substr($item, $i, 2);
        if ($part eq '%>') {
          ++$i;
          $name = 0;
          if ($append_name) {
            $append_name = 0;
            if (!$self->{'if_skip'}) {
              $self->append_current($part);
            }
          }
          if ($length != $i + 1) {
            if (!$self->{'if_skip'}) {
              $self->append_current(substr($item, $i + 1));
            }
            last;
          }
        }
        elsif ($name) {
          my($substr)  = substr($item, $i);
          my($efcheck) = ($substr =~ /^endfor\%\>/);
          my($focheck) = ($efcheck ? 0 : ($substr =~ /^foreach\(/));

          if ($focheck && $self->{'foreach'}->{'count'} >= 0) {
            ++$self->{'foreach'}->{'nested'};
          }

          if ($self->{'foreach'}->{'count'} < 0 ||
              $self->{'foreach'}->{'processing'} > $self->{'foreach'}->{'nested'} ||
              (($efcheck || $focheck) &&
               $self->{'foreach'}->{'nested'} == $self->{'foreach'}->{'processing'})) {
            my($nlen) = 0;
            ($status,
             $errorString,
             $nlen) = $self->process_name($substr);

            if ($status && $nlen == 0) {
              $errorString = "Could not parse this line at column $i";
              $status = 0;
            }
            if (!$status) {
              last;
            }

            $i += ($nlen - 1);
          }
          else  {
            $name = 0;
            if (!$self->{'if_skip'}) {
              $self->append_current('<%' . substr($item, $i, 1));
              $append_name = 1;
            }
          }

          if ($efcheck && $self->{'foreach'}->{'nested'} > 0) {
            --$self->{'foreach'}->{'nested'};
          }
        }
        else {
          if (!$self->{'if_skip'}) {
            $self->append_current(substr($item, $i, 1));
          }
        }
      }
    }
  }
  else {
    if (!$self->{'if_skip'}) {
      $self->append_current($line);
    }
  }

  if (!$self->{'eval'} && $self->{'foreach'}->{'count'} < 0) {
    ## If the line started out empty and we're not
    ## skipping from the start or the built up line is not empty
    if ($startempty ||
        ($self->{'built'} ne $self->{'crlf'} && $self->{'built'} ne '')) {
      push(@{$self->{'lines'}}, $self->{'built'});
    }
  }

  return $status, $errorString;
}


sub parse_file {
  my($self)  = shift;
  my($input) = shift;

  $self->collect_data();
  my($status, $errorString) = $self->cached_file_read($input);

  if ($status) {
    my($sstack) = $self->{'sstack'};
    if (defined $$sstack[0]) {
      my($lstack) = $self->{'lstack'};
      $status = 0;
      $errorString = "Missing an '$$sstack[0]' starting at $$lstack[0]";
    }
  }

  if (!$status) {
    my($linenumber) = $self->get_line_number();
    $errorString = "$input: line $linenumber:\n$errorString";
  }

  return $status, $errorString;
}


sub get_lines {
  my($self) = shift;
  return $self->{'lines'};
}


1;
