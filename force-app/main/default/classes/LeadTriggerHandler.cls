public class LeadTriggerHandler {
    public void beforeInsert(List<Lead> newLeads){
        //For this scenario we can use flow and standard duplicate rules as well
        //We also need to consider update of Company Names and throw an error as well if updated name = existing account record.

        LeadTriggerHelper.checkForExistingAccounts(newLeads);
    }
}