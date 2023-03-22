public class LeadConversionQueueable implements Queueable {
    private final List<Lead> leadRecords;
    private final OtterApplicationRequestBodyWrapper requestBody;
    private final String source;

    public LeadConversionQueueable(List<Lead> leadRecords, OtterApplicationRequestBodyWrapper requestBody, String source) {
        this.leadRecords = leadRecords;
        this.requestBody = requestBody;
        this.source = source;
    }

    public void execute(QueueableContext QContext) {
        try {
            List<Database.LeadConvert> leadConvertList = new List<Database.LeadConvert>();
            for (Lead lead : leadRecords) {
                // Create a LeadConvert object
                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(lead.Id);

                // Set the conversion parameters
                lc.setConvertedStatus('Closed - Converted');
                lc.setDoNotCreateOpportunity(false);

                leadConvertList.add(lc);
            }

            // Convert the Leads and get the converted Account, Contact, and Opportunity records
            List<Database.LeadConvertResult> lcrList = Database.convertLead(leadConvertList);
            List<Id> accountIds = new List<Id>();
            List<Id> contactIds = new List<Id>();
            List<Id> opportunityIds = new List<Id>();

            for (Database.LeadConvertResult lcr : lcrList) {
                accountIds.add(lcr.getAccountId());
                contactIds.add(lcr.getContactId());
                opportunityIds.add(lcr.getOpportunityId());
            }
            

            executeNext(accountIds, contactIds, opportunityIds);

        } catch(Exception e) {
            //create an object that will store  all of Exceptions
            //send an http post to the sender api that there was an error encountered
        }
    }

    public void executeNext(List<Id> accountIds, List<Id> contactIds, List<Id> opportunityIds) {
        if(source == GlobalConstants.SOURCE_OTTER_APPLICATION_ENDPOINT){
            OtterApplicationConvertedLeadQueueable queueable = new OtterApplicationConvertedLeadQueueable(accountIds, contactIds,opportunityIds,requestBody);
            System.enqueueJob(queueable);
        }

        // for reusability , just add a source name and handle here
    }
}