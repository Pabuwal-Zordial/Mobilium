public class ContactTriggerHandler {
    
    public static void CheckContact(list<contact> contactlst)
    {
        set<id> accountids = new set<id>();
        list<account> accLst = new list<account>();
        integer num = 0;
        
        for(contact con :  contactlst)
        {
            if(con.AccountId!=null )
            accountids.add(con.AccountId);
            
        }
        AccountContactService.updatecheckbox(accountids);
    }
    public static void updateCheckContact(list<contact> contactlst , map<id, contact> oldcontactMap)
    {
        set<id> accountids = new set<id>();
        list<account> accLst = new list<account>();
        integer num = 0;
        
        for(contact con :  contactlst)
        {
            if(con.AccountId!=null && oldcontactMap.get(con.id).active__c != con.Active__c  )
            {
            accountids.add(con.AccountId);
            }
            else if(oldcontactMap.get(con.id).accountid != con.AccountId)
            {
                accountids.add(oldcontactMap.get(con.id).accountid);
                accountids.add(con.AccountId);
                
            }
            AccountContactService.updatecheckbox(accountids);
                
            
        }
    }
     public static void afterDelete(list<contact> oldContacts)
    {
        set<id> accountids = new set<id>();
        list<account> accLst = new list<account>();
        integer num = 0;
        
        for(contact con :  oldContacts)
        {
            if(con.AccountId!=null )
            {
            accountids.add(con.AccountId);
            }
            
            AccountContactService.updatecheckbox(accountids);
        }
    }
     public static void afterunDelete(list<contact> newContacts)
    {
        set<id> accountids = new set<id>();
        list<account> accLst = new list<account>();
        integer num = 0;
        
        for(contact con :  newContacts)
        {
            if(con.AccountId!=null )
            {
            accountids.add(con.AccountId);
            }
            
            AccountContactService.updatecheckbox(accountids);
        }
    }
    
    public static void getCount(list<contact> newList, map<id,Contact> oldMap)
    {
        set<id> parentid = new set<id>();
        map<id,decimal> mapid = new map<id,decimal>();
        list<account> listupdate= new list<account>();
        
        if(!newList.isEmpty())
        {
            for(contact newCon: newList)
            {
                if(oldmap != null)
                {
                    contact oldCon = oldMap.get(newCon.id);
                    if(newCon.Accountid != oldcon.AccountId)
                    {
                     parentid.add(newCon.AccountId);   
                     parentid.add(oldcon.AccountId);   
                    }
                    else{
                         parentid.add(newCon.AccountId);
                    }
                }
                else{
                    parentid.add(newCon.AccountId);
                }
            }
        }
        if(!parentId.isEmpty())
        {
            for(AggregateResult agg : [select count(id) cou, accountid  from contact where accountid in : parentid
                                      			group by accountid ])
            {
                mapid.put((id)agg.get('accountid'),(decimal)agg.get('cou'));
            }
        }
       if(!mapid.isEmpty())
       {
           for(account acc : [select id, Active_Contacts__c from account where id in : mapid.keyset()])
           {
               acc.Active_Contacts__c = mapid.get(acc.id);
               listupdate.add(acc);
           }
       }
        if(listupdate.size() > 0)
        {
            update listupdate;
        }
    }
    public static void getError(list<contact> lst)
    {
        set<id> accountids = new set<id>();
        map<id,integer> acc = new map<id,integer>();
        if(!lst.isEmpty())
        {
            for(contact con : lst){
                accountids.add(con.AccountId);
            }
        }
        for(AggregateResult aggr : [select Count(id) co, accountid from contact  where Accountid in : accountids
                                   group by accountid])
            {
                acc.put((id)aggr.get('accountid'),(integer)aggr.get('co'));
                system.debug('acc' + acc.Values());
            }
        for(contact con1 : lst)
        {
            if(acc.containskey(con1.AccountId) && acc.get(con1.accountid) >= 4 && con1.accountid != null )
            {
                con1.addError('cannot create new');
            }
        }
            
    }
    
    public static void getName(list<contact> conList)
    {
        set<id> acc = new set<id>();
        if(!conList.IsEmpty())
        {
            for(contact con : conList)
            {
                if(!string.isblank(con.AccountId))
                {
                   acc.add(con.AccountId);
                    System.debug('acc id '+ acc);
                }
            }
        }
       map<id,Account> accMap = new map<id,Account>([select id, Description from account where id in : acc]);
        map<id,account> mapToUpdate = new map<id,account>();
        
      if(!conList.IsEmpty())
      {
          for(contact con : conList)
          {
              if(accmap.containskey(con.AccountId))
              {
                   account acc1 = accmap.get(con.AccountId);
               //   if(!acc1.Description.contains(con.Id))
               //   {
                      acc1.Description =+ con.id;
                      maptoUpdate.put(acc1.id, acc1);
                                      System.debug('acc map id '+ maptoUpdate);
                  System.debug('acc map id '+ maptoUpdate.values());
                //  }
              }
              
          }
      }
        if(!mapToupdate.isEmpty())
        {
            update maptoUpdate.values();
        }
    }
    
    public static void checkDuplicate(list<contact> conList, map<id, contact> oldmaplist)
    {
        map<string,contact> phonemap = new map<string,contact>();
           map<string,contact> emailmap = new map<string,contact>();
        if(!conList.isEmpty())
        { 
            for(contact con : conlist)
            {
                if(oldmaplist != null)
                {
                    contact conold = oldmaplist.get(con.id);
                    {
                        if(conold.Email != con.Email)
                        {
                            emailmap.put(con.Email, con);
                        }
                    }
                }
                else if(con.Email != null)
                {
                    emailmap.put(con.Email, con);
                }
                else if(con.phone != null)
                {
                    phonemap.put(con.phone, con);
                }
            }
        }
     list<contact> listco = new list<contact>([select id, phone, email  from contact where phone in : phonemap.keyset() 
                                               or email in : emailmap.keyset()]);
        string error = '';
        FOR(contact con1 : listco)
        {
            if(emailmap.get(con1.Email) != null)
            {
                error = 'test';
            }
        }
       FOR(contact con2 : conList)
       {
           if(String.isNotBlank(error))
              {
                  con2.addError('already exist  ' + con2.Email);
              }
       }
        
    }
    public static void emailNotify(list<contact> newList, map<id,contact> oldmapList)
    {
       set<id> accold = new  set<id>();
         set<id> accnew = new  set<id>();
          map<id,contact> conmap = new map<id,contact>();
        if(!newList.isEmpty())
        {
            for(contact con : newlist)
            {
                if(oldmapList != null)
                {
                    contact oldcon = oldmaplist.get(con.id);
                    {
                        if(con.AccountId != oldcon.AccountId)
                        {
                        
                             
                            conmap.put(con.AccountId, con);
                         
                        }
                    }
                }
                else if(con.AccountId != null)
                {
                    conmap.put(con.AccountId, con);
                }  
            }
        }
        
        for(contact con : [select id, accountid from contact where accountid in : conmap.keyset()])
        {
            if(conmap.keyset().contains(con.AccountId))
            {
                
            }
        }
    }
  
    public static void deleteRecords(list<contact> conList)
    {
     set<id> acc = new set<id>();
        if(!conlist.isEmpty())
        {
            for(contact con : conlist)
            {
               acc.add(con.AccountId);
            }
        }
        map<id,account> accmap = new map<id,account>([select id, owner.email, ownerid from account where id in :  acc]);
        list<task> tskUpdate = new list<task>();
        
            for(contact con1 : conlist)
            {
                account acc1 = accmap.get(con1.AccountId);
                
                task tsk = new task();
                
                tsk.whatid = con1.AccountId;
                //tsk.WhoId =accmap.get(con1.AccountId).ownerid;
                tsk.Description= 'contact deleted ' + con1.id; 
                tskUpdate.add(tsk);
            }
        if(!tskUpdate.isEmpty())
        {
            insert tskupdate;
        }
        
    }
    
    public static void getConDescription(list<contact> newList, map<id,Contact> oldmapList)
    {
        set<id> accids = new set<id>();
        list<account> toUpdate = new list<account>();
        if(!newList.isEmpty())
        {
            for(contact newCon : newlist)
            {
                if(oldmapList != null)
                {
                   contact oldCon = oldmaplist.get(newCon.id);
                    if(newcon.AccountId != oldcon.AccountId)
                    {
                        accids.add(newcon.AccountId);
                        accids.add(oldcon.AccountId);
                    }
                    else{
                         accids.add(newcon.AccountId);
                    }
                }
                else{
                     accids.add(newcon.AccountId);
                }
            }
        }
     if(!accids.isEmpty())
              {
                map<id,list<String>> conNames = new  map<id,list<String>>();
         for(contact con : [select id, name, createddate, accountid from contact 
                           where accountid in : accids])
         {
             string contactname = 'Contact ' + con.name + con.id + '\n';
             if(!conNames.containskey(con.AccountId))
             {
             conNames.put(con.AccountId, new list<string>{contactname});
             }
             else{
                 conNames.get(con.AccountId).add(contactname);
                 
             }
         }
     
        for(id ids : accids)
        {
            account ac = new account();
            ac.id = ids;
            
            if(conNames.containskey(ac.id))
            {
                ac.Description = string.join(conNames.get(ac.id), '');
                
            }
            else{
                 ac.Description = 'no contact';
            }
            toUpdate.add(ac);
        }
              }
        if(!toUpdate.isEmpty())
        {
            update toUpdate;
        }
        
        
        
    }
    
    public static void getContacts(list<contact> newCon, map<id,Contact> oldConMAp)
    {
        set<id> parentid = new set<id>();
        map<id,integer> countMap = new map<id,Integer>();
        list<Account> toupdate = new list<Account>();
        if(!newCon.isEmpty())
        {
            for(contact con1 : newcon)
            {
                if(oldConMAp != null)
                {
                    contact conold = oldConMAp.get(con1.id);
                    {
                        if(conold.Active__c != con1.Active__c && string.isNotblank(conold.AccountId))
                        {
                             parentid.add(con1.AccountId);
                              parentid.add(conold.AccountId);
                        }
                        else if(conold.Accountid != con1.Accountid && string.isNotblank(conold.AccountId))
                        {
                            parentid.add(con1.AccountId);
                             parentid.add(conold.AccountId);
                        }
                    }
                }
                else if(con1.Active__c && string.isNotblank(con1.AccountId)){
                     parentid.add(con1.AccountId);
                }
            }
             }
 
         for(AggregateResult agg : [select count(id) cou, accountid from contact where accountid in : parentid and active__C = true
                                   group by accountid])
         {
                 countMap.put((id)agg.get('Accountid'), (integer)agg.get('cou'));
         }
        for(id accountid : parentid)
        {
            account acc = new account();
            acc.id = accountid;
            acc.Active_Contacts__c = countMap.get(accountid);
            toupdate.add(acc);  
        }
        if(toupdate.size() > 0)
        {
            update toupdate;
        }
    }

Public static void getCountAcc(list<contact> newCon )
{
    set<id> parentid = new set<id>();
			 for(contact con : newCon)
             {
                 if(con.AccountId != null)
                 {
                    parentid.add(con.AccountId);
                 }
             }
    list<Account> acc = [select id, active_contacts__c, (select id from contacts) from Account where id in : parentid];
    
    for(Account acc1 : acc )
    {
        acc1.Active_Contacts__c = acc1.contacts.size();
    }
    if(!acc.isEmpty())
    {
        try{
            update acc;
        }
        catch (Exception ex)
        {
            system.debug('Exception is '+ ex.getMessage());
        }
    }
}
    Public static void getCountAccUpdate(list<contact> newCon, Map<id,Contact> oldConMap )
{
    set<id> parentid = new set<id>();
			 for(contact con : newCon)
             {
               contact oldCon = oldConMap.get(con.id);
                 if(con.AccountId != null && oldCon.AccountId!=con.AccountId)
                 {
                    parentid.add(con.AccountId);
                 }
                 if(oldCon.AccountId != null)
                 {
                    parentid.add(oldCon.AccountId);
                 }
             }
    list<Account> acc = [select id, active_contacts__c, (select id from contacts) from Account where id in : parentid];
    
    for(Account acc1 : acc )
    {
        acc1.Active_Contacts__c = acc1.contacts.size();
    }
    if(!acc.isEmpty())
    {
        try{
            update acc;
        }
        catch (Exception ex)
        {
            system.debug('Exception is '+ ex.getMessage());
        }
    }
}
    public static void duplicateCheck(list<Contact> newConList)
    {
        set<string> emailSet = new set<string>();
        set<string> phoneSet = new set<String>();
        for(Contact con : newConlist)
        {
            if(string.isNotBlank(con.Phone))
            {
                phoneSet.add(con.Phone);
            }
             if(string.isNotBlank(con.email))
            {
                phoneSet.add(con.email);
            }
        }
        for(contact con : [select id, phone, email from Contact where phone in : phoneSet or email in : emailSet])
        {
            if(phoneSet.contains(con.Phone))
            {
                con.phone.addError('Duplicate Phone');
            }
                        if(emailSet.contains(con.email))
            {
                con.email.addError('Duplicate');
            }
        }
    }
   public static void primaryContact(list<contact> newConList)
   {
       set<id> Accids = new set<id>();
        set<id> AlreadyActive = new set<id>();
       set<id> CurrentActive = new set<id>();
       for(contact con : newConList )
       {
           if(con.Active__c == true && String.isNotBlank(con.AccountId))
           {
               Accids.add(con.AccountId);
           }
       }
for(contact con1 : [select id, accountid, active__C from contact where id in: Accids and active__c = true] )
{
    AlreadyActive.add(con1.AccountId);
}
       for(contact con1 : newConList)
       {
           if(con1.Active__c == true && String.isNotBlank(con1.AccountId))
           {
               if(AlreadyActive.contains(con1.AccountId))
               {
                   con1.addError('not add');
               }
               else if(CurrentActive.contains(con1.AccountId))
               {
                    con1.addError('not add');
               }
               else{
                    CurrentActive.add(con1.AccountId);
               }
               
           }
       }
       
   }
public static void createAccount(list<Contact> conList)
{
    set<id> contacts = new set<id>();
    list<Account> accids = new list<Account>();
   map<id,Account> conAccids = new map<id,Account>();
      list<contact> conids = new list<contact>();
    map<id,id> accConids = new Map<id,id>();
    for(contact con : conList)
    {
        if(String.isBlank(con.AccountId))
        {
            Account acc = new account();
            acc.Name = con.LastName;
           // accids.add(acc);
            conAccids.put(con.id,acc);
            system.debug(accids);
        }
    }
    if(!conAccids.IsEmpty())
    {
        insert conAccids.values();
    }
    for(contact con : conList )
    {
       contact con1 = [select id , name, accountid from Contact where id =: con.id];
        con1.AccountId = conAccids.get(con1.id).id;
        conids.add(con1);
        
    }
    update conids;
    
    
}
    
    public static void stopDeleteifCase(list<contact> oldConList)
    {
        set<id> conid = new set<id>();
        for(contact con : oldConList)
        {
            conid.add(con.id);
        }
        
       // list<contact> con1 = ;
        
        for(contact con2 : [select id,(select id from tasks) from contact where id in : conid])
        {
            if(con2.tasks.size()>0)
            {
                con2.addError('Cases Exist!');
            }
        }
    }
    
    public static void checkCounter(list<contact> con, map<id,contact> oldConMap)
    {
        set<id> accids = new set<id>();
        
        
        if(!con.isEmpty()){
            for(contact con1 : con){
                if(con1.AccountId != null)
                {
                    accids.add(con1.AccountId);
                }
                if(oldConMap != null)
                {
                    contact con2 = oldconmap.get(con1.id);
                    if(con2.AccountId != con1.AccountId)
                    {
                           accids.add(con2.AccountId);
                    }
                }
            }
        }
        if (accIds.isEmpty()) return;
        
       map<id,Integer> AccCount = new map<id, Integer>();
        list<account> accList = new list<Account>();
        
        for(aggregateResult ar : [select count(id) ids, accountid acc from contact where accountid in : accids
                                 group by accountid] )
        {
            AccCount.put((id)ar.get('acc'),(integer)ar.get('ids'));
        }
        for(id idss : accids)
        {
            if(AccCount.containskey(idss))
            {
                account ac = new account();
                ac.id = idss;
                ac.NumberOfEmployees = AccCount.get(idss)!= null ? AccCount.get(idss): 0;
                accList.add(ac);
            }
        }
        if(acclist != null || !acclist.isEmpty())
        {
            try{
                
            update accList;
            }
            catch(dmlexception e){
                system.debug('Exception  ' + e.getMessage());
                
            }
            
        }
        
        
    }
    public static void checkCase(list<contact> conList)
    {
        set<id> Conids = new set<id>();
        if(!conList.isEmpty())
        {
            for(contact con1 : conList)
            {
                Conids.add(con1.id);
            }
            system.debug('Conids' + Conids);
        }
        map<id,Integer> conCase = new map<id,Integer>();
        
        for(aggregateResult con : [select count(id) cou, whoid conId from task where whoid in :Conids
                                  	group by whoid ] )
            
        {
            conCase.put((id)con.get('conId'), (Integer)con.get('cou'));
            system.debug('conCase'+conCase);
        }
        for(contact con : conList)
        {
            if(conCase.containsKey(con.id))
            {
                con.addError('cannot delete a contact is task is there');
            }
        }
    }
}