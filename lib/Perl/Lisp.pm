package Perl::Lisp;
use Moose;

use warnings;
use strict;
use Carp;

use version;
our $VERSION = qv('0.0.3');

use PPI;

=head1 NAME

Perl::Lisp - Perl to Lisp langauge transcoder


=head1 VERSION

This document describes Perl::Lisp version 0.0.1


=head1 SYNOPSIS

    use Perl::Lisp;

    # XXX No code samples until the interface is worked out.

=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE 

# {{{ _is_terminal_node($node)
sub _is_terminal_node {
  my ( $self, $node ) = @_;
  my $type = ref $node;
  return if $type !~ /PPI\::Token\::/;
  return 1;
}

# }}}

# {{{ _escape_double_quotes($str)
sub _escape_double_quotes {
  my ( $self, $str ) = @_;
  $str =~ s/"/\\"/g;
  return $str;
}

# }}}

# {{{ _lisp_representation($node)
sub _lisp_representation {
  my ( $self, $node ) = @_;
  my $type = ref $node;

  my %dispatch = (
#    'PPI::Token' => sub { return $_[0]->content },
#    'PPI::Token::Whitespace' => sub { return $_[0]->content },
#    'PPI::Token::Comment' => sub { return "; " . $_[0]->content },
#    'PPI::Token::Pod' => sub { return "; " . $_[0]->content },

# {{{ PPI::Token::Number
    'PPI::Token::Number' => sub { return $_[0]->content },
    'PPI::Token::Number::Binary' => sub {
      my $content = $_[0]->content;
      $content =~ s/^-0b/#b-/;
      $content =~ s/^0b/#b/;
      return $content;
     },
    'PPI::Token::Number::Octal' => sub {
      my $content = $_[0]->content;
      $content =~ s/^-0/#o-/;
      $content =~ s/^0/#o/;
      return $content;
     },
    'PPI::Token::Number::Hex' => sub {
      my $content = $_[0]->content;
      $content =~ s/^-0x/#x-/;
      $content =~ s/^0x/#x/;
      return $content;
     },

# }}}

    'PPI::Token::Number::Float' => sub { return $_[0]->content },
#    'PPI::Token::Number::Exp' => sub { return $_[0]->content },
#    'PPI::Token::Number::Version' => sub { return $_[0]->content },
    'PPI::Token::Word' => sub { return $_[0]->content },
#    'PPI::Token::DashedWord' => sub { return $_[0]->content }, # Deprecated
    'PPI::Token::Symbol' => sub { return $_[0]->content },
    'PPI::Token::Magic' => sub { return $_[0]->content },
    'PPI::Token::ArrayIndex' => sub {
      my $content = $_[0]->content;
      $content =~ s/^\$#/@/;
      return qq{(length $content)};
    },
# {{{ PPI::Token::Operator
    'PPI::Token::Operator' => sub {
      my $content = $_[0]->content;

      # XXX <<= and >>= aren't in the PPI docs...

      my %map = (
#  [ q{++} => q{incf} ], # XXX Needs redesign
#  [ q{--} => q{decf} ], # XXX Needs redesign

        q{**} => q{pow},
        q{!} => q{lognot},
        q{~} => q{bit-not},
        q{+} => q{+},
        q{-} => q{-},
#  [ q{=~} => q{=~} ],
#  [ q{!~} => q{!~} ],
        q{*} => q{*},
        #q{/} => q{/}, # XXX Need to test this in context...
        q{%} => q{mod},
#  [ q{x} => q{x} ],
#  [ q{<<} => q{<<} ],
#  [ q{>>} => q{>>} ],
#  [ q{lt} => q{lt} ],
#  [ q{gt} => q{gt} ],
#  [ q{le} => q{le} ],
#  [ q{ge} => q{ge} ],
#  [ q{cmp} => q{cmp} ],
         q{==} => q{eql}, # XXX Controversial
#  [ q{!=} => q{!=} ], # XXX Controversial, probably
#  [ q{<=>} => q{<=>} ],
#  [ q{.} => q{.} ],
#  [ q{..} => q{..} ],
#  [ q{...} => q{...} ],
#  [ q{,} => q{,} ],
         q{&} => q{bit-and}, # XXX Bit vector only...
         q{|} => q{bit-or}, # XXX Bit vector only...
         q{^} => q{bit-xor}, # XXX Bit vector only...
         q{&&} => q{and},
         q{||} => q{or},
#  [ q{//} => q{or} ],
#  [ q{?} => q{?} ],
#  [ q{:} => q{:} ],
#  [ q{=} => q{=} ], # XXX Needs redesign
#  [ q{+=} => q{+=} ], # XXX Needs redesign
#  [ q{-=} => q{-=} ], # XXX Needs redesign
#  [ q{*=} => q{*=} ], # XXX Needs redesign
#  [ q{.=} => q{.=} ], # XXX Needs redesign
#  [ q{//=} => q{//=} ], # XXX Needs redesign
#  [ q{<} => q{<} ],
#  [ q{>} => q{>} ],
#  [ q{<=} => q{<=} ],
#  [ q{>=} => q{>=} ],
#  [ q{<>} => q{>=} ], # XXX Needs redesign
#  [ q{=>} => q{=>} ], # XXX Needs redesign
#  [ q{->} => q{->} ], # XXX Needs redesign
          q{and} => q{logand},
          q{or} => q{logor},
#  [ q{dor} => q{logor} ], # XXX Needs redesign
          q{not} => q{lognot},
          q{eq} => q{equal}, # XXX Controversial
#  [ q{ne} => q{ne} ], # XXX Needs redesign
      );
      die "Unknown operator '$content'\n" unless exists $map{$content};
      return $map{$content};
    },

# }}}

#    'PPI::Token::Quote'
    'PPI::Token::Quote::Single' => sub {
      my $content = $_[0]->content;
      $content =~ s/^'|'$//g;
      $content =~ s/\\'/'/g;
      $content =~ s/\\"/\"/g;
      return qq{"$content"};
    },
    # Apparently PPI::Token::Quote::Interpolate isn't actually used.
    # Instead, it hands off to ::Double and ::Literal as needed.
    #
    'PPI::Token::Quote::Double' => sub {
      my $content = $_[0]->content;
      $content =~ s/^"|"$//g;
      $content =~ s/\\'/'/g;
      return qq{"$content"};
    },
    'PPI::Token::Quote::Literal' => sub {
      my $content = $_[0]->content;
      if ( $content =~ s/^q[ ]?// ) {
        $content =~ s/^[ ]?.|.$//g;
        $content =~ s/\\'/'/g;
        $content =~ s/\\"/\"/g;
      }
      return qq{"$content"};
    },
#       'PPI::Token::Quote::Interpolate'
#    'PPI::Token::QuoteLike'
#       'PPI::Token::QuoteLike::Backtick' => sub { return $_[0]->content },
#       'PPI::Token::QuoteLike::Command' => sub { return $_[0]->content },
#       'PPI::Token::QuoteLike::Regexp' => sub { return $_[0]->content },
       'PPI::Token::QuoteLike::Words' => sub {
         my $content = $_[0]->content;
         $content =~ s/^qw[ ]?//;
         $content =~ s/^.//;
         $content =~ s/.$//;
         $content =
           join (" ",
                 map { qq{"} . $self->_escape_double_quotes($_) . qq{"} }
                   split /\s+/, $content);
         return qq{'($content)};
       },
#       'PPI::Token::QuoteLike::Readline' => sub { return $_[0]->content },
#    'PPI::Token::Regexp'
#       'PPI::Token::Regexp::Match' => sub { return $_[0]->content },
#       'PPI::Token::Regexp::Substitute' => sub { return $_[0]->content },
#       'PPI::Token::Regexp::Transliterate' => sub { return $_[0]->content },
    'PPI::Token::HereDoc' => sub {
       my @lines = $_[0]->heredoc;
       pop @lines;
       return join("\n", @lines);
    },
#    'PPI::Token::Cast' => sub { return $_[0]->content },
#    'PPI::Token::Structure' => sub { return $_[0]->content },
#    'PPI::Token::Label' => sub { return $_[0]->content },
#    'PPI::Token::Separator' => sub { return $_[0]->content },
#    'PPI::Token::Data' => sub { return $_[0]->content },
#    'PPI::Token::End' => sub { return $_[0]->content },
#    'PPI::Token::Prototype' => sub { return $_[0]->content },
#    'PPI::Token::Attribute' => sub { return $_[0]->content },
#    'PPI::Token::Unknown' => sub { return $_[0]->content },
  );

  if ( exists $dispatch{$type} ) {
    return $dispatch{$type}->($node);
  }
  die "*** UNKNOWN TYPE '$type'\n";
}

# }}}

# {{{ _walk($node)
sub _walk {
  my ( $self, $node, $level ) = @_;
  $level ||= 0;

  if ( $self->_is_terminal_node($node) ) {
    return $self->_lisp_representation($node);
  }

  my @walk;
  for my $child ( $node->schildren ) {
    push @walk, $self->_walk($child,$level+1);
  }
  return join "\n", @walk;
}

# }}}

# {{{ to_lisp($perl)

=head2 to_lisp($perl)

=cut

sub to_lisp {
  my ( $self, $perl ) = @_;
  my $doc = PPI::Document->new(\$perl);

  return $self->_walk($doc->top);
}

# }}}

=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
Perl::Lisp requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-perl-lisp@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Jeffrey Goff  C<< <jgoff@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Jeffrey Goff C<< <jgoff@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

1;
