package CrmWebApiAccessor;
require Exporter;
@ISA = qw(Exporter);
#@EXPORT = qw(setImports, declareMain, closeMain);

use strict;
use warnings;

use DateTime;
use Data::Dumper;
use LWP::UserAgent;  ## used to get stuff via LWP from a server##
use HTTP::Request;	## frames the request for LWP ##
use HTTP::Headers;
use JSON;
use HTML::Entities;
use Win32::Console;

sub new {
	
    my $type = shift;

	my %parm = (@_);

	my $this = {
		debug => 1,
		expiresAt => DateTime->now->subtract(seconds => 1),
		token => ""
	};

	$this->{crmUrl} = $parm{'crmUrl'};
	$this->{crmApiUrl} = $parm{'crmApiUrl'};
	$this->{clientId} = $parm{'clientId'};
	$this->{clientSecret} = $parm{'clientSecret'};
	
	if (defined $parm{'debug'})
	{
		$this->{debug} = $parm{'debug'};
		
		if ($this->{debug} == 1)
		{
			print 'crmUrl:' . $this->{crmUrl} . "\n";
			print 'crmApiUrl:' .$this->{crmApiUrl} . "\n";
			print 'clientId:' . $this->{clientId} . "\n";
			print 'clientSecret:' . $this->{clientSecret} . "\n";
		}
	}
	
	bless $this, $type;		
}

sub getFirstName {
	my($this) = @_;
    return $this->{'crmUrl'};
}

sub debugPrint {
	my($msg) = @_;
    # if (defined $this->{debug})
	# {
	print $msg . "\n";
	# }
}

sub getAuthorizationUri{
	my ($this) = @_;
	print 'getting auth uri....' . "\n";
	my $header = ['Content-Type' => 'application/json; charset=UTF-8'];
	my $request = HTTP::Request->new(Get => $this->{crmApiUrl}, $header);
	my $ua=LWP::UserAgent->new();
	
	my $response = $ua->request($request);
	
	my $wwwAuthenticateHeader = $response->header('www-authenticate');
	my $authuri = "";
	my $resourceUri = "";
	
	($authuri, $resourceUri) = $wwwAuthenticateHeader =~ m/authorization_uri=(?<u>.*authorize).* resource_id=(?<r>.*)/g;
	
	$authuri =~ s/authorize/token/g;
	
	return ($authuri, $resourceUri);
}

sub getToken{
	my ($this) = @_;
	print 'getting token....' . "\n";
	my ($authUri, $resourceUri) = getAuthorizationUri($this);
	#debugPrint ("Authorization Uri: " . $authUri);
	
	my $header = ['Content-Type' => 'application/x-www-form-urlencoded;'];
	my $content = "resource=$resourceUri&client_id=" . $this->{clientId} . "&client_secret=" . $this->{clientSecret} . "&grant_type=client_credentials";
	my $request = HTTP::Request->new(Post => $authUri, $header,$content);
		
	my $ua=LWP::UserAgent->new();
	
	my $response = $ua->request($request);
	#debugPrint ($response->content);
	my $token = "";
	my $expiresIn = DateTime->now;
	if ($response->is_success)
	{
		my $json = decode_json($response->content);
		#debugPrint(Dumper($json));
		
		$token = $json->{'access_token'};
		$expiresIn->add(seconds => $json->{'expires_in'});
	}
	else {
		print "Error retrieving token:\n";
		print "Code was ", $response->code, "\n";
		print "Msg: ", $response->message, "\n";
		print $response->content, "\n";
		die;
	}
	$this->{token}  = $token;
	$this->{expiresAt} = $expiresIn;
	return ($token, $expiresIn);
}

sub getData{
	my ($this, $query)= @_;
	print 'getting data....' . "\n";
	my $queryUri = $this->{crmApiUrl} . $query;
	debugPrint($queryUri);
	
	if (DateTime->now > $this->{expiresAt})
	{
		print 'token expired, getting new token' . "\n";
		
		getToken($this);
		
		print $this->{token} . "\n";
	}
	print 'getting data....' . "\n";
	my $crmApiUa = LWP::UserAgent->new();
	$crmApiUa->default_header(Authorization => 'Bearer ' . $this->{token});
	my $apiResponse = $crmApiUa->get($queryUri);
	
	print 'response received!' . "\n";
	
	my $apiData;
	if($apiResponse->is_success) {
		my $jsonData = decode_json($apiResponse->content);
		#debugPrint(Dumper($jsonData->{'value'}));
		$apiData = $jsonData->{'value'};
		debugPrint ("type: " . (ref $apiData));
		#debugPrint(Dumper($apiData));
	} 
	else {
		print "Error retrieving data:\n";
		print "Code was ", $apiResponse->code, "\n";
		print "Msg: ", $apiResponse->message, "\n";
		print $apiResponse->content, "\n";
		die;
	}
	
	print 'done getting data! retrieved: ' . scalar(@$apiData) . " elements! \n";
	
	return @$apiData;
}


sub printData{
	my ($this, @data)= @_;
	for my $item( @data ){
		print Dumper($item). "\n";
	}
}
	

1;