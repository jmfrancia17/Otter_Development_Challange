@isTest
private class AccountTriggerHelper_Test {
    @TestSetup
    static void prepareData(){
        Lead newLeadRec = TestDataFactory.prepareLead();
        insert newLeadRec;
    }

    @isTest
    static void testCheckForExistingLead(){
        Account accountRec = TestDataFactory.prepareAccount();
        accountRec.Name = 'Test Company';

        Test.startTest();
            try{
                insert accountRec;
            }
            catch(Exception e){
                System.assertEquals(true, e.getMessage().contains('A Lead with the same Company name already exists. Please convert the existing Lead instead of creating a new Account.'), 'Wrong error message thrown');
            }
        Test.stopTest();

        List<Account> createdAccounts = [SELECT Id FROM Account];
        System.assertEquals(0, createdAccounts.size(), 'There should be no created accounts');
    }
}