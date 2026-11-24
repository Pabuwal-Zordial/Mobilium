trigger CTpersonTrigger on Person__c (before insert, before update) {
    if(trigger.isInsert && Trigger.Isbefore)
    {
   CTPersonTriggerHandler.beforeperson(trigger.new);
    }
    if(trigger.Isbefore && trigger.isUpdate)
    {
       CTPersonTriggerHandler.afterupdate(trigger.new, trigger.oldmap);
    }
    

}