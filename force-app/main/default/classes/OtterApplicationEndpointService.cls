public class OtterApplicationEndpointService {

    public static String validateOtterApplicationRequestBody(OtterApplicationRequestBodyWrapper requestBody){
        
        List<String> errorMessages = new List<String>();
    
        checkFieldIsNotBlank(requestBody.companyName, 'Company Name', errorMessages);
        checkFieldIsNotBlank(requestBody.email, 'Email', errorMessages);
        checkFieldIsNotBlank(requestBody.phone, 'Phone', errorMessages);
        checkListIsNotEmpty(requestBody.selectedProducts, 'Selected Products', errorMessages);
        checkFieldIsNotNull(requestBody.address, 'Address', errorMessages);
        checkFieldIsNotBlank(requestBody.address.street, 'Street', errorMessages);
        checkFieldIsNotBlank(requestBody.address.city, 'City', errorMessages);
        checkFieldIsNotBlank(requestBody.address.state, 'State', errorMessages);
        checkFieldIsNotBlank(requestBody.address.postalCode, 'Postal Code', errorMessages);
        checkFieldIsNotBlank(requestBody.address.country, 'Counry', errorMessages);
        checkFieldIsNotBlank(requestBody.personalFirstName, 'Personal First Name', errorMessages);
        checkFieldIsNotBlank(requestBody.personalLastName, 'Personal Last Name', errorMessages);
        checkProductsAreValid(requestBody.selectedProducts, errorMessages);

        return String.join(errorMessages, ', ');
    }

    private static void checkFieldIsNotBlank(String field, String fieldName, List<String> errorMessages) {
        if (String.isBlank(field)) {
            errorMessages.add(fieldName + ' cannot be empty');
        }
    }

    private static void checkFieldIsNotNull(Object field, String fieldName, List<String> errorMessages) {
        if (field == null) {
            errorMessages.add(fieldName + ' cannot be empty');
        }
    }

    private static void checkListIsNotEmpty(List<Object> objectList, String fieldName, List<String> errorMessages) {
        if (objectList.isEmpty()) {
            errorMessages.add(fieldName + ' cannot be empty');
        }
    }

    private static void checkProductsAreValid(List<OtterApplicationRequestBodyWrapper.ProductWrapper> products, List<String> errorMessages) {

        for (OtterApplicationRequestBodyWrapper.ProductWrapper product : products) {
            if (String.isBlank(product.uuid)) {
                errorMessages.add('Product UUID cannot be empty');
                break;
            }
            if (product.quantity == null || product.quantity == 0) {
                errorMessages.add('Product quantity cannot be null or 0 for ' + product.uuid);
            }
        }
    }

    public static String checkIfProductUuidsAreValid(Set<String> wrapperProductUuids, List<Product2> availableProducts){

        List<String> invalidUuids = new List<String>();
        Set<String> availableProductUuids = new Set<String>();

        if(!availableProducts.isEmpty()){
            for(Product2 product : availableProducts){
                availableProductUuids.add(product.ExternalId);
            }
        }

        for(String uuid : wrapperProductUuids){
            if(!availableProductUuids.contains(uuid)){
                invalidUuids.add(uuid);
            }
        }

        return String.join(new List<String>(invalidUuids), ', ');
    }

    public static String createAccountWithOpportunityAndContact(OtterApplicationRequestBodyWrapper requestBody, List<Product2> availableProducts, List<OtterApplicationRequestBodyWrapper.ProductWrapper> wrapperProducts){

        String accountId;

        // How to determine which pricebook to use
        List<Pricebook2> priceBooks = [SELECT Id, Name FROM Pricebook2 WHERE Name =: GlobalConstants.STANDARD_PRICE_BOOK];

        if(priceBooks.isEmpty()){return null;}

        // Use fflib framework's SObject Unit of Work pattern to centralise all database activities

        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<Schema.SObjectType>{
            Account.sObjectType,
            Contact.sObjectType,
            Opportunity.sObjectType,
            OpportunityContactRole.sObjectType,
            OpportunityLineItem.sObjectType});

        // Create a new account
        Account newAccount = prepareAccount(requestBody);
        uow.registerNew(newAccount);

        // Create a new contact for the account    
        Contact newContact = prepareContact(requestBody);

        uow.registerRelationship(newContact, Contact.AccountId, newAccount);
        uow.registerNew(newContact);

        // Create a new opportunity contact role for the contact and opportunity
        Opportunity newOpportunity = prepareOpportunity(requestBody,priceBooks[0].Id);

        uow.registerRelationship(newOpportunity, Opportunity.AccountId, newAccount);
        uow.registerNew(newOpportunity);
        
        // Create a new opportunity contact role for the contact and opportunity
        OpportunityContactRole newContactRole = new OpportunityContactRole(isPrimary = true);
        uow.registerRelationship(newContactRole, OpportunityContactRole.ContactId, newContact);
        uow.registerRelationship(newContactRole, OpportunityContactRole.OpportunityId, newOpportunity);
        uow.registerNew(newContactRole);

        uow = prepareOpportunityProducts(wrapperProducts,priceBooks[0].Id,newOpportunity,uow,availableProducts);

        uow.commitWork();
        return newAccount.Id;
    }

    public static Account prepareAccount(OtterApplicationRequestBodyWrapper requestBody){
        Account newAccount = new Account(
            Name = requestBody.companyName,
            Phone = requestBody.phone,
            BillingStreet = requestBody.address.street,
            BillingCity = requestbody.address.city,
            BillingState = requestBody.address.city,
            BillingPostalCode = requestBody.address.postalCode,
            BillingCountry = requestBody.address.country
        );

        return newAccount;
    }

    public static Contact prepareContact(OtterApplicationRequestBodyWrapper requestBody){
        Contact newContact = new Contact(
            FirstName = requestBody.personalFirstName,
            LastName = requestBody.personalLastName,
            MailingStreet = requestBody.address.street,
            MailingCity = requestbody.address.city,
            MailingState = requestBody.address.state,
            MailingPostalCode = requestBody.address.postalCode,
            MailingCountry = requestBody.address.country,
            Phone = requestBody.phone,
            Email = requestBody.Email
        );

        return newContact;
    }

    public static Opportunity prepareOpportunity(OtterApplicationRequestBodyWrapper requestBody, Id priceBookId){
        Opportunity newOpportunity = new Opportunity(
            Name = requestBody.companyName,
            StageName = 'Closed Lost',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = priceBookId
        );

        return newOpportunity;
    }

    public static fflib_SObjectUnitOfWork prepareOpportunityProducts(List<OtterApplicationRequestBodyWrapper.ProductWrapper> selectedProducts,Id priceBookId, 
    Opportunity opportunity, fflib_SObjectUnitOfWork uow, List<Product2> productsToUse){

        Map<String, Integer> quantityByUuid = new Map<String, Integer>();
        List<OpportunityLineItem> opportunityProducts = new List<OpportunityLineItem>();
        Map<String, Product2> productsByExternalId = new Map<String, Product2>();
        List<Product2> availableProducts = productsToUse;

        for (OtterApplicationRequestBodyWrapper.ProductWrapper wrapperProduct : selectedProducts) {
            quantityByUuid.put(wrapperProduct.uuid, wrapperProduct.quantity);
        }
        if(availableProducts.isEmpty()){
            availableProducts = [SELECT Id, Name , ExternalId FROM Product2 WHERE ExternalId IN: quantityByUuid.keySet()];
        }
        
        for (Product2 product : availableProducts) {
            productsByExternalId.put(product.ExternalId, product);
        }

        List<PricebookEntry> priceBookEntries = [SELECT Id, Product2Id,UnitPrice FROM PricebookEntry WHERE Pricebook2Id =:  priceBookId AND Product2.ExternalId IN : quantityByUuid.keySet()];
        Map<Id, PricebookEntry> priceBookEntryByProductId = new Map<Id,PricebookEntry>();

        for(PricebookEntry pbEntry : priceBookEntries){
            priceBookEntryByProductId.put(pbEntry.Product2Id,pbEntry);
        }

        for(Product2 product : availableProducts){
            Integer quantity = quantityByUuid.get(product.ExternalId);
            PricebookEntry pbEntry = priceBookEntryByProductId.get(product.Id);
            OpportunityLineItem lineItem = new OpportunityLineItem(
                Product2Id = product.Id,
                Quantity = quantity,
                PricebookEntryId = pbEntry.Id,
                UnitPrice = pbEntry.UnitPrice
            );
            uow.registerRelationship(lineItem, OpportunityLineItem.OpportunityId, opportunity);
            opportunityProducts.add(lineItem);
        }

        uow.registerNew(opportunityProducts);

        return uow;
    }
}