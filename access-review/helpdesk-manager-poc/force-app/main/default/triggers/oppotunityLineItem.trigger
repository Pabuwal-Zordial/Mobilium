trigger oppotunityLineItem on OpportunityLineItem ( after update, before insert) {

 // OpportunityLineItemHelper.getCount(trigger.new);
      OpportunityLineItemHelper.assignLineNumbers(trigger.new);
    
    
 
}