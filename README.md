# Dynamics365WebApiUsingPerl
Sample code to access Dynamics 365 using Web-Api and OAuth and Client Id and Client Secret.

Note: This is my first ever foray into PERL scripts. This was a 0 to 60 in about 4 hours. So, I may have not done everything the perl way. Feel free to fork and submit changes

## What you need ##

1. Your CRM URL
2. Client Id
3. Client Secret.

For number 2 and 3 you can follow my blog post: [Headless authentication against CRM]( http://blog.aggregatedintelligence.com/2017/02/headless-authentication-against-crm-365.html)


## Other notes ##
1. All of the code is in the package "CRMWebApiAccessor.pm" file.
2. Once you setup an instance of your class, you just need to call getData to get the data you need.

```
#set required variables
my $crmUrl = "https://xxxxxxxx.crm.dynamics.com/";
my $crmApiUrl = $crmUrl . "api/data/V8.2/";

my $clientId="00000000-0000-0000-0000-000000000000";
my $clientSecret="yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy";

#initalize the class
my $c = new CrmWebApiAccessor(
	'crmUrl' => $crmUrl, 
	'crmApiUrl' => $crmApiUrl, 
	'clientId' => $clientId,  
	'clientSecret' => $clientSecret, 
	'debug' => 1, 'traceLevel' => 2);

#get the data
my (@data) = $c->getData('systemusers?$top=2&$select=fullname');

#print the data
$c->printData(@data);

#to access the data: (you need to know what properties are returned)
for my $item( @data ){
	print $item->{"fullname"} . " {" . $item->{"systemuserid"} ."}". "\n";
};

```