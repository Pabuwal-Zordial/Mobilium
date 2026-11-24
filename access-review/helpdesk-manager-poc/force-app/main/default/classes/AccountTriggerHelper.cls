public class AccountTriggerHelper {
    
    public static void GetContacts(list<account> accNew, map<id,Account> accOldMap)
    {
        set<id> accids = new set<id>();
        list<contact> listToUpdate = new list<contact>();
        map<id,Contact> conAcc = new Map<id,Contact>();
        if(!accNew.isEmpty())
        {
            for(Account accNewList : accNew)
            {
                if(accOldMap != null)
                {
                    Account OldList = accOldMap.get(accNewList.id);
                    if(accNewList.id != OldList.id	)
                    {
                        accids.add(accNewList.id);
                        accids.add(OldList.id);
                    }
                    else if(accNewlist.Active1__c != oldList.Active1__C)
                    {
                        accids.add(accNewList.id);
                    }
                }
                else{
                    accids.add(accNewList.id);   
                }
               system.debug('IDS aCC __> ' + accids);
                
            }  
        }
          system.debug('IDS aCC __> ' + accids);
        for(contact con : [select id, Active__c, AccountID from Contact WHERE AccountID IN : accids])
        {
con.Active__c = true;
                listToUpdate.add(con);
               system.debug('IDS ' +  listToUpdate);
             system.debug('IDS con __> ' + con);
        }
        if(listToUpdate.size() > 0)
        {
            update listToUpdate;
        }
        
    }
    
    public static void updateContacts(list<account> NewList, map<id,Account> oldMap)
        
    {
        map<id,account> accids = new map<id,account>();
        list<contact> updatelist = new list<Contact>();
        if(!NewList.isEmpty())
        {
            for(account acc : newlist)
            {
                if(oldmap != null)
                {
                    account oldAccount = oldmap.get(acc.id);
                    if(acc.phone != oldAccount.Phone && acc.Phone != null)
                    {
                        accids.put(acc.id, acc);
                        accids.put(oldAccount.id, oldaccount);
                    }
            }
        }
        }
        
      for(contact con : [select id, accountid, phone from contact where accountid in : accids.keyset()])
      {
          if(accids.containskey(con.accountid))
          {
              con.Phone = accids.get(con.AccountId).phone;
              updatelist.add(con);
          }
      }
        if(!updatelist.isEmpty())
        {
            update  updatelist;
        }
        
        
    }
    public static void CreateContact(list<Account> acc)
    {
        map<id,account> accmap = new map<id,account>();
        set<id> accids = new set<id>();
        list<contact> conU = new list<contact>();
        integer ac;
        if(!acc.isEmpty())
        {
            for(account acc1 : acc)
            {
                if(acc1.NumberofLocations__c != null)
                {
               ac = (integer)acc1.NumberofLocations__c;
              id accid = acc1.id;

                }
            }
        
        for(integer i=0;i<=ac;i++)
        {
            contact con = new contact();
            con.AccountId = accmap.values()[i].id;
            con.LastName = 'contact ' + i + + accmap.values()[i].name;
            conU.add(con);     
        }
        }
        if(!conU.isEmpty())
        {
            insert conU;
        }
    }
    
    public static void UpdateEmail(List<Account> acc)
        
    {
        map<id,account> accMap = new map<id,account>();
        list<contact> conupdate = new list<Contact>();
        if(!acc.isEmpty())
        {
            for(account acc1 : acc )
            {
                if(acc1.Phone != null)
                {
                    accMap.put(acc1.id, acc1);
                }
               
                For(contact con : [select id , accountid , phone from contact where accountid in : accmap.keyset()])
                {
                    con.phone = accmap.get(con.accountid).phone;
                    conupdate.add(con);
                }
            }
        }
        if(!conupdate.isEmpty())
        {
            update conupdate;
        }
    }
    
    public static void phoneCase(list<account> accNew, map<id,Account> OldMapA)
    {
        map<id,string> accids  = new map<id,string>();
        if(!accNew.isEmpty())
        {
            for(account acc : accNew)
            {
                if(String.isNotBlank(acc.Phone))
                {
					accids.put(acc.id, acc.Phone);    
                }
            
            if(OldMapA != null && accids.containskey(acc.id))
            {
                account oldMapRec = OldMapA.get(acc.id);
            
                if(oldMapRec.Phone != acc.Phone)
                {
                    accids.put(acc.id, acc.Phone);    
                }
            }
            }        
    }
        list<case> caseToUpdate = [select id, SuppliedPhone, accountid from case
                                  where accountid in : accids.keyset()];
          list<case> caseToUpdate1 = new   list<case>();
        
        for(case cs : caseToUpdate)
        {
            if(cs.SuppliedPhone != accids.get(cs.AccountId) && accids.get(cs.AccountId)!= null)
            {
                cs.SuppliedPhone = accids.get(cs.AccountId);
                caseToUpdate1.add(cs);
            }
        }
        if(!caseToUpdate1.isEmpty())
        {
           update caseToUpdate1;
            system.debug(caseToUpdate1);
        }
            
        
       
}
}