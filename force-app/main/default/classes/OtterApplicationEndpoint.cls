@RestResource(urlMapping='/OtterApplicationEndpoint/*')
global class OtterApplicationEndpoint {

    @HttpPost
    global static ApplicationResponse createOtterApplication() {
        ApplicationResponse applicationResponse = new ApplicationResponse();
        applicationResponse.status = 'New';
        applicationResponse.debug = 'Created';
    
        try {
            OtterApplicationRequestBodyWrapper requestBody = OtterApplicationRequestBodyWrapper.deserialize(RestContext.request.requestBody.toString());
            handleOtterApplicationRequest(applicationResponse, requestBody);
        } catch (JSONException e) {
            RestContext.response.statusCode = 400; // Bad Request
            applicationResponse.status = 'Error';
            applicationResponse.debug = 'Parsing Error/Invalid JSON request body';
        } catch (APIException e) {
            RestContext.response.statusCode = 400; // Bad Request
            applicationResponse.status = 'Error';
            applicationResponse.debug = e.getMessage();
        } catch (Exception e) {
            RestContext.response.statusCode = 500; // Internal Server Error
            applicationResponse.status = 'Error';
            applicationResponse.debug = 'Unhandled Error : ' + e.getMessage();
        }
    
        return applicationResponse;
    }
    
    private static void handleOtterApplicationRequest(ApplicationResponse applicationResponse, OtterApplicationRequestBodyWrapper requestBody) {
        
        //throw an error if any field is missing, I assumed that all fields would be required;
        String errorMessage = OtterApplicationEndpointService.validateOtterApplicationRequestBody(requestBody);
        if (String.isNotBlank(errorMessage)) {
            throw New APIException(errorMessage);
        }
    
        Set<String> wrapperProductUuids = new Set<String>();
    
        applicationResponse.companyName = String.isNotBlank(requestBody.companyName) ? requestBody.companyName : '';
        List<Account> matchedAccount = [SELECT Id, Name FROM Account WHERE Name =: requestBody.companyName];
        
        //throw an error if account is already existing
        handleMatchedAccounts(matchedAccount,applicationResponse);
    
        List<OtterApplicationRequestBodyWrapper.ProductWrapper> selectedProducts = requestBody.selectedProducts;
    
        for(OtterApplicationRequestBodyWrapper.ProductWrapper wrapperProduct : selectedProducts){
            wrapperProductUuids.add(wrapperProduct.uuid);       
        }
        
        // validate if uuids are existing in salesforce org, if not throw an error. This is all or nothing.
        // let's say client requested for 10 products, if one product is invalid it would throw an error.
        List<Product2> availableProducts = [SELECT Id, Name, ExternalId FROM Product2 WHERE ExternalId IN: wrapperProductUuids];
        validateProductUuids(wrapperProductUuids, availableProducts);
        
        // call queable if there are any matched leads. We're leveraging here chaining of queaueable jobs to minimize cpu limits per request.
        List<Lead> matchedLeads = [SELECT Id, Company FROM Lead WHERE Company =: requestBody.companyName];
        handleMatchedLeads(matchedLeads, requestBody, applicationResponse);
    
        if (matchedAccount.isEmpty() && matchedLeads.isEmpty()) {
            //create account contact and opportunity if matched accounts and matched leads are empty
            applicationResponse.accountId = OtterApplicationEndpointService.createAccountWithOpportunityAndContact(requestBody, availableProducts, requestBody.selectedProducts);
            RestContext.response.statusCode = 200; //Success
        }
    }
    
    
    private static void handleMatchedAccounts(List<Account> matchedAccount, ApplicationResponse applicationResponse) {
        if (!matchedAccount.isEmpty()) {
            applicationResponse.accountId = matchedAccount[0].Id;
            throw New APIException('Account already existing.');
        }
    }
    
    private static void validateProductUuids(Set<String> wrapperProductUuids, List<Product2> availableProducts) {
        if (availableProducts.isEmpty()) {
            throw New APIException('UUIDs provided are not valid');
        }
    
        String invalidProductUuid = OtterApplicationEndpointService.checkIfProductUuidsAreValid(wrapperProductUuids, availableProducts);
        if (String.isNotBlank(invalidProductUuid)) {
            throw New APIException('Invalid UUIDs: ' + invalidProductUuid);
        }
    }
    
    private static void handleMatchedLeads(List<Lead> matchedLeads, OtterApplicationRequestBodyWrapper requestBody, ApplicationResponse applicationResponse){
        if(!matchedLeads.isEmpty()){
            LeadConversionQueueable queueable = new LeadConversionQueueable(matchedLeads, requestBody,GlobalConstants.SOURCE_OTTER_APPLICATION_ENDPOINT);
            System.enqueueJob(queueable);
            applicationResponse.debug = 'Lead conversion in progress';
            RestContext.response.statusCode = 200; //Success
        }
    }

    global class ApplicationResponse {
        global String status;
        global String companyName;
        global String accountId;
        global String debug;
    } 

    global class APIException extends Exception {}
}