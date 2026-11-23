public class OpportunityLineItemHelper {
    
    
public static void assignLineNumbers(List<OpportunityLineItem> newLines) {

        // Collect Opportunity IDs
        Set<Id> oppIds = new Set<Id>();
        for (OpportunityLineItem oli : newLines) {
            if (oli.OpportunityId != null) {
                oppIds.add(oli.OpportunityId);
            }
        }

        if (oppIds.isEmpty()) return;

        // Query existing line numbers per Opportunity
        Map<Id, Integer> oppToMaxLineNumber = new Map<Id, Integer>();

        for (AggregateResult ar : [
            SELECT OpportunityId oppId, MAX(SortOrder) maxNum
            FROM OpportunityLineItem
            WHERE OpportunityId IN :oppIds
            GROUP BY OpportunityId 
            all rows
        ]) {
            oppToMaxLineNumber.put(
                (Id) ar.get('oppId'),
                (Integer) ar.get('maxNum') == null ? 0 : (Integer) ar.get('maxNum')
            );
             system.debug(oppToMaxLineNumber);
        }

        // Assign line numbers
        for (OpportunityLineItem oli : newLines) {
            if (oli.OpportunityId == null) continue;

            Integer nextNumber =
                oppToMaxLineNumber.containsKey(oli.OpportunityId)
                ? oppToMaxLineNumber.get(oli.OpportunityId) + 1
                : 1;

            oli.SortOrder = nextNumber;
              system.debug(nextNumber);

            // update map for multiple OLIs in same transaction
            oppToMaxLineNumber.put(oli.OpportunityId, nextNumber);
            system.debug(oppToMaxLineNumber);
        }
    }

    public static void getCount(list<OpportunityLineItem> newOpp)
    {
        set<id> oppids = new set<id>();
        map<id,decimal> idMap = new Map<id,Decimal>();
        list<account> listToUpdate = new list<Account>();
        if(!newOpp.isEmpty())
        {
            for(OpportunityLineItem opp : newOpp)
            {
                oppids.add(opp.opportunityid);
            }
        }
        if(!oppids.isEmpty())
        {
            for(opportunity opps : [select id, accountid from opportunity where id in : oppids])
            {
           idMap.put(opps.Accountid, 0);
            }

        }
        for(AggregateResult agg : [select count(id) ids, opportunity.Accountid from OpportunityLineItem where 
                                    Opportunity.Accountid in : idMap.keyset() group by opportunity.Accountid   ])
                                    {
                        idMap.put((id)agg.get('Accountid'),(decimal)agg.get('ids'));
                                    }

        for(id ids : idMap.keyset() )
        {
            Account acc = new Account();
            acc.id = ids;
            acc.Active_Contacts__c = idMap.get(ids);
            listToUpdate.add(acc);

        }
        if(!listToUpdate.isEmpty())
        {
            update listToUpdate;
        }
    }
    
 public static void main(list<OpportunityLineItem> newList, map<id,OpportunityLineItem> oldOppMap)
 {
     
 }
    
    
    public static void main(list<OpportunityLineItem> newList)
    {
     map<id,String> opporIds = new map<id,String>();
         map<id,String> accIds = new map<id,String>();
        list<account> updateid = new list<account>();
        if(!newList.isEmpty())
        {
            for(OpportunityLineItem oppNew : newList )
            {
               opporIds.put(oppNew.OpportunityId, oppNew.Description);
            }
        }
        if(!opporIds.isEmpty())
        {
            for(Opportunity opp : [select id, AccountID from Opportunity where ID IN : opporIds.keyset()])
            {
                accIds.put(opp.AccountId,opporIds.get(opp.id) );
            }
        }
        if(!accIds.isEmpty())
        {
            for(Account acc  : [select id, Site from Account where id in : accIds.keyset()])
            {
               acc.Site = accIds.get(acc.id);
                updateid.add(acc);
            }
        }
        if(updateid.size()>0)
        {
            update updateid;
        }
        
    }
    
    /* calculates the total number of line items across all opportunities related to an Account 
     * and updates a custom field on the Account object

find the id of oli and store in set
*/
    
    
    public static void count(list<opportunityLineItem> opps)
    {
        set<id> olis = new set<id>();
        if(!opps.isEmpty())
        {
            for(opportunityLineItem oli : opps )
            {
                olis.add(oli.OpportunityId);
            }
        }
        system.debug('olis'+ olis);
       map<id,Double> oliCount = new map<id,Double>();
        list<account> accUpdate = new list<account>();
        
        for(AggregateResult ar : [select sum(quantity) cou, opportunity.accountid ids from opportunityLineItem
                                  where opportunityid in : olis
                                 
                                 group by opportunity.accountid ])
        {
            oliCount.put((id)ar.get('ids'), (Double)ar.get('cou'));
        }
         system.debug('oliCount'+ oliCount);
        
        for(account acc : [select id, Active_Contacts__c from account where id in : oliCount.keyset()])
        {
            if(oliCount.containskey(acc.id))
            {
                account acc1 = new account();
                acc1.id = acc.id;
                acc1.Active_Contacts__c = oliCount.get(acc.id) != null ?  oliCount.get(acc.id) : 0 ;
                accUpdate.add(acc1);
                  system.debug('oliCount'+ acc + oliCount.get(acc.id));
            }
        }
        if(!accUpdate.isEmpty() && accUpdate != null)
        {
            update accUpdate;
              system.debug('accUpdate'+ accUpdate);
        }
        
    }
    
    /*
     * Write a SOQL query to retrieve the opportunity with the second highest amount. 

Select Count(id), Amount 
from Opportunity
group by amount desc nulls last
offset 1
lmit 1

Write a soql to get all the accounts that have exactly 5 related contacts.

Select Count(id), Accountid from contact
Where Accountid in (Select id from Account)
group by accountid
having count(id) = 5

 
When a new Opportunity Line Item (OpportunityLineItem) is created, automatically increase a counter on the Account that tracks the total number of all line items across all Opportunities for that Account.

A1  -> p1(oli1, ol2) ,p2(oli1)

A2 -> p1, p2, p3 

Write after trigger on OpportunityLineItem
 i Will get id of opp

get the account using id of opp
get the count by using map<id, Integer>


trigger on OpportunityLineItem(after insert)

{
OpportunityLineItem.Counter(trigger.new);

}



Class OpportunityLineItem

{

Public static void Counter(list<OpportunityLineItem> oli)
{
set<id> opportunityIds = new set<id>();

if(!oli.isEmpty())
{
  for(OpportunityLineItem : oli)
{
opportunityIds.add(oli.opportunityid);

}
}

map<id,Integer> accCount = new map<id,Integer>();

list<account> accToUpdate = new list<Account>();

for(AggregateResults opp : [Select Count(id) cou , opportunity.Accountid accid from opportunityLineItem
				where opportunityid in: opportunityIds
				group by opportunity.Accountid ])

{
accCount.put((Id)opp.get('accid'), (Integer)opp.get('accid');
}


for(id accid : AccCount.keyset())
{
account acc = new account();
acc.id = accid;
acc.Oli_Count__c = accCount.get(accid) == null ? 0 : ccCount.get(accid);
accToUpdate.add(acc);


}

if(!accToUpdate.isEmpty() || accToUpdate != null)
{
update accToUpdate;


}


}
childjs

import{ lwc, api} from /lighting;


@api recordid;

handleclick(){ 
const env = new CustomEvent('recordSelector'),
{
detail: { id : this.recordid, name : 'test'}.

bubble : true;
composed : false);

this.dispatchEvent(evt);
}

}






Parenthtml
<template>
<c-child-cmp> record-id={Selectedid} onrecordSelector = {handleRecordValue}  </c-child-cmp>

</template>

handleRecordValue(event){ 
 const(id, name) = event.detail;
console.log('selected id' + id);
}
 




trigger on Account AccountTrigger(Before Delete)

{
AccountTriggerHandler.CheckName(trigger.old);
}

Class AccountTriggerHandler

public static void CheckName(list<account> acc)
set<id> accIds = new set<id>();
Map<id,Integer> accCon = new map<id,Integer>();
for(account acc1 : acc)

{
accIds.add(acc1.id)
}

For(AggregateResults ar : [Select Count(id) cou, accountid ids from contact where accountid in : accids
			and LastName = 'Shivam' group by accountid having count(id) > 0]

{
accCon.put((Id)ar.get('ids'), (integer)ar.get('cou'));
}

for(account acc2 : acc)

if(accCon.ContainsKey(acc2.id)
{
acc2.addError('Cannot Delete this Account' );

}



Global class BatchClass implements Database.batchableContext

public queryLocator start(database.batchableContext BC)

{

}

Execute(batchableContext bc, scope)
{

}


Finish()

{

}

Property -> account -> contact


Three objects 

Account - parent of contact

Contact 

Property - parent of account
 
Status field in all three objects
 
Whenever new contact is created in system then 

1) If contact status is blank and related account status is not blank than copy the account status in contact status

2) If account status is blank and related property status is not blank than copy the property status in contact status



Trigger on Contact ContactTrigger(before insert)

{

ContactTriggerHandler.CheckStatus(trigger.new);

}





Public class ContactTriggerHandler{

Public static void CheckStatus(list<Contact> newCon)

{
set<id> accids = new set<id>();

if(!newCon.isEmpty())
{

for(contact con : newCon)

{
if(con.Accountid != null || !con.Accountid.isEmpty() && con.Status == null)
{
accids.add(Accountid);
}

map<id,String> propStatus = new map<id,String>();
map<id,Property> propMap = new map<id,Property>([Select id, status from property where id in (Select id from account where status = null and id in : accids) and status != null]);


Map<id,Account> accMap = new Map<id,Account>([select id , status  from account where id in : accids and status != null]);
for(account acc1 : select id, property.status from account where id in : accids and status = null ]

{
propStatus.put(id, property.status);

}

for(contact con1 : newCon)

if(accMap.Containskey(con1.accountid) && con1.status == null)

{

con1.status = accMap.get(con1.accountid).status;

}
if(propStatus.Containskey(con1.accountid) && con1.status == null)

{
con1.status = propStatus.get(con1.accountid);

}





3 obj 

acc <> accCon_junc <> con - opp




Trigger on Opportunity OpportunityTrigger(After Insert)

{

opportunity.UpdateAcc(trigger.new);

}


Class Opportunity

{
Public static void UpdateAcc(list<opportunity> opps)
map<id, String> conDateMap = new map<id,string>();
list<Account> accUpdate = new List<Account>();
{

if(!opps.isEmpty())
{
for(opportunity opps1 : opps)
{
if(opps1.contact != null)
{
conDateMap.put(opps1.contactid, String(opps1.Createddate))

}

}

}

map<id,id> accConMap = new map<id,id>();



for(AccountContactJunc__C ac : Select Accountid, Contactid from AccountContactJunc__C
					where contactid in : conDateMap.keyset())

{
accConMap.put( ac.Accountid, ac.Contactid);

}

For(id acc : accConMap.keys())
{

Contact con =  accConMap.get(acc.id)
account acc1 = new account acc1;

acc1.id = acc.id;
acc1.OpportunityCreatedate__C = conDateMap.get(con.id);

accUpdate.add(acc1)


}






}

if(!accUpdate.isempty())

{
update accUpdate;
}

}


2nd largest amt from opp


Select id, amount from opportunity
order by amount desc nulls last

limit 2 
offset 1




String s = '1,2,3,5,4,2,2,1,4,5';
 

write apex to get the count of each string.


Public class Count

{
Public static void checkCount(String str)
String countStr;
Integer Counter = 0;
map<String, Integer> count = new map<String,Integer>();
if(str != null)

{
for(int i = 0; i<=str.length(); i++)

{

countStr = str.subString(i,i+1);

if(count.containsKey(countStr) && countStr != null)
{
Counter++;
count.put(countStr,Counter);

}
}

System.debug(' Count of ' + count.keyset() + 'is ' count.Values();



}


}


}

Account Email is updated , update all the related contact email field with the same email
.



1. Write trigger on Account after update
2. Store the acc ids and email in map.
3. get the contacts with the accids.
4. update email which is related to account.



Trigger on Account AccountTrigger(After Update)

{
AccountTriggerHandler.updateEmailRelatedContacts(Trigger.new, Trigger.oldMap);

}

Class AccountTriggerHandler{

Public Static void updateEmailRelatedContacts(List<Account> acc, map<id,Account> oldAccMap)
{

map<id,String> accEmailMap = new map<id,String>();
list<Contact> contactsToUpdate = new list<Contact>();
if(!acc.isEmpty())
{

for(account acc1 : acc)

{
if(oldAccMap != null)

{
account oldAcc = oldAccmap.get(acc1.id);

if(acc1.email != oldAcc.Email)
{
accEmailMap.put(acc1.id, acc1.email);

}

}

}

for(Contact con : [Select id, email, Accountid from Contact where Accountid in: accEmailMap.keyset()])

if(accEmailMap.Containskey(con.accountid))
{
Contact con1 = new contact();
con1.id = con.id;
con1.Email = accEmailMap.get(con.Accountid);
contactsToUpdate.add(con1);

}

If(!contactsToupdate.isEmpty())
{
update contactsToUpdate;

}
			




}




}




}





























}

}

}


}



 


 



*/
    

}