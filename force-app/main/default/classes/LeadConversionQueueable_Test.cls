@isTest
private class LeadConversionQueueable_Test {

    private static final Integer GENERATOR_LENGTH = 5;

    @TestSetup
    static void prepareData(){
        Lead newLeadRec = TestDataFactory.prepareLead();
        insert newLeadRec;

        Account accountRec = TestDataFactory.prepareAccount();
        insert accountRec;

        Contact contactRec = TestDataFactory.prepareContact();
        contactRec.AccountId = accountRec.Id;
        insert contactRec;

        Opportunity opportunityRec = TestDataFactory.prepareOpportunity();
        opportunityRec.AccountId = accountRec.Id;
        insert opportunityRec;

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
    }

    @isTest
    static void testLeadConversionQueueable() {
        // Create test data

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
        List<Lead> leadRecords = [SELECT Id,Name FROM Lead];

        String requestBodyString = TestDataFactory.prepareValidRequestBodyForOtter(leadRecords[0].Name, 
                                    TestDataFactory.generateRandomString(GENERATOR_LENGTH) + '@yacorp.com', 
                                    TestDataFactory.generateRandomString(GENERATOR_LENGTH), 
                                    selectedProducts, 
                                    address, 
                                    TestDataFactory.generateRandomString(GENERATOR_LENGTH), 
                                    TestDataFactory.generateRandomString(GENERATOR_LENGTH));

        OtterApplicationRequestBodyWrapper requestBody = OtterApplicationRequestBodyWrapper.deserialize(requestBodyString);

        // Create the LeadConversionQueueable instance
        LeadConversionQueueable queueable = new LeadConversionQueueable(leadRecords, requestBody, GlobalConstants.SOURCE_OTTER_APPLICATION_ENDPOINT);

        // Execute the test asynchronously
        Test.startTest();
            System.enqueueJob(queueable);
        Test.stopTest();

        // Verify that leads have been converted
        List<Lead> convertedLeads = [SELECT Id, IsConverted FROM Lead WHERE Id IN :leadRecords];
        for (Lead lead : convertedLeads) {
            System.assert(lead.IsConverted, 'The lead should be converted');
        }
    }

    @isTest
    static void testOtterApplicationConvertedLeadQueueable() {
        // Create test data

        Map<Id, Account> accountById = new Map<Id, Account>([SELECT Id FROM Account LIMIT 1]);
        List<Id> accountIds = new List<Id>(accountById.keySet());

        Map<Id, Contact> contactById = new Map<Id, Contact>([SELECT Id FROM Contact LIMIT 1]);
        List<Id> contactIds = new List<Id>(contactById.keySet());

        Map<Id, Opportunity> opportunityById = new Map<Id, Opportunity>([SELECT Id FROM Opportunity LIMIT 1]);
        List<Id> opportunityIds = new List<Id>(opportunityById.keySet());
        
        List<Map<String, Object>> selectedProducts = new List<Map<String, Object>>{
            new Map<String, Object>{'uuid' => 'test-uuid-1', 'quantity' => 2}
        };
        Map<String, String> address = new Map<String, String>{
            'street' => 'Street',
            'city' => 'City',
            'state' => 'State',
            'postalCode' => '3020',
            'country' => 'PH'
        };

        String requestBodyString = TestDataFactory.prepareValidRequestBodyForOtter('Test Company', 
                                    'testing@yacorp.com', 
                                    '123-4567', 
                                    selectedProducts, 
                                    address, 
                                    'John', 
                                    'Test Contact');

        OtterApplicationRequestBodyWrapper requestBody = OtterApplicationRequestBodyWrapper.deserialize(requestBodyString);

        // Create the OtterApplicationConvertedLeadQueueable instance
        OtterApplicationConvertedLeadQueueable queueable = new OtterApplicationConvertedLeadQueueable(accountIds, contactIds, opportunityIds, requestBody);

        // Execute the test asynchronously
        Test.startTest();
            System.enqueueJob(queueable);
        Test.stopTest();
        
        List<Opportunity> updatedOpportunity = [SELECT Id, StageName FROM Opportunity WHERE Id IN: opportunityIds];
        System.assertEquals('Closed Lost', updatedOpportunity[0].StageName);

        List<OpportunityLineItem> oli = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId IN : opportunityIds];
        System.assertNotEquals(null, oli);

        List<Contact> updatedContacts = [SELECT Id, Email, MailingStreet, MailingCity,MailingState , MailingPostalCode, MailingCountry FROM Contact WHERE Id IN : contactIds];

        for(Contact con : updatedContacts){
            System.assertEquals('Street', con.MailingStreet);
            System.assertEquals('City', con.MailingCity);
            System.assertEquals('State', con.MailingState);
            System.assertEquals('3020', con.MailingPostalCode);
            System.assertEquals('PH', con.MailingCountry);
            System.assertEquals('testing@yacorp.com', con.Email);
        }
    }
}