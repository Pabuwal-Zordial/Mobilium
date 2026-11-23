trigger AccountTriggerS on Account (before insert, before update, after insert, after update, before delete) {
    if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate))
    {
   //  AccountHandlerS.valid(trigger.new);
    }
    if(trigger.isAfter && trigger.isInsert)
    {
//AccountHandlerS.Acccontact(trigger.new);
//AccountHandlerS.CreateContact(trigger.new);
}
     if(trigger.isAfter && trigger.isUpdate)
    {
AccountTriggerHelper.phoneCase(trigger.new , trigger.oldMap);
}
         if(trigger.isBefore && trigger.isInsert)
    {
//AccountHandlerS.updateAcc(trigger.new);
}
    
    
    
}