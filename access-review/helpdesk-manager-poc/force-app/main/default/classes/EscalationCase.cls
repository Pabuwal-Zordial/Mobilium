public class EscalationCase {

    public static void main(list<account> AccountId, map<id,account> OldAccountID)
    {
        list<id> accIds = new list<id>();
        list<task> tskList = new list<task>();
        for(account acc : AccountId )
        {
            account oldAcc = OldAccountID.get(acc.id);
            if(acc.Escalated__c != oldAcc.Escalated__c && acc.Escalated__c )
            {
                accIds.add(acc.id);

            }
        }
        for(contact con : [select id, account.name, accountid from contact where accountid in : accIds and Active__c = TRUE])
        {
            Task tsk = new Task();
            tsk.subject = con.account.name;
            tsk.whatid = con.accountid;
            tsk.whoid = con.id;

            tskList.add(tsk);
        }

        if(tskList.size()>0 || !tskList.isEmpty())
        {
            insert tskList;
        }
       

    }

    public static void CloseOpp(list<account> newAcc, map<id,account> oldAccMap)
    {
        set<id> accid = new set<id>();
        list<opportunity> opps = new list<opportunity>();
        
        if(!newAcc.isEmpty())
        {
            for(account acc : newAcc)
{
    if(acc.escalated__c == true && oldAccmap.containskey(acc.id) && oldAccmap.get(acc.id).escalated__c == false)
    {
        accid.add(acc.id);

    }
}
        }

        if(!accid.Isempty())
        {
            for(opportunity opp : [select id, name from opportunity where accountid in : accid and
                                    stagename != 'closed won'])
            {
                opp.Stagename = 'Closed Won';
opp.CloseDate = date.today();
opps.add(opp);
            }
        }
        if(!opps.isEmpty())
{
update opps;
}
      

    }

    public static void caseHandle(list<case> newCase)
    {
        set<id> caseid = new set<id>();
        map<id,case> caseMap = new map<id,case>();
        list<task> newtask = new list<task>();
        if(!newCase.isEmpty())
        {
            for(case case1 : newCase)
            {
                if(case1.ContactId == null)
                {
                 caseMap.put(case1.id, case1);
                }
            }
        }
        for(case case2 : caseMap.values())
        {
            if(caseMap.containsKey(case2.id))
            {
            task tsk = new task();
            tsk.subject = 'name1';
            tsk.whatId = case2.id;
            newtask.add(tsk);
        }
        }
        if(!newTask.isEmpty())
        {
        insert newtask;
        }
    }
    public static void ContactCase(list<case> newCase)
    {
        set<string> caseEmail = new set<string>();
        list<case> caseupdate = new list<case>();
        if(!newCase.isEmpty())
        {
            for(case caseList : newCase)
            {
                if(caseList.SuppliedEmail != null)
                {
                    caseEmail.add(caseList.SuppliedEmail);
                }
            }
        }
     
        map<string,id> existingCon  = new map<string,id>();
       list<Case> caseExist = new list<Case>();
        map<string,id> newCon = new map<string,id>();
        list<contact> newContact = new list<contact>();
        
        for(contact con : [select id , email from contact where email in : caseEmail and email != null])
        {
            existingCon.put(con.email, con.id);
        }
        
        for(case case1 : newCase)
        {
            if(case1.SuppliedEmail!=null && existingCon.containskey(case1.SuppliedEmail))
            {
                case1.ContactId = existingCon.get(case1.SuppliedEmail);
               // caseUpdate.add(case1);
            }
            else if(case1.SuppliedEmail != null )
            {
                contact con = new contact();
                con.lastname='case' + case1.CaseNumber;
                con.AccountId = case1.AccountId;
                con.Email = case1.SuppliedEmail;
                caseExist.add(case1);
               // con.LastName = 'test';
               
                newContact.add(con);
                system.debug('newContact' + newContact);
                
            }
        }
        if(!newContact.isEmpty())
        {
            insert newContact;
            for(contact con1 : newContact)
            {
              newCon.put(con1.Email, con1.id);
            }
            for(case case1 : caseExist )
            {
                if(newCon.containskey(case1.SuppliedEmail) && !newCon.isEmpty())
                {
                    case1.ContactId = newCon.get(case1.SuppliedEmail);
                }
            }
        }
        
       
    }
    
public static void createCase(list<case> newCaseList)
{
    map<string,id> conMap = new map<string,id>();
    set<string> email1 = new set<string>();
    if(!newCaseList.isEmpty())
    {
        for(case cs : newCaseList)
        {
            if(cs.SuppliedEmail != null)
            {
                email1.add(cs.SuppliedEmail.toLowerCase());
            }
        }
    }
      for(contact con : [select id , email from contact where email in : email1])
      {
          conMap.put(con.Email, con.Id);
      }
    for(case case1 : newCaseList)
    {
        if(conMap.containsKey(case1.SuppliedEmail.toLowerCase()))
        {
            case1.ContactId = conMap.get(case1.SuppliedEmail.toLowerCase());
        }
    }
}

public static void ValidateEmail(list<case> newCase, map<id,case> oldCaseMap)
{
    set<string> emailString = new set<string>();
    emailString.add('gmail.com');
   
    
    if(!newCase.isEmpty())
    {
      
       for(case cs : newCase)
       {
            case  oldcase = oldCaseMap.get(cs.id);
           system.debug('old' + oldcase);
          if((cs.SuppliedEmail != null || cs.SuppliedEmail != oldcase.SuppliedEmail ))
          {
              string email = cs.SuppliedEmail.subStringAfter('@').toLowerCase(); 
              system.debug('email string'+email);
              if((!emailString.contains(email)))
                 {
                  system.debug(emailString);
              cs.SuppliedEmail = '';
                     system.debug('email'+  cs.SuppliedEmail);
                 }
          }
       }
    }
}
    
public static void preventDeletion(list<case> newCase)
{
    set<id> caseIds = new set<id>();
    map<id,id> taskRelations = new map<id,id>();
    if(!newCase.isEmpty())
    {
        for(case cs : newCase)
        {
            caseIds.add(cs.Id);
        }
    }
    system.debug('caseIds'+ caseIds);
    for(task tsk : [select id, whatid from task where WhatId in: caseIds ])
    {
        taskRelations.put(tsk.whatid, tsk.id);
    }
    system.debug('taskRelations'+ taskRelations);
    for(case cs1 : newCase)
    {
    if(taskRelations.containskey(cs1.id))
        cs1.SuppliedEmail.addError('cannot delete due to task');
     }
    
}
    
public static void createCaseContact(list<case> newCase)
{
    set<id> conIds = new set<id>();
    map<id,contact> conMap = new map<id,contact>();
    if(!newCase.isEmpty())
    {
        for(case cs : newCase)
        {
            if(cs.ContactId != null)
            {
              conIds.add(cs.ContactId);  
            } 
        }
        for(contact con : [select id, leadSource from contact where id in: conIds and leadsource = 'Web'])
        {
            conMap.put(con.id, con);
            system.debug(conMap);
        }
        for(case case1: newCase)
        {
            if(case1.ContactId != null && !conMap.containskey(case1.ContactId))
            {
                case1.ContactId.addError('cannot create');
            }
        }
    }
}
    
    public static void AssignContacts(list<case> newCase)
        
    {
     set<string> emailString = new set<string>();
        if(!newCase.Isempty())
        {
            for(case cs : newCase)
            {
               if(String.isNotBlank(cs.ContactEmail))
               {
                   emailString.add(cs.ContactEmail.toLowercase());
               }
            }
        }
        map<String,id> conId = new map<String,id>();
        
        for(Contact con1 : [select id,email from contact where email in : emailString])
        {
            conId.put(con1.Email, con1.id);
        }
        
        for(case cs1 : newCase)
        {
            if(String.isNotBlank(cs1.ContactEmail))
               {
                  Boolean ContactFound = conId.containskey(cs1.ContactEmail.ToLowerCase());
                   if(ContactFound == true)
                   {
                       cs1.ContactId = conId.get(cs1.ContactEmail);
                   }
                   }
      
        
    }
    }

    public static void CheckEmail(list<case> newCase){
set<id> CaseSet = new set<id>(); 
         map<id,list<sobject>> tskList = new map<id,list<sobject>>();
        if(!newCase.isempty())
        {
            for(case cs : [select id, (select id,subject from tasks), (select id, Subject from events) from case
                          	where id in : newCase])
            {
            tskList.put(cs.id, cs.Tasks);
                 tskList.put(cs.id, cs.Events);
           if(!tskList.isEmpty())
           {
               CaseSet.add(cs.id);
           }
        } 
        }
        for(case cs1 : newCase)
        {
            if(Caseset.contains(cs1.id))
            {
             
                cs1.addError('Cannot delete ' );
            }
        }
          }
    
    public static void CheckBilling(list<case> newCase)
    {
        Set<id> accIds = new set<id>();
        if(!newCase.Isempty())
        {
            for(case cs : newCase)
            {
                if(String.isNotBlank(cs.AccountId))
                {
                    accIds.add(cs.AccountId);
                }
            }
        }
        map<id,account> accMap = new map<id,Account>([Select id,name, phone from account where id in : accIds]);
        
        for(case cs1 : newCase)
        {
            if(cs1.AccountId== null || !accMap.ContainsKey(cs1.AccountId) )
            {
                continue;
            }
        
        Boolean CheckContact = String.isblank(accMap.get(cs1.accountid).phone);
        if(CheckContact)
        {
            cs1.addError('Cannot create because ' + accMap.get(cs1.accountid).name + ' is Empty');
        }
        }
        
        
        
    }
    
    Public static void checkCount(List<case> newCase, map<id,case> oldCase)
    {
        set<id> accountIds = new Set<id>();
        map<id,Integer> AccCaseMap = new map<id,Integer>();
        if(!newCase.isEmpty())
        {
            for(case cs : newCase)
            {
                if(cs.AccountId != null)
                {
                  accountIds.add(cs.AccountId);
                }
                 if(oldCase!= null)
            {
                case oldCase1 = oldCase.get(cs.id);
                if(oldCase1.AccountId != cs.AccountId)
                {
                     accountIds.add(oldCase1.AccountId);
                }
            }
            }
           
        }
        for(AggregateResult ar : [select accountid accid, count(id) caseids from case where accountid in :accountIds
                                 group by accountId])
        {
            AccCaseMap.put((id)ar.get('accid'), (Integer)ar.get('caseids'));
        }
        list<Account> accountToUpdate = new list<Account>();
        
            for(id ids : accountIds)
            {
                Integer count = AccCaseMap.Containskey(ids) ? AccCaseMap.get(ids) : 0;
                Account acc = new account();
                acc.id = ids;
                acc.NumberofLocations__c = count;
                accountToUpdate.add(acc);
                
            }
        if(!accountToUpdate.isEmpty())
        {
            update accountToUpdate;
        }
        
    }
    
    public static void getHighestNumber(list<case> newCase, map<id,Case> oldMapCase)
    {
        set<id> accids = new set<id>();
        map<id,double> accMax = new map<id,double>();
        list<Account> accUpdate = new List<account>();
        if(!newCase.isEmpty())
        {
            system.debug('here 1');
            for(case cs : newCase){
                if(cs.AccountId!=null)
                {
                   accids.add(cs.AccountId);
                }
                if(oldMapCase != null && oldMapCase.containskey(cs.id))
            {
               case oldcs = oldMapCase.get(cs.id);
                if(oldcs.AccountId != cs.AccountId && (oldcs.AccountId != null || oldcs.case_value__c != cs.case_value__c))
                {
                     accids.add(oldcs.AccountId);
                    system.debug('here 2' + accids);
                } 
            }
            }            
        }
        
        for(AggregateResult ar : [select max(Case_Value__c) csmax, accountid ida from case
                                  	where accountid in : accids
                                  group by accountid
                                ])
        {
            accMax.put((id)ar.get('ida'), (double)ar.get('csmax'));
            system.debug('here 3'+ accMax.values() );
        }
        List<account> acc1 = [select id, (select id, caseNumber from cases order by Case_Value__c desc nulls last limit 1
                                        	) from account where id in : accids  ];
        
       /* for(id ids : accids)
        {
            double max = accMax.containsKey(ids) && accMax.get(ids)!= null ? accMax.get(ids) : 0.00;
            system.debug('here 4'+ max);
            account acc = new account();
            acc.Id = ids;
            acc.Avg_Case_Resolution_Days__c = Decimal.valueOf(max);
            accUpdate.add(acc);
            
        }*/
         for(account asd : acc1)
        {
            double max = accMax.containsKey(asd.id) && accMax.get(asd.id)!= null ? accMax.get(asd.id) : 0.00;
            system.debug('here 4'+ max);
            account acc = new account();
            acc.Id = asd.id;
            acc.Avg_Case_Resolution_Days__c = Decimal.valueOf(max);
            acc.Description = asd.Cases != null && !asd.Cases.isEmpty() ? asd.Cases[0].casenumber : null;


            accUpdate.add(acc);
            
        }
        
        
        if(!accUpdate.isEmpty() || accUpdate != null)
        {
           update accUpdate;
        }
    }
    
    public static void DupCheck(list<case> newCase){
        map<String,id> se = new  map<String,id>();
        set<string> se1 = new set<String>();
        if(!newCase.isEmpty())
        {
            for(case cs : newCase){
                if(String.isnotBlank(cs.SuppliedPhone))
                {
                    //se.put(cs.id, cs.SuppliedPhone);
                    se1.add(cs.SuppliedPhone);
                }
                    
            }
        }
            for(case cs1 : [select id,SuppliedPhone from case where SuppliedPhone in : se1])
            {
               se.put(cs1.SuppliedPhone, cs1.id);
            }
        
        for(Case cs2 : newCase )
        {
            if(se.containsKey(cs2.SuppliedPhone))
            {
                cs2.addError('Phone number already exist on '+ se.get(cs2.SuppliedPhone));
            }
        }
        
        
    }
    
}