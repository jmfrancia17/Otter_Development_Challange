public class LeadTriggerHelper {
    public static void checkForExistingAccounts(List<Lead> newLeads){
        try{    
            Set<String> leadCompanyNames = new Set<String>();
            Set<String> accountNames = new Set<String>();

            for(Lead leadRec : newLeads){
                if(!leadRec.IsConverted){
                    leadCompanyNames.add(leadRec.Company);
                }
            }

            if(leadCompanyNames.isEmpty()){return;}

            List<Account> accounts = [SELECT Id, Name FROM Account WHERE Name IN : leadCompanyNames];

            if(accounts.isEmpty()){return;}

            for(Account accountRec : accounts){
                accountNames.add(accountRec.Name);
            }

            for(Lead leadRec : newLeads){
                if(accountNames.contains(leadRec.Company)){
                    leadRec.addError('An Account with the same Name as the Lead\'s company name is already existing.');
                }
            }
        }
        catch(Exception e){

        }
    }
}