/*
* Application Name:- HTTPCalloutFramework
* Created:- 4/17/2026
* Last Updated:- 4/17/2026
* Description:- This is the service class for performing HTTP Callouts
* Contributors:-
*    1. Vibe CodeX
*/
public class HttpCalloutService {

    IntegrationSetting__mdt calloutMetadata;
	String endpointURL;
    String bearerToken;
    String requestMethod;
    String requestBody;
    Integer requestTimeout;
    Map<String, String> urlParametersMap;
    Map<String, String> headerParametersMap;
    HTTPRequest request;
    
	//Getters and Setters - Begin
 	public String getEndpointURL() {
 		return endpointURL;
 	}
    
    /**
     * @name: GetBearerToken
     * @description: Concrete implementation of the Command interface for getting a Bearer Token.
     */
 	public String getBearerToken() {
 		return bearerToken;
 	}
    
    /**
    * This method sets the Bearer Token for the given Command Apex instance.
    * @param bearerToken The Bearer Token to be set.
    */
    public void setBearerToken(String bearerToken) {
		this.bearerToken = bearerToken;
	}
    /**

    /**
     * This method sets the endpoint URL for the API call.
     * @param endpointURL The URL of the endpoint to be set.
     */
	public void setEndpointURL(String endpointURL) {
		this.endpointURL = endpointURL;
	}
    
    /**
     * This method returns the request method used in the API call.
     * @return String - The request method (GET, POST, PUT, DELETE, etc.).
     */
	public String getRequestMethod() {
		return requestMethod;
	}
    
    /**
     * Sets the request method for the API call.
     * @param requestMethod The request method to be used (e.g. GET, POST, PUT, DELETE).
     */
	public void setRequestMethod(String requestMethod) {
		this.requestMethod = requestMethod;
	}
    
    /**
    * This method returns the request body for the given command.
    * @return String - The request body.
    */
	public String getRequestBody() {
		return requestBody;
	}
    /**
     * Sets the request body for the given CommandApex instance.
     * @param requestBody The request body to be set.
     */
	public void setRequestBody(String requestBody) {
		this.requestBody = requestBody;
	}
    
     /**
     * This method returns the request timeout value for the given code.
     * @return Integer - The request timeout value.
     */
	public Integer getRequestTimeout() {
		return requestTimeout;
	}
    /**
     * Sets the request timeout for the CommandApex instance.
     * @param requestTimeout The timeout value in milliseconds.
     */
	public void setRequestTimeout(Integer requestTimeout) {
		this.requestTimeout = requestTimeout;
	}
    
    /**
    * This method retrieves the header parameters from the headerParametersMap.
    * @return Map<String, String> - A map of header parameters.
    */
    public Map<String, String> getHeaderParameters() {
        Map<String, String> newHeaderParam = headerParametersMap;
        return newHeaderParam;
    }
    /**
    * Sets a header parameter in the headerParametersMap.
    * @param key The key of the header parameter.
    * @param value The value of the header parameter.
    */
    public void setHeaderParameter(String key, String value) {
        if(String.isNotEmpty(key) && String.isNotEmpty(value)) {
            headerParametersMap.put(key, value);
        }
    }
    
    /**
    * Removes a header parameter from the map of header parameters.
    * @param key The key of the header parameter to be removed.
    */
    public void removeHeaderParameter(String key) {
        headerParametersMap.remove(key);
    }
    
    /**
    * @name: setURLParameters
    * @return: urlParametersMap
    */
    public Map<String, String> setURLParameters() {
        Map<String, String> newUrlParam = urlParametersMap;
        return newUrlParam;
    }
    
