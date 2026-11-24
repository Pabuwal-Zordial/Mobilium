trigger BranchTrigger on Branch__c (after insert, after update, after delete, after undelete) {
    set<id> bank1 = new set<id>();
    if(trigger.isInsert || trigger.isUndelete)
        for(branch__c bran : trigger.new)
        if(bran.Bank__c != null)
    {
        bank1.add(bran.bank__c);
    }
    if(trigger.isdelete)
    {
        for(branch__C bran : trigger.old)
        {
            if(bran.Bank__c != null)
        {
         bank1.add(bran.bank__c);
        }
        }
    }
    if(trigger.isupdate)
    {
        for(branch__c branches : trigger.new)
        {
            if(branches.bank__c != trigger.oldmap.get(branches.id).bank__c ) 
                if(trigger.oldmap.get(branches.id).bank__C != null)
            {
                bank1.add((trigger.oldmap.get(branches.id).bank__C));
            }
            if(branches.bank__c != null)
            {
                bank1.add(branches.bank__c);
            }
        }
    }
    
    list<bank__c> bank2 = [select id , number_of_branches1__c, (select id from branches__r) from bank__C where id in : bank1];
    {
       // bank2.add(bank1);
       if(bank2 != null)
       {
          for(bank__c bank3 : bank2)
               bank3.number_of_branches1__c = bank3.branches__r.size();
       }
           
    }
   if(!bank2.isEmpty())
    {
     update bank2;   
    }
   
    
    

}