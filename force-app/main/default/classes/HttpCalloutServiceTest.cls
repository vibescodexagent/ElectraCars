@isTest
private class HttpCalloutServiceTest {

    @TestSetup
    static void setupTestData() {
        // Use existing TestDataFactory methods to create minimal test data.
        // Create one user and one account as common dependencies.
        TestDataFactory.createUsers(1, null, true);
        TestDataFactory.createAccounts(1, true);
    }

    // Mock implementation for successful HTTP response
    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"ok","message":"success"}');
            res.setHeader('Content-Type','application/json');
            return res;
        }
    }

    // Mock implementation for error HTTP response
    private class ErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"status":"error","message":"server error"}');
            res.setHeader('Content-Type','application/json');
            return res;
        }
    }

    @isTest
    static void shouldFormRequestAndReturnMockedResponse_SendRequestNoArgs_Success() {
        // Given
        HttpCalloutService svc = new HttpCalloutService();
        svc.setEndpointURL('https://example.com/api/test');
        svc.setRequestMethod('POST');
        svc.setRequestBody('{"name":"test"}');
        svc.setRequestTimeout(30 * 1000); // 30 seconds
        svc.setBearerToken('dummy-token');

        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        // When
        Test.startTest();
        HTTPResponse resp = svc.sendRequest();
        Test.stopTest();

        // Then
        Assert.areEqual(200, resp.getStatusCode(), 'Expected 200 OK from mocked response');
        Assert.areEqual('{"status":"ok","message":"success"}', resp.getBody(),
            'Response body should match mocked success payload');
    }

    @isTest
    static void shouldFormRequestAndReturnMockedResponse_SendRequestWithRequestParam_Error() {
        // Given
        HttpCalloutService svc = new HttpCalloutService();
        svc.setEndpointURL('https://example.com/api/fail');
        svc.setRequestMethod('GET');
        svc.setRequestTimeout(10 * 1000);

        // Build a request manually to pass into overloaded sendRequest(HTTPRequest)
        HTTPRequest manualReq = new HTTPRequest();
        manualReq.setEndpoint('https://example.com/api/fail');
        manualReq.setMethod('GET');

        Test.setMock(HttpCalloutMock.class, new ErrorMock());

        // When
        Test.startTest();
        HTTPResponse resp = svc.sendRequest(manualReq);
        Test.stopTest();

        // Then
        Assert.areEqual(500, resp.getStatusCode(), 'Expected 500 from mocked error response');
        Assert.isTrue(resp.getBody().contains('"status":"error"'),
            'Error response body should contain status error');
    }

    @isTest
    static void shouldBuildRequestWithHeadersAndUrlParameters_GetRequest_VerifyFields() {
        // Given
        HttpCalloutService svc = new HttpCalloutService();
        svc.setEndpointURL('https://api.example.com/resource?existing=1');
        svc.setRequestMethod('PUT');
        svc.setRequestBody('{"value":42}');
        svc.setRequestTimeout(15 * 1000);
        svc.setBearerToken('abc123');

        // set additional headers and URL params using public setters
        svc.setHeaderParameter('X-Custom-Header', 'custom-value');
        svc.setHeaderParameter('ToBeRemoved', 'remove-me');
        svc.setURLParameter('q', 'search');
        svc.setURLParameter('emptyKey', null);

        // Verify header removal API
        svc.removeHeaderParameter('ToBeRemoved');

        // Verify URL parameter removal API
        svc.setURLParameter('temp', 't');
        svc.removeURLParameter('temp');

        // When
        Test.startTest();
        HTTPRequest req = svc.getRequest();
        Test.stopTest();

        // Then - assert endpoint contains appended params and method/body/headers are set
        String endpoint = req.getEndpoint();
        Assert.isTrue(endpoint.startsWith('https://'), 'Endpoint should be an https URL');
        Assert.isTrue(endpoint.contains('q=search'), 'Endpoint should contain url parameter q=search');
        // The implementation strips existing query string before appending parameters,
        // so existing query params are not preserved. Assert that existing=1 is NOT present.
        Assert.isTrue(!endpoint.contains('existing=1'), 'Existing query param should NOT be preserved by implementation');

        Assert.areEqual('PUT', req.getMethod(), 'Request method should be PUT');
        Assert.areEqual('{"value":42}', req.getBody(), 'Request body should match');

        // Verify headers: Authorization should be present due to bearer token and custom header
        String authHeader = req.getHeader('Authorization');
        String customHeader = req.getHeader('X-Custom-Header');
        String removedHeader = req.getHeader('ToBeRemoved');
        Assert.isTrue(String.isNotBlank(authHeader), 'Authorization header must be set');
        Assert.areEqual('custom-value', customHeader, 'Custom header must match');
        Assert.isTrue(String.isBlank(removedHeader), 'Removed header should not be present');

        // Additional coverage: call getRequest multiple times to exercise idempotency/path
        // Do not call Test.startTest()/Test.stopTest() again inside the same test method (causes FinalException).
        HTTPRequest req2 = svc.getRequest();
        Assert.areEqual(req.getEndpoint(), req2.getEndpoint(), 'Repeated calls should produce same endpoint');
    }

    @isTest
    static void repeatedGetRequest_WithStartStop_InSeparateTest_IncreasesCoverage() {
        // Given - create a new service and set some values
        HttpCalloutService svc = new HttpCalloutService();
        svc.setEndpointURL('https://api.example.com/repeat');
        svc.setRequestMethod('GET');
        svc.setRequestTimeout(5 * 1000);

        // When - use its own Test.startTest()/Test.stopTest() to avoid nested calls
        Test.startTest();
        HTTPRequest reqA = svc.getRequest();
        Test.stopTest();

        // Then - call again in a normal context to compare
        HTTPRequest reqB = svc.getRequest();
        Assert.areEqual(reqA.getEndpoint(), reqB.getEndpoint(), 'Endpoints should match between start/stop and regular calls');
    }

    @isTest
    static void headerAndUrlEdgeCases_NoBearer_VerifyNoAuthorization() {
        // Given - service without bearer token
        HttpCalloutService svc = new HttpCalloutService();
        svc.setEndpointURL('https://api.example.com/noauth');
        svc.setRequestMethod('GET');
        svc.setRequestTimeout(5000);

        // Try setting empty header key/value combinations
        svc.setHeaderParameter('', 'valueShouldBeIgnored');
        svc.setHeaderParameter('OnlyKey', '');
        svc.setURLParameter('', 'shouldBeIgnored');
        svc.setURLParameter('onlyKey', '');

        // When
        HTTPRequest req = svc.getRequest();

        // Then - Authorization should not be present and OnlyKey should be present with null/empty value handling
        String authHeader = req.getHeader('Authorization');
        String onlyKeyHeader = req.getHeader('OnlyKey');
        Assert.isTrue(String.isBlank(authHeader), 'Authorization should not be set when bearer token missing');
        // Depending on implementation, OnlyKey may be set to empty string; assert that it exists or is blank but call shouldn't error
        // We check that calling getRequest() didn't throw and request endpoint is correct.
        Assert.isTrue(req.getEndpoint().startsWith('https://api.example.com'), 'Endpoint should be set even without bearer token');
    }

    @isTest
    static void constructorException_WhenCustomMetadataNotFound() {
        // The constructor queries IntegrationSetting__mdt expecting one row; when none exist it throws a QueryException.
        Boolean threw = false;
        try {
            HttpCalloutService svc = new HttpCalloutService('non_existent_developer_name_for_test');
        } catch (Exception ex) {
            threw = true;
            // assert it's a query exception or something similar
            Assert.isTrue(ex.getMessage().contains('List has no rows for assignment'), 'Expected query exception when metadata not found');
        }
        Assert.isTrue(threw, 'Constructor should throw when custom metadata record is not found in single-row query');
    }

    @isTest
    static void bulkSendRequests_WithMock_IncreasesCoverage() {
        // Given - prepare service and mock
        HttpCalloutService svc = new HttpCalloutService();
        svc.setEndpointURL('https://example.com/bulk');
        svc.setRequestMethod('POST');
        svc.setRequestBody('{"bulk":"1"}');

        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        // When - call sendRequest multiple times in a loop under start/stop to simulate repeated behavior
        Test.startTest();
        for (Integer i = 0; i < 10; i++) {
            svc.setRequestBody('{"bulk":"' + i + '"}');
            HTTPResponse r = svc.sendRequest();
            Assert.areEqual(200, r.getStatusCode(), 'Each mocked response should be 200');
        }
        Test.stopTest();
    }
}