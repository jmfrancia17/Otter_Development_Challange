trigger LeadTrigger on Lead (before insert) {
    LeadTriggerHandler handler = new LeadTriggerHandler();
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            handler.beforeInsert(Trigger.new);
        }
    }
}