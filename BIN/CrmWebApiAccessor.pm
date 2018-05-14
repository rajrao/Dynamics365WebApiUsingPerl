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
		token => "",
		traceLevel => 1,  #1 - verbose, #2 -debug #3-important messages 
	};

	$this->{crmUrl} = $parm{'crmUrl'};
	$this->{crmApiUrl} = $parm{'crmApiUrl'};
	$this->{clientId} = $parm{'clientId'};
	$this->{clientSecret} = $parm{'clientSecret'};
	$this->{traceLevel} = $parm{'traceLevel'};
	
	if (defined $parm{'debug'})
	{
		$this->{debug} = $parm{'debug'};
		
		if ($this->{debug} == 1)
		{
			print 'CrmWebApiAccessor instance data:' . "\n";
			print 'crmUrl:' . $this->{crmUrl} . "\n";
			print 'crmApiUrl:' .$this->{crmApiUrl} . "\n";
			print 'clientId:' . $this->{clientId} . "\n";
			print 'clientSecret:' . $this->{clientSecret} . "\n";
			print 'traceLevel:' . $this->{traceLevel} . "\n\n";
		}
	}
	
	bless $this, $type;		
}


sub debugPrint {
	my($this, $msg, $traceLevel) = @_;
    if (defined $this->{debug} && $traceLevel >= $this->{traceLevel})
	{
		print $msg . "\n";
	}
}

sub getAuthorizationUri{
	my ($this) = @_;
	debugPrint($this, 'getting auth uri....' . "\n", 2);
	my $header = ['Content-Type' => 'application/json; charset=UTF-8'];
	my $request = HTTP::Request->new(Get => $this->{crmApiUrl}, $header);
	my $ua=LWP::UserAgent->new();
	
	my $authuri = "";
	my $resourceUri = "";
	
	my $response = $ua->request($request);
	if ($response->code == 401)
	{
		my $wwwAuthenticateHeader = $response->header('www-authenticate');
		($authuri, $resourceUri) = $wwwAuthenticateHeader =~ m/authorization_uri=(?<u>.*authorize).* resource_id=(?<r>.*)/g;
		
		$authuri =~ s/authorize/token/g;
		
		debugPrint ($this, "Authorization Uri: " . $authuri . "Resource Uri: " . $resourceUri, 2);
	}
	else
	{
		print "Error retrieving auth uri. Expected code 401\n";
		print "Code was ", $response->code, "\n";
		print "Msg: ", $response->message, "\n";
		print $response->content, "\n";
		die;
	}
	return ($authuri, $resourceUri);
}

sub getToken{
	my ($this) = @_;
	debugPrint($this, 'getting token....' . "\n", 2);
	my ($authUri, $resourceUri) = getAuthorizationUri($this);
		
	my $token = "";
	my $expiresIn = DateTime->now;
	
	if ($authUri ne "")
	{
		my $header = ['Content-Type' => 'application/x-www-form-urlencoded;'];
		my $content = "resource=$resourceUri&client_id=" . $this->{clientId} . "&client_secret=" . $this->{clientSecret} . "&grant_type=client_credentials";
		my $request = HTTP::Request->new(Post => $authUri, $header,$content);
			
		my $ua=LWP::UserAgent->new();
		
		my $response = $ua->request($request);
		debugPrint ($this, $response->content, 1);
		
		if ($response->is_success)
		{
			my $json = decode_json($response->content);
			debugPrint($this, Dumper($json), 1);
			
			$token = $json->{'access_token'};
			$expiresIn->add(seconds => $json->{'expires_in'});
			
			$this->{token}  = $token;
			$this->{expiresAt} = $expiresIn;
		
			debugPrint($this, 'token retrieved. Expires at: ' . $expiresIn . "\n", 2);
		}
		else {
			print "Error retrieving token:\n";
			print "Code was ", $response->code, "\n";
			print "Msg: ", $response->message, "\n";
			print $response->content, "\n";
			die;
		}		
	}
		
	return ($token, $expiresIn);
}

sub getData{
	my ($this, $query)= @_;
	print 'getting data for query: ' . $query . "\n";
	my $queryUri = $this->{crmApiUrl} . $query;
	debugPrint($this, $queryUri, 3);
	
	if (DateTime->now > $this->{expiresAt})
	{
		debugPrint($this, 'token expired, getting new token' . "\n", 3);
		getToken($this);
	}
	
	debugPrint($this, 'sending request to get data.... ' . "\n", 2);
	
	my $crmApiUa = LWP::UserAgent->new();
	$crmApiUa->default_header(Authorization => 'Bearer ' . $this->{token});
	my $apiResponse = $crmApiUa->get($queryUri);
	
	debugPrint($this, 'response received!' . "\n", 2);
		
	my $apiData;
	if($apiResponse->is_success) {
		my $jsonData = decode_json($apiResponse->content);
		debugPrint($this, Dumper($jsonData->{'value'}), 1);
		$apiData = $jsonData->{'value'};
		debugPrint ($this, "type: " . (ref $apiData), 1);
		debugPrint($this, Dumper($apiData), 1);
	} 
	else {
		print "Error retrieving data:\n";
		print "Code was ", $apiResponse->code, "\n";
		print "Msg: ", $apiResponse->message, "\n";
		print $apiResponse->content, "\n";
		die;
	}
	
	debugPrint($this, 'done getting data! retrieved: ' . scalar(@$apiData) . " elements! \n", 3);
		
	return @$apiData;
}


sub printData{
	my ($this, @data)= @_;
	for my $item( @data ){
		print Dumper($item). "\n";
	}
}
	

1;