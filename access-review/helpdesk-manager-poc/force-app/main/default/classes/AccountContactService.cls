public class AccountContactService {
public static void updatecheckbox(set<id> accountids)
{
    map<id,account> acclst = new  map<id,account>();
     for(AggregateResult acc : [select accountid, count(id) totalContacts from contact where active__c = true and accountid in : accountids group by accountid  ])
        {
          integer num = integer.valueof(acc.get('totalcontacts')); 
            string accid = string.valueof(acc.get('accountid'));
            
            Account acc1 = new account(id=accid, active_contacts__C = num);
            accLst.put(accid, acc1);
           
           
        }
    for(id accid2 : accountids )
    {
    if(!acclst.containskey(accid2))
    {
        acclst.put(accid2, new account(id =accid2, active_contacts__C= 0  ) );
    }
        }
    
         update accLst.values();
    
}
}