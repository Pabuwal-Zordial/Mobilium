public class OpportunityHelper {

    public static void maxAmt(list<Opportunity> OppList, map<id,Opportunity> oldMap)
{
    set<id> parentIds = new set<id>();
    list<account> accid = new list<Account>();
    if(!OppList.isEmpty())
    {
    for(Opportunity newOpp : OppList)
    {
        if(oldMap != null)
        {
        Opportunity oppOld = oldMap.get(newOpp.id);
        
    if(newOpp.Accountid != oppOld.Accountid)
    {
        parentIds.add(newOpp.Accountid);
         parentIds.add(oppOld.Accountid);

    }
    else{
     parentIds.add(newOpp.Accountid);
    }}
    }

    }

if(!parentIds.isEmpty())
{
    list<account> accList = [select id , (select id, amount,name from Opportunities where amount != null order by amount desc limit 1) from account where ID IN : parentIds ];

if(!accList.IsEmpty())
{
    for(account acc1 : accList)
    {
        if(!acc1.Opportunities.isEmpty())
        {
            acc1.SicDesc = acc1.Opportunities[0].name;
            accid.add(acc1);
        }
        else{
             acc1.SicDesc = '';
             accid.add(acc1);
        }
    }

}
}
if(!accid.isEmpty())
{
    update accid;
}



}

public static void getOpp(list<opportunity> oppList, map<id,opportunity> oldMap)
{
    set<id> oppIds = new set<id>();
    map<id,integer> intMap = new map<id,integer>();

    if(!oppList.isEmpty())
    {
        for(opportunity oppNew : oppList)
        {
            if(oldMap != null)
            {
                opportunity oppOld = oldMap.get(oppNew.id);
            if(oppNew.AccountId != oppOld.AccountId)
            {
                oppIds.add(oppNew.id);
                 oppIds.add(oppOld.id);
            }
            else{
                oppIds.add(oppNew.id);
            }
            }
            else{
                 oppIds.add(oppNew.id);

            }
        }
        }

        if(!oppIds.isEmpty())
        {
            for(AggregateResult aggr : [select accountid , Count(stagename) stn from opportunity WHERE
                                            id in : oppIds and stagename = 'Closed Won'
                                                GROUP BY accountid])
                                            {
                                                intMap.put((id)aggr.get('accountid'), (integer)aggr.get('stn'));

                                            }
        }
        list<Account> accids = [select id, rating from account where id in : intMap.keyset()];
           list<Account> listToUpdate = new list<Account>();
        if(!accids.isEmpty())
        {
           for(account acc : accids)
           {
               Integer count = intMap.containsKey(acc.id) ? intMap.get(acc.id) : 0;
               String Toupdate;
               if(count < 2)
               {
                   Toupdate = 'Hot';
               }
               else if (count > 2 && count < 6)
               {
                   Toupdate = 'Warm';
               }
               else{
                   Toupdate = 'Cold';
               }
               acc.rating = Toupdate;
               listToupdate.add(acc);
           }

        }
        update listToUpdate;
    }
    
    public static void getOppN(list<opportunity> newList, map<id,opportunity> oldMapopp)
    {
        set<id> accids = new set<id>();
        if(!newList.isEmpty())
        {
            for(opportunity newOpps : newList )
            {
                if(oldMapopp != null)
                {
                    opportunity oldOpps = oldMapopp.get(newOpps.id);
                    {
                        if(newOpps.Amount != oldopps.Amount && newopps.Amount!= null)
                        {
                            accids.add(newOpps.AccountId);
                              accids.add(oldopps.AccountId); 
                        }
                        else{
                              accids.add(newOpps.AccountId);  
                        }
                    }
                }
                else if (newopps.Amount!= null){
                    accids.add(newOpps.AccountId); 
                }
            }
        }
        list<account> updateList = new list<account>();
        map<id,decimal> opps = new map<id,decimal>();
        
        for(opportunity ops : [select id, amount from opportunity where accountid in : accids
                              	order by amount desc])
        {
            opps.put(ops.id, ops.Amount);
        }
        
        
        list<account> acc = [select id, AnnualRevenue , (select id , amount from Opportunities 
                                                        order by amount desc limit 1) from account where id in : accids];
        
        if(!acc.isEmpty())
        {
            for(account acc1 : acc)
            if(acc1.opportunities.isEmpty())
            {
                acc1.AnnualRevenue = acc1.opportunities[0].amount;
                updatelist.add(acc1);
               // acc1.AnnualRevenue = ''
            }
            else{
                  acc1.AnnualRevenue = 0;
                       updatelist.add(acc1);
            }
        }
        if(!updateList.isEmpty())
        {
            update updateList;
        }
        
    }
    
public static void getMaxAmt(list<Opportunity> newList)
{
    set<id> accIds = new set<id>();
    for(Opportunity opps : newList)
    {
        if(opps.accountid != null)
        {
            accIds.add(opps.accountid);
        }
    }
    list <Account> acc = [select id, AnnualRevenue,AccountNumber, (select id, amount, name from Opportunities order by amount desc nulls last limit 1 ) from account where id in : accIds];
    
    for(Account acc1 : acc)
    {
        list<opportunity> oppss = acc1.opportunities; 
        if(!oppss.isEmpty())
        {
            acc1.Description = oppss[0].name; 
        }
        else{
             acc1.Description = null; 
        }
    }
    if(!acc.isEmpty())
    {
        update acc;
    }
}
    public static void getMaxAmtU(list<Opportunity> newList, map<id,opportunity> oldopps)
{
    set<id> accIds = new set<id>();
    for(Opportunity opps : newList)
    {
        opportunity oppsOld = oldopps.get(opps.id);
        if(opps.accountid != null && oppsOld.AccountId != opps.Accountid)
        {
            accIds.add(opps.accountid);
        }
        if(String.isnotBlank(oppsOld.AccountId))
        {
            accIds.add(oppsOld.accountid);
        }
    }
    list <Account> acc = [select id, AnnualRevenue,AccountNumber, (select id, amount,name from Opportunities order by amount desc nulls last limit 1 ) from account where id in : accIds];
    
    for(Account acc1 : acc)
    {
        list<opportunity> oppss = acc1.opportunities; 
        if(!oppss.isEmpty())
        {
            acc1.Description = oppss[0].name; 
        }
        else{
             acc1.Description = null; 
        }
    }
    if(!acc.isEmpty())
    {
        update acc;
    }
}
   
   
public static void getMaxAmtAd(list<Opportunity> oldList)
{
    getMaxAmt(oldList);
}
    public static void getMaxAmtUd(list<Opportunity> newList)
{
    getMaxAmt(newList);
}
    public static void checkForLostReason(List<Opportunity> newOppsList, map<id,Opportunity> oldMapOpps)
    {
        for(Opportunity opps : newOppsList)
        {
            
            if(opps.StageName == 'Closed Won'  && opps.stagename != oldMapOpps.get(opps.id).stagename  && String.isBlank(opps.description))
                
            {
                opps.addError('Enter Description');
            }
        }
    }
    
public static void StopRecordEdit(List<Opportunity> newOppsList)
{
    date dt = date.Today()-7;
    System.debug('dt'+ dt);
    for(opportunity opps : newOppsList)
    {
     if(opps.createddate < dt) 
     {
         opps.addError('Not able to edit');
     }
    }
}  
    Public Static Void CreateTask(List<Opportunity> newOppsList , Map<id,Opportunity> oldMapRec)
    {
        List<task> tskList = new list<Task>();
        user us = [select id from user where name = 'Automated Process'];
        for( Opportunity opps : newOppsList)
        {
            if(opps.StageName != oldMapRec.get(opps.id).StageName)
            {
                Task tsk = new Task();
                tsk.Subject = 'Opp'+ opps.StageName;
                tsk.WhatId = opps.id;
                tsk.OwnerId = Us.id;
                tsk.ActivityDate = System.Today()+3;
                tskList.add(tsk);
                
                
            }
        }
       if(!tskList.isEmpty())
       {
           try{
               Insert tskList;
           }
           Catch(exception e)
           {
               system.debug('Error' + e.GetMessage());
           }
       }
    }
}