public class AccountTriggerHelper {

    public static void checkForExistingLead(List<Account> accounts){
        try{
            Set<String> accountNames = new Set<String>();
            Set<String> companyNames = new Set<String>();
            for(Account account : accounts){
                accountNames.add(account.Name);
            }

            List<Lead> leads = [SELECT Id, Name,Company FROM Lead WHERE Company IN: accountNames AND IsConverted = false];

            if(leads.isEmpty()){return;}

            for(Lead leadRec : leads){
                companyNames.add(leadRec.Company);
            }

            for(Account account : accounts){
                if(companyNames.contains(account.Name)){
                    account.addError('A Lead with the same Company name already exists. Please convert the existing Lead instead of creating a new Account.');
                }
            }
        }
        catch(Exception e){
            //create an object that will store  all of Exceptions
        }
    }
}