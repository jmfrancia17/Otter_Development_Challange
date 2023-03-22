public class TestDataFactory {
    private static final Integer GENERATOR_LENGTH = 5;
    
    public static Product2 prepareProduct(){
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ExternalId = 'test-uuid-1',
            isActive = true
        );

        return testProduct;
    }

    public static priceBookEntry preparePriceBookEntry(){
        PricebookEntry standardPricebookEntry = new PricebookEntry(
            // Pricebook2Id = standardPricebookId,
            UnitPrice = 100.0,
            IsActive = true
        );

        return standardPricebookEntry;
    }

    public static Account prepareAccount() {
        Account newAccount = new Account(
            Name = 'Test Account'
        );

        return newAccount;
    }

    public static Contact prepareContact() {
        Contact newContact = new Contact(
            LastName = 'Test Contact',
            FirstName = 'John',
            Email = 'testingcontact@yacorp.com'
        );
        return newContact;
    }

    public static Opportunity prepareOpportunity() {
        Opportunity newOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 10000.00
        );
        return newOpportunity;
    }

    public static Lead prepareLead() {
        Lead newLead = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Email = 'TestingLead@yacorp.com'
        );

        return newLead;
    }

    public static String generateRandomString(Integer length) {
        String characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
        Integer charactersLength = characters.length();
        String result = '';

        for(Integer i = 0; i < length; i++) {
            Integer randomIndex = Math.mod(Math.abs(Crypto.getRandomInteger()), charactersLength);
            result += characters.substring(randomIndex, randomIndex + 1);
        }

        return result;
    }

    public static String prepareValidRequestBodyForOtter(String companyName, String email, String phone, List<Map<String, Object>> selectedProducts, Map<String, String> address, String personalFirstName, String personalLastName) {
        Map<String, Object> requestBody = new Map<String, Object>{
            'companyName' => companyName,
            'email' => email,
            'phone' => phone,
            'selectedProducts' => selectedProducts,
            'address' => address,
            'personalFirstName' => personalFirstName,
            'personalLastName' => personalLastName
        };
    
        return JSON.serialize(requestBody);
    }
}