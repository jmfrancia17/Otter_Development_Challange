@isTest
private class OtterApplicationEndpoint_Test {

    private static final Integer GENERATOR_LENGTH = 5;
    private static final String OTTER_ENDPOINT = '/services/apexrest/OtterApplicationEndpoint';

    @TestSetup
    static void prepareData(){

        Id standardPricebookId = Test.getStandardPricebookId();

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            Name = GlobalConstants.STANDARD_PRICE_BOOK
        );

        update standardPricebook;

        Product2 testProduct = TestDataFactory.prepareProduct();
        insert testProduct;

        PricebookEntry pbEntry = TestDataFactory.preparePriceBookEntry();
        pbEntry.Product2Id = testProduct.Id;
        pbEntry.Pricebook2Id = standardPricebook.Id;
        insert pbEntry;
        
        Account newAccount = TestDataFactory.prepareAccount();
        insert newAccount;

        Lead leadRec = TestDataFactory.prepareLead();
        insert leadRec;

        //            Pricebook2Id = standardPricebookId,
    }

    @isTest
    static void testCreateOtterApplication() {

        List<Map<String, Object>> selectedProducts = new List<Map<String, Object>>{
            new Map<String, Object>{'uuid' => 'test-uuid-1', 'quantity' => 2}
        };
        Map<String, String> address = new Map<String, String>{
            'street' => TestDataFactory.generateRandomString(GENERATOR_LENGTH),
            'city' => TestDataFactory.generateRandomString(GENERATOR_LENGTH),
            'state' => TestDataFactory.generateRandomString(GENERATOR_LENGTH),
            'postalCode' => TestDataFactory.generateRandomString(GENERATOR_LENGTH),
            'country' => TestDataFactory.generateRandomString(GENERATOR_LENGTH)
        };

        // Prepare test data
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = OTTER_ENDPOINT;
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(TestDataFactory.prepareValidRequestBodyForOtter(TestDataFactory.generateRandomString(GENERATOR_LENGTH), 
                                                                TestDataFactory.generateRandomString(GENERATOR_LENGTH) + '@yacorp.com', 
                                                                TestDataFactory.generateRandomString(GENERATOR_LENGTH), 
                                                                selectedProducts, 
                                                                address, 
                                                                TestDataFactory.generateRandomString(GENERATOR_LENGTH), 
                                                                TestDataFactory.generateRandomString(GENERATOR_LENGTH)));

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
            OtterApplicationEndpoint.ApplicationResponse response = OtterApplicationEndpoint.createOtterApplication();
        Test.stopTest();

        // Assert the response
        System.assertEquals('New', response.status);
        System.assertNotEquals(null, response.companyName);
        System.assertNotEquals(null, response.accountId);
        System.assertEquals('Created', response.debug);
    }

    @isTest
    static void testInvalidRequestBody() {
        // Prepare test data
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = OTTER_ENDPOINT;
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{ "invalid": "request }');

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
            OtterApplicationEndpoint.ApplicationResponse response = OtterApplicationEndpoint.createOtterApplication();
        Test.stopTest();

        // Assert the response
        System.assertEquals('Error', response.status);
        System.assertEquals('Parsing Error/Invalid JSON request body', response.debug);
    }

    @isTest
    static void testRequiredChecker(){
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = OTTER_ENDPOINT;
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(TestDataFactory.prepareValidRequestBodyForOtter('', '', '', new List<Map<String, Object>>(), new Map<String, String>(), '', ''));

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
            OtterApplicationEndpoint.ApplicationResponse response = OtterApplicationEndpoint.createOtterApplication();
        Test.stopTest();

        System.assertEquals('Error', response.status);
        System.assertEquals(400, res.statusCode);
    }
    @isTest
    static void testMatchedAccount(){
        List<Map<String, Object>> selectedProducts = new List<Map<String, Object>>{
            new Map<String, Object>{'uuid' => 'test-uuid-1', 'quantity' => 2}
        };
        Map<String, String> address = new Map<String, String>{
            'street' => TestDataFactory.generateRandomString(GENERATOR_LENGTH),
            'city' => TestDataFactory.generateRandomString(GENERATOR_LENGTH),
            'state' => TestDataFactory.generateRandomString(GENERATOR_LENGTH),
            'postalCode' => TestDataFactory.generateRandomString(GENERATOR_LENGTH),
            'country' => TestDataFactory.generateRandomString(GENERATOR_LENGTH)
        };

        // Prepare test data
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = OTTER_ENDPOINT;
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(TestDataFactory.prepareValidRequestBodyForOtter('Test Account', 
                                                                TestDataFactory.generateRandomString(GENERATOR_LENGTH) + '@yacorp.com', 
                                                                TestDataFactory.generateRandomString(GENERATOR_LENGTH), 
                                                                selectedProducts, 
                                                                address, 
                                                                TestDataFactory.generateRandomString(GENERATOR_LENGTH), 
                                                                TestDataFactory.generateRandomString(GENERATOR_LENGTH)));

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
            OtterApplicationEndpoint.ApplicationResponse response = OtterApplicationEndpoint.createOtterApplication();
        Test.stopTest();

        System.assertEquals(400, res.statusCode);
        System.assertEquals('Error', response.status);
        System.assertEquals('Account already existing.', response.debug);
    }

    @isTest
    static void testMatchedLead(){
        List<Map<String, Object>> selectedProducts = new List<Map<String, Object>>{
            new Map<String, Object>{'uuid' => 'test-uuid-1', 'quantity' => 2}
        };
        Map<String, String> address = new Map<String, String>{
            'street' => TestDataFactory.generateRandomString(GENERATOR_LENGTH),
            'city' => TestDataFactory.generateRandomString(GENERATOR_LENGTH),
            'state' => TestDataFactory.generateRandomString(GENERATOR_LENGTH),
            'postalCode' => TestDataFactory.generateRandomString(GENERATOR_LENGTH),
            'country' => TestDataFactory.generateRandomString(GENERATOR_LENGTH)
        };

        // Prepare test data
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = OTTER_ENDPOINT;
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(TestDataFactory.prepareValidRequestBodyForOtter('Test Company', 
                                                                TestDataFactory.generateRandomString(GENERATOR_LENGTH) + '@yacorp.com', 
                                                                TestDataFactory.generateRandomString(GENERATOR_LENGTH), 
                                                                selectedProducts, 
                                                                address, 
                                                                TestDataFactory.generateRandomString(GENERATOR_LENGTH), 
                                                                TestDataFactory.generateRandomString(GENERATOR_LENGTH)));

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
            OtterApplicationEndpoint.ApplicationResponse response = OtterApplicationEndpoint.createOtterApplication();
        Test.stopTest();
    }
}