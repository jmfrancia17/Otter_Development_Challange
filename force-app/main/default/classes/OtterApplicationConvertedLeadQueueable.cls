public class OtterApplicationConvertedLeadQueueable implements Queueable{
    private final List<Id> accountIds;
    private final List<Id> contactIds;
    private final List<Id> opportunityIds;
    OtterApplicationRequestBodyWrapper requestBody;

    public OtterApplicationConvertedLeadQueueable(List<Id> accountIds, List<Id> contactIds,List<Id> opportunityIds,OtterApplicationRequestBodyWrapper requestBody) {
        this.accountIds = accountIds;
        this.contactIds = contactIds;
        this.opportunityIds = opportunityIds;
        this.requestBody = requestBody;
    }

    public void execute(QueueableContext QContext) {
        try {
            if (!accountIds.isEmpty() && !contactIds.isEmpty() && !opportunityIds.isEmpty() && requestBody != null) {

                // Use fflib framework's SObject Unit of Work pattern

                fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<Schema.SObjectType>{
                    Account.sObjectType,
                    Contact.sObjectType,
                    Opportunity.sObjectType,
                    OpportunityLineItem.sObjectType});
                

                List<OtterApplicationRequestBodyWrapper.ProductWrapper> selectedProducts = requestBody.selectedProducts;
                List<Pricebook2> priceBooks = [SELECT Id, Name FROM Pricebook2 WHERE Name =: GlobalConstants.STANDARD_PRICE_BOOK];

                Account updatedAccount = OtterApplicationEndpointService.prepareAccount(requestBody);
                updatedAccount.Id = accountIds[0];
                uow.registerDirty(updatedAccount);

                Contact updatedContact = OtterApplicationEndpointService.prepareContact(requestBody);
                updatedContact.Id = contactIds[0];
                uow.registerDirty(updatedContact);
                
                Opportunity updatedOpportunity = OtterApplicationEndpointService.prepareOpportunity(requestBody, priceBooks[0].Id);
                updatedOpportunity.Id = opportunityIds[0];
                uow.registerDirty(updatedOpportunity);

                uow = OtterApplicationEndpointService.prepareOpportunityProducts(selectedProducts,priceBooks[0].Id,updatedOpportunity,uow, new List<Product2>());

                uow.commitWork();
            }
        } catch (Exception e) {
            //create an object that will store  all of Exceptions
            //send an http post to the sender api that there was an error encountered
        }
    }
}