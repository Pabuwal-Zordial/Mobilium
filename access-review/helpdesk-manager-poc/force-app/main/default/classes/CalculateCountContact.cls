public class CalculateCountContact {
    
    public static void GetContactsCount(list<contact> newCon, map<id,Contact> oldConMap)
    {
        set<id> accSet = new set<id>();
        if(!newCon.isempty())
        {
            for(contact con : newcon)
            if(oldConMap != null)
            {
               contact oldCon = oldconMap.get(con.id);
                if(con.accountid != oldcon.AccountId)
                {
                    accSet.add(con.AccountId);
                      accSet.add(oldCon.AccountId);
                }
                else if (con.leadScoring__Lead_Score__c != oldcon.leadScoring__Lead_Score__c){
                    {
                        accSet.add(con.AccountId);
                    }   
                }
            }
            else if (con.leadScoring__Lead_Score__c != null  || con.AccountId != null)
            {
                accSet.add(con.AccountId);
            }
        }
        system.debug('set'+accSet);
        
        
       map<id,decimal> accInt = new map<id,decimal>();
        list<account> listupdate = new list<Account>();
        
        for(AggregateResult acc : [select Accountid , sum(leadScoring__Lead_Score__c) Score
                                  from Contact
                                  where Accountid IN : accSet
                                  group by Accountid
                                  order by Accountid asc])
   
        {
         accInt.put((id)acc.get('Accountid'),(decimal)acc.get('Score') );  
            system.debug('map'+ accInt);
        }
    
    if(accInt.size()>0 || !accInt.isEmpty())
    {
        for(Account acc : [select id, Active_Contacts__c from account where id in : accInt.keyset()])
        {
            acc.Active_Contacts__c = accInt.get(acc.id);
            listupdate.add(acc);
            system.debug('lits'+listupdate);
            
        }
    }
         if(listupdate.size() > 0)
        {
            update listupdate;
        }
    }

}