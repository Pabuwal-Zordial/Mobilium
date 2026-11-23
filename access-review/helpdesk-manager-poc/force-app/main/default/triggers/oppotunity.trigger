trigger oppotunity on Opportunity (after insert, after update, after delete, after undelete) {
    
    if(trigger.isafter && trigger.isUpdate){
    
  //  OpportunityHelper.maxAmt(trigger.new, trigger.oldmap);
    // OpportunityHelper.getOpp(trigger.new, trigger.oldmap);
        OpportunityHelper.getMaxAmtU(trigger.new, trigger.oldmap);
          OpportunityHelper.CreateTask(trigger.new, trigger.oldmap);
      //  OpportunityHelper.StopRecordEdit(trigger.new);
        
        
    }
     if(trigger.isafter && trigger.isInsert)
     {
         OpportunityHelper.getMaxAmt(trigger.new);
     }
     if(trigger.isafter && trigger.isDelete)
     {
         OpportunityHelper.getMaxAmtAd(trigger.old);
     }
     if(trigger.isafter && trigger.isUnDelete)
     {
         OpportunityHelper.getMaxAmtUd(trigger.new);
     }
    else
    {
// OpportunityHelper.getOpp(trigger.new, trigger.oldmap);        //  OpportunityHelper.maxAmt(trigger.new, null);
    }

}