    /**
    * This method sets a URL parameter with the given key and value.
    * If the key and value are not empty strings, the parameter is added to the map of URL parameters.
    * If the key is empty but the value is not, the value is ignored.
    * If the key is not empty but the value is, the key is added to the map with a null value.
    * @param key The key of the URL parameter.
    * @param value The value of the URL parameter.
    */
    public void setURLParameter(String key, String value) {
        if(String.isNotEmpty(key) && String.isNotEmpty(value)) {
            urlParametersMap.put(key, value);
        } else if(String.isNotEmpty(key)) {
            urlParametersMap.put(key, value);
        }
    }
    /**
    * This method removes a URL parameter from the existing map of URL parameters.
    * @param key The key of the URL parameter to be removed.
    */
    public void removeURLParameter(String key) {
        urlParametersMap.remove(key);
    }

        /*
    * Constructor
    */
    public HTTPCalloutService() {
        initialize();
    }

    /*
    * Constructor with Custom Metadata
    */
    public HTTPCalloutService(String customMetadataName) {
        try {
            calloutMetadata = [
                SELECT Method__c,  Endpoint__c, Timeout__c,Path__c,APIKey__c
                    FROM IntegrationSetting__mdt
                    WHERE DeveloperName =:customMetadataName WITH SECURITY_ENFORCED
            ];
        } catch (Exception e) {
            throw e;
        }
        initialize();
    }

        /*
    * Initialization of class variables
    */
    private void initialize() {
        urlParametersMap = new Map<String, String>();
        headerParametersMap = new Map<String, String>();
        if(calloutMetadata != null) {
            endpointURL = calloutMetadata.Path__c != null ? 'callout:'+calloutMetadata.Endpoint__c + calloutMetadata.Path__c : calloutMetadata.Endpoint__c;
            requestMethod = calloutMetadata.Method__c;
            requestTimeout = Integer.valueOf(calloutMetadata.Timeout__c) *1000;
            if(!String.IsBlank(calloutMetadata.APIKey__c)){
                urlParametersMap.put('access_key',calloutMetadata.APIKey__c);
            }
        }
    }

        /*
    * This method is used to append the URL parameters at the end of URL
    */
    private void appendURLParameters() {
        Set<String> urlParamKeys = urlParametersMap.keySet();
        if(!urlParamKeys.isEmpty()) {
            endpointURL += '?';
            for(String urlParamKey : urlParamKeys) {
                endpointURL += urlParamKey + '=' + urlParametersMap.get(urlParamKey) + '&';
            }
            endpointURL = endpointURL.substringBeforeLast('&');
        }
    }

    /*
    * This method is used to set Header parameters using headerParametersMap
    */
    private void addHeaderParameters() {
        for(String key : headerParametersMap.keySet()) {
            request.setHeader(key, headerParametersMap.get(key));
        }
    }

    /*
    * This method is used to form HTTP Request
    */
    public void formHTTPRequest() {
        request = new HTTPRequest();
        if(String.IsNotBlank(this.bearerToken)){
            setHeaderParameter('Authorization', 'Bearer ' + this.bearerToken);
        }
        addHeaderParameters();
        if(String.isNotEmpty(endpointURL)) {
            endpointURL = endpointURL.substringBefore('?');
            appendURLParameters();
            request.setEndpoint(endpointURL);
            system.debug('endpointURL $#$#$'+endpointURL);
        }
        if(String.isNotEmpty(requestMethod)) {
            request.setMethod(requestMethod);
            system.debug('requestMethod $#$#$'+requestMethod);
        }
        if(String.isNotEmpty(requestBody)) {
            request.setBody(requestBody);
        } 

        if(requestTimeout!=null) {
            request.setTimeout(requestTimeout);
            system.debug('requestTimeout $#$#$'+requestTimeout);
        }
    }

    /*
    * This method forms and returns the HTTP Request without sending (for debugging purposes)
    */
    public HTTPRequest getRequest() {
        formHTTPRequest();
        return request;
    }

    /*
    * This method is used to send HTTP Request and return the response
    */
    public HTTPResponse sendRequest() {
        formHTTPRequest();
        Http http = new Http();
        return http.send(request);
    }

    /*
    * This method is used to send HTTP Request received in parameter and return the response
    */
    public HTTPResponse sendRequest(HTTPRequest request) {
        Http http = new Http();
        return http.send(request);
    }

}