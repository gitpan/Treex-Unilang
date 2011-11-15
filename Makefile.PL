
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "collection of blocks parametrized by language and language independent",
  "AUTHOR" => "Treex team <treex\@ufal.mff.cuni.cz>",
  "BUILD_REQUIRES" => {
    "English" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Test::More" => 0,
    "Test::Output" => 0,
    "Treex::Core::Config" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Treex-Unilang",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Treex::Unilang",
  "PREREQ_PM" => {
    "File::Slurp" => 0,
    "Moose" => 0,
    "Treex::Block::Read::BaseTextReader" => 0,
    "Treex::Block::Write::Redirectable" => 0,
    "Treex::Core" => "0.07191",
    "Treex::Core::Block" => 0,
    "Treex::Core::Common" => 0,
    "Treex::Core::Document" => 0,
    "Treex::Core::DocumentReader" => 0,
    "Treex::Core::Resource" => 0,
    "Treex::Tool::Parser::MSTperl::Config" => 0,
    "Treex::Tool::Parser::MSTperl::Node" => 0,
    "Treex::Tool::Parser::MSTperl::Parser" => 0,
    "Treex::Tool::Parser::MSTperl::Sentence" => 0,
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.07297",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



