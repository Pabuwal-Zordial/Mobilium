trigger ContactTrigger on Contact (after insert, after update, after delete,before delete, after undelete, before insert, before update) {
  if((trigger.isInsert || trigger.isundelete ) && trigger.isafter)
  {
   
      ContactTriggerHandler.checkCounter(trigger.new, null);
   // ContactTriggerHandler.getContacts(trigger.new, null);
    //  CalculateCountContact.GetContactsCount(trigger.new, null);
           
  }
     if( trigger.isdelete  && trigger.isafter)
     {
         ContactTriggerHandler.checkCounter(trigger.old, null);
       //ContactTriggerHandler.primaryContact(trigger.new);
     }
    if((trigger.isupdate && trigger.isAfter))
    {
        //ContactTriggerHandler.getCountAccUpdate(trigger.new, trigger.oldMap);
         ContactTriggerHandler.checkCounter(trigger.new, trigger.oldMap);
        
      //  ContactTriggerHandler.updateCheckContact(trigger.new, trigger.oldmap);
       //ContactTriggerHandler.getError(trigger.new);
      //  ContactTriggerHandler.getCount(trigger.new, trigger.oldmap);
      //  ContactTriggerHandler.checkDuplicate(trigger.new, trigger.oldmap);
    //  ContactTriggerHandler.getConDescription(trigger.new, trigger.oldmap);
    // ContactTriggerHandler.getContacts(trigger.new, trigger.oldmap);
   // CalculateCountContact.GetContactsCount(trigger.new, trigger.oldmap);
    }
        if(trigger.isdelete && trigger.isBefore)
        {
         //   ContactTriggerHandler.afterDelete(trigger.old);
          ContactTriggerHandler.checkCase(trigger.old);  
            // ContactTriggerHandler.getCount(trigger.old, null);
//ContactTriggerHandler.deleteRecords(trigger.old);
//CalculateCountContact.GetContactsCount(trigger.old, null);
        }
        if(trigger.isundelete && trigger.isafter)
        {
          //  ContactTriggerHandler.afterunDelete(trigger.new);
        }

}