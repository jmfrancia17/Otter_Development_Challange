public class AccountTriggerHandler {
    public void beforeInsert(List<Account> newAccounts){
        //For this scenario we can use flow and standard duplicate rules as well
        //We also need to consider update of account names and throw an error as well if updated name = existing non converted lead.
        AccountTriggerHelper.checkForExistingLead(newAccounts);
    }
}