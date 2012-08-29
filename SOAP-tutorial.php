
Thought I would add a bit of a tutorial to this subject to get folks going on this. Following is a working example of using PhP and the 3D API.

NOTE: I have changed the API key value so this code won't work if you cut and paste. You have to use your own STORE URL and API Key.

Hope this helps someone else untangle the API. (P.S. The API documentation could be improved with some real life examples in PhP and ASP code)

FGluck -- www.rutabaga.com

------ START HERE -----------

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>Example PhP Interface to 3D API SOAP service</title>
</head>

<body>
<?php
// build the Soap XML to submit to the 3D API SOAP service.
// The PhP reference and examples for soapClient is here: http://php.net/manual/en/soapclient.soapclient.php
// You can see how your PhP is configured and what is included by using the simple statement
// phpinfo();.

// Turn on some error reporting
//
ERROR_REPORTING(E_ALL);
ini_set('display_errors', true);
// Now define the SOAP client using the url for the service. This service is from http://api.3dcart.com/cart.asmx
// The service provides a number of interfaces to the 3D cart database. See the URL above from complete info
// from this page, click on Service Description (http://api.3dcart.com/cart.asmx?WSDL) to see the WSDL
// service of the description.

// first, we create a soap client with trace on so that we can later see the results.
// trace allow us to see the results of the calls later (see below)
// more informaton on the SimpleXML library for PhP and how to create a soapclient is at
//
$client = new soapclient('http://api.3dcart.com/cart.asmx?WSDL', array('trace' => 1,
'soap_version' => SOAP_1_1));

// Parameters passed to the call must be in an array so we now create that array
// NOTE: the name of the elements must EXACTLY match what the service expects (including upper and lower case).
// If the names do not match, the service throws them out.
// The ONLY way to find exactly what the service expects is to look at the service description at
// this URL http://api.3dcart.com/cart.asmx

$param = array(
'storeUrl'=>"www.mystore.com",
// your UserKey is set from your admin panel. The API service must be enabled and you
// have to have a valid key in order to use this service
'userKey'=>"12343656789012345678901234567890"
);


// We then call the service ($client), passing the parameters and the name of the operation that we want the server to execute
// the result is assigned to a variable called $result
$result = $client->getProductCount($param);


// Then we use three standard PHP SimpleXML library calls to see the results
// print the SOAP request
echo '<h2>SOAP Request</h2><pre>' . htmlspecialchars($client->__getLastRequest(), ENT_QUOTES) . '</pre>';
// print the SOAP request Headers
echo '<h2>SOAP Request Headers</h2><pre>' . htmlspecialchars($client->__getLastRequestHeaders(), ENT_QUOTES) . '</pre>';
// print the SOAP response
echo '<h2>SOAP Response</h2><pre>' . htmlspecialchars($client->__getLastResponse(), ENT_QUOTES) . '</pre>';


// Results are returned in an array that contains one item -- a stdClass object.
// We look at all the results using print_r after we check if the call was successful assess the results
if (is_soap_fault($result)) {
echo '<h2>Fault</h2><pre>';
print_r($result);
echo '</pre>';
} else {
echo '<h2>Result Data Structure:</h2><pre>';
print_r($result);
echo '</pre>';
}

// as shown by the print_r results, what we get back is an object that contains an array
// The Array contains one stdClass Object called GetProductCountResult
// That object in turn contains properties
// We show the outcome property of specific variables in that object by printing it

echo "<br/><strong>There are a total of:</strong> ".$result->getProductCountResult->any." products that were found<br/>";
?>
</body>
</html>

----- END CODE ---
