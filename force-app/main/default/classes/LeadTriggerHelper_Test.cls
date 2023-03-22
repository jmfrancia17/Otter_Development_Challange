@isTest
private class LeadTriggerHelper_Test {
    @TestSetup
    static void prepareData(){
        Account newAccountRec = TestDataFactory.prepareAccount();
        newAccountRec.Name = 'Test Company';
        insert newAccountRec;
    }

    @isTest
    static void testCheckForExistingLead(){
        Lead newLeadRec = TestDataFactory.prepareLead();

        Test.startTest();
            try{
                insert newLeadRec;
            }
            catch(Exception e){
                System.assertEquals(true, e.getMessage().contains('An Account with the same Name as the Lead\'s company name is already existing.'), 'Wrong error message thrown');
            }
        Test.stopTest();

        List<Lead> createdLeads = [SELECT Id FROM Lead];
        System.assertEquals(0, createdLeads.size(), 'There should be no created leads');
    }
}