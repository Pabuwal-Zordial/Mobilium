public class AccountHandlerS {
    Public static void valid(list<Account> accNew)
    {
       for(Account acc : accNew)
       {
        
            if(acc.rating == 'Hot' && acc.type == null)
            {
                acc.type.adderror('enter prospoect');
            } 
       }    
    }
     Public static void Acccontact(list<Account> contactNew)
    {
        list<contact> conInsert= new list<contact>();
       for(Account acc : contactNew)
       {
        contact con = new contact();
           con.AccountId = acc.id;
           con.LastName = acc.Name;
           conInsert.add(con);
       }
        insert conInsert;
    }
    
     Public static void Accopp(map<id,Account> newAcc, map<id,Account> oldAcc)
    {
        list<opportunity> oppInsert= new list<opportunity>();
        list<Account> acclst = new list<Account>();
       for(Account acc1 : newAcc.values())
       {
           if(newAcc.get(acc1.id).rating!=oldAcc.get(acc1.id).rating && newAcc.get(acc1.id).rating == 'Hot' )
           {
        opportunity con = new opportunity(); 
           con.AccountId = acc1.id;
           con.Name = acc1.Name;
               //con.StageName = 'StageName';
              // con.CloseDate = system.today();
               
           oppInsert.add(con);
       }
       }
        if(oppInsert != null && oppInsert.size()>0)
        {
            try{
                   insert oppInsert;
                  system.debug('list' +oppInsert );
            }
            Catch(Exception e){
                
    List<Account> olis = [SELECT Id, AccountNumber, name  FROM Account WHERE Id IN: newAcc.keySet()];

    for (Account o :olis){
        o.AccountNumber= 'Opportunity not created for account' + o.name;
    }

    update olis;
               system.debug('error occured');
                
            }
     
          
        }
    }
    
      Public static void AccDel(list<account> oldAcc)
    {
        set<id> accid = new set<id>();
        map<id,boolean> mapacc = new map<id,boolean>();
            for(account acc1 : oldacc )
        {
            accid.add(acc1.id);
        }
       for(contact con : [select id, name,accountid, active__c from contact where active__C = true and accountid in : accid])
       {
           mapacc.put(con.accountid,con.active__c ); 
           system.debug('map'+ mapacc.keyset());
           system.debug('map'+ mapacc.values());
       }
      for(account acc : oldacc)
      {
          if(mapacc.get(acc.id)!=null && mapacc.get(acc.id) == true )
          {
              acc.adderror('stop');
          }
      }
    }
    
        
public static void updateAcc(list<Account> acc)
{
   set<id> accIds = new set<id>();
    if(!acc.isEmpty())
    {
    for(Account acc1 : acc )
    {
        if(acc1.AnnualRevenue == null || acc1.AnnualRevenue < 1000000)
        {
            acc1.Rating = 'Cold';
        }
        else if(acc1.AnnualRevenue > 1000000){
             acc1.Rating = 'Hot';
        }
    }
        
        }
}

    Public static void updateContacts(list<Account> newAccList, map<id,Account> oldAccMap)
    {
        map<id,string> accMap = new map<id,string>();
        list<Contact> ConList1 = new list<Contact>(); 
        for(account acc : newAccList)
        {
            Account accOld = oldAccMap.get(acc.id);
            if(accold.Phone != acc.Phone)
            {
                accMap.put(acc.id, accold.Phone);
            }
        }
        for(account acc1 : [select id, phone, (select id , phone, AccountId from contacts) from Account
                           where id in: accMap.keyset()])
        {
            list<contact> conList = acc1.contacts; 
            for(contact con : conlist)
            {
                if(String.isBlank(con.Phone) || con.Phone == accMap.get(con.AccountId))
                {
                    con.Phone = acc1.Phone;
                    ConList1.add(con);
                    
                }
                    
            }
        }
        update conlist1;
        
    }
    
public static void Checkopps(List<Account> accNewList, Map<id,Account> accOldMap)
{
    set<id> accIds = new set<id>();
    Map<id,Opportunity> AccOpps = new Map<id,Opportunity>();
    list<Opportunity> oppss = new list<Opportunity>();
    for(Account acc : accNewList)
    {
        if(acc.Active1__c == false && acc.Active1__c != accOldMap.get(acc.id).Active1__C )
        {
            accIds.add(acc.id);
        }
    }

		for(Account Acc1 : [select id, Active1__c, (select id, StageName from opportunities where
                                                   stageName != 'Closed Won') from Account
                           where id in : accIds])
        {
            if(acc1.Opportunities != null)
            {
           for(opportunity ops : acc1.opportunities)
           {
                 ops.StageName = 'Closed Lost';
            oppss.add(ops);
                system.debug('oppsss'+ oppss);
           }
            }
        }
    
    try{
        if(!oppss.isEmpty())
        {
            update oppss;
        }
    }
    catch(exception e)
    {
        system.debug('Error' + e.GetMessage());
    }

        
}    
    
}