trigger casetrigger on Case (before insert, before update, before delete, after insert,after delete, after undelete, after update) {
    
     if(trigger.isbefore && trigger.isInsert){
      //   EscalationCase.CheckBilling(trigger.new);
        // EscalationCase.createCase(trigger.new);
          EscalationCase.DupCheck(trigger.new);
         
             //EscalationCase.ValidateEmail(trigger.new, null);
         
     }
    if(trigger.isAfter && (trigger.isInsert|| trigger.isundelete)){
       //EscalationCase.getHighestNumber(trigger.new, null);
        }
     if(trigger.isbefore && trigger.isUpdate){
        //   EscalationCase.ValidateEmail(trigger.new , trigger.oldMap);
     }
     if(trigger.isafter && trigger.isUpdate){
          // EscalationCase.getHighestNumber(trigger.new , trigger.oldMap);
     }
          if(trigger.isafter && trigger.isdelete )
      {
        //  EscalationCase.getHighestNumber(trigger.old, null);
          
      }
      if(trigger.isbefore && trigger.isdelete)
      {
       //   EscalationCase.CheckEmail(trigger.old);
          
      }
         
}