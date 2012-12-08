package Lingua::Translate::Bing;

use 5.006;
use strict;
use warnings;
use Encode;

use LWP::UserAgent;
use URI::Escape;
use JSON::XS;
use XML::Simple;
use Carp;

=head1 NAME

Lingua::Translate::Bing - class to access the function of translation provided by "Bing Translation Api". 

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

    use Lingua::Translate::Bing;

    my $translator = Lingua::Translate::Bing->new("1111111", "111111");

    print $translator->translate("Hello", "ru");
    ...


=cut

my @lang_codes = qw /ar 
bg
ca
zh-CHS
zh-CHT
cs 
da 
nl 
en 
et 
fa
fi 
fr 
de
el 
ht 
he 
hi 
hu 
id 
it 
ja 
ko 
lv 
lt 
mww 
no 
pl 
pt 
ro 
ru 
sk 
sl 
es 
sv 
th
tr
uk 
vi/;

=head1 CONSTRUCTORS

=head2 new($client_id, $client_secret)

$client_id and $client_secret you will must get in L<http://datamarket.azure.com/dataset/bing/microsofttranslator>.

B<ATTENTION!>
Microsoft offers free access to Bing Translator for no more than 2,000,000 characters/month. 

=cut

sub new {
    my ($class, %args)  = @_;
    
    my $self = { 
        client_id => $args{'client_id'},
        client_secret => $args{'client_secret'},
        tokens_xml => 'tokens.xml',
        xml => XML::Simple->new(KeepRoot => 1),
    };
    bless $self, $class;
    return $self;
}

=head1 METHODS

=head2 translate($text, $to)

=over 1

=item $text  

Text, that must will be translated.

=item $to

Language code. Such as in L<http://msdn.microsoft.com/en-us/library/hh456380.aspx>

=back

=cut

sub translate {
    my ($self, $text, $to) = @_;
    my $result; 

    my @selected_lang = grep{
        /^($to)/ix
        } @lang_codes;
    $to = $selected_lang[0];

    if (defined($to)) {
        $result = $self->sendRequest($text, $to, $self->getAccessToken());
        unless (defined($result)) {
            $self->updateToken();
            $result = $self->sendRequest($text, $to, $self->getAccessToken());
        }
    } else {
        croak "Language undefined";
    }
    return $result;     
}

=head2 initAccessToken()

Returns token from Microsoft OAuth service.

=cut

sub initAccessToken {
    my ($self) = @_;
    my $result;
    my $browser = LWP::UserAgent->new();

    my $url = "https://datamarket.accesscontrol.windows.net/v2/OAuth2-13";
    my $scope = "http://api.microsofttranslator.com";       
    my $grant_type = "client_credentials";                 

    my $response = $browser->post( $url,
             [
             'client_id' => $self->{client_id},
             'client_secret' => $self->{client_secret},
             'scope' => $scope,
             'grant_type' => $grant_type
             ],
     );
    if ($response) {
         my $content = $response->content;
        my $json_xs = JSON::XS->new();
        $result = $json_xs->decode($content)->{'access_token'};
    }
    unless (defined($result)) {
        croak "Failed init access token";
    }
    return uri_escape($result);
}

=head2 getExistsTokens()

Returns last actual tokens from "tokens.xml" file.

=cut


sub getExistsTokens {
    my ($self) = @_;
    my $result;
    if (-f $self->{tokens_xml}) {
        $result = $self->{xml}->XMLin($self->{tokens_xml});
    }
    
    return $result;    
}

=head2 updateToken()

Gets token from Microsoft OAuth service and write it to "tokens.xml".

=cut

sub updateToken {
    my ($self) = @_;
    my $access_tokens = $self->getExistsTokens();

    $access_tokens->{$self->{client_id}}->{'token'} = $self->initAccessToken();
    $self->{xml}->XMLout($access_tokens, OutputFile => 'tokens.xml', XMLDecl => "<?xml version='1.0'?>");  
    return $access_tokens;
}

=head2 getAccessToken()

Gets token from "tokens.xml" if it exist. Else update "tokens.xml".

=cut


sub getAccessToken {
    my ($self) = @_;
    
    my $access_tokens;

    unless (-f $self->{tokens_xml}) {
        $access_tokens = $self->updateToken();
    } else {
        $access_tokens = $self->getExistsTokens();
        unless (defined($access_tokens->{$self->{client_id}})) {
            $access_tokens = $self->updateToken();
        }
    }

    return $access_tokens->{$self->{client_id}}->{token}; 
}

=head2 sendRequest($text, $to, $access_token)

=over 1

=item $text 

Text, that must will be translated.

=item $to 

Language code.

=item $access_token 

Token from Microsoft OAuth service.

=back

=cut


sub sendRequest {
    my ($self, $text, $to, $access_token) = @_;
    $access_token = "Bearer " . $access_token; 
    my $url =
    "http://api.microsofttranslator.com/V2/Http.svc/Translate?text=$text&to=$to&appId=$access_token&contentType=text/plain";

    my $browser = LWP::UserAgent->new();
    my $response = $browser->get($url, 'Authorization' => $access_token);
    my $result = $response->content;
    my $xml_parser = $self->{xml}->XMLin($result);
    
    if (defined($result) && !defined($xml_parser)) {
        croak "$result";
    }

    return encode('utf8', $xml_parser->{'string'}->{'content'});
}

=head1 AUTHOR

Milovidov Mikhail, C<< <milovidovwork at yandex.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bingtranslationapi at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=BingTranslationApi>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc BingTranslationApi


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=BingTranslationApi>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/BingTranslationApi>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/BingTranslationApi>

=item * Search CPAN

L<http://search.cpan.org/dist/BingTranslationApi/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Milovidov Mikhail.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lingua::Translate::Bing
