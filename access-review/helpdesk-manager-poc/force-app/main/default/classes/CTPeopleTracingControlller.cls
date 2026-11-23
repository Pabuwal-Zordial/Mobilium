public class CTPeopleTracingControlller {
    public static list<People_Tracing__c> getTraces(string personid)
    {
        return[SELECT Id, Name, Contact_Date__c, Contact_Type__c, Person_1__c, Person_2__c FROM People_Tracing__c where person_1__c =: personid or person_2__c =: personid order by Contact_Date__c desc nulls last ];
    }
     public static list<People_Tracing__c> checkDuplicates(list<People_Tracing__c> peopleTraces)
    {
        set<id> people1 = new set<id>();
         set<id> people2 = new set<id>();
        list<People_Tracing__c> dup = new list<People_Tracing__c>();
        list<People_Tracing__c>  peoplelst1 = new list<People_Tracing__c>();
        
        map<id,set<id>> checkDuplicate = new map<id,set<id>>();
        
        for(People_Tracing__c peopleTrace : peopleTraces )
        {
           people1.add(peopleTrace.Person_1__c);
            people2.add(peopleTrace.Person_2__c);
            
            
        }
        list<People_Tracing__c> peoplelst = [select id, Person_1__c , Person_2__c from People_Tracing__c where Person_1__c IN : people1 or Person_2__c IN : people2 ];
            if(peoplelst.size()>0 && peoplelst!=null)
        {
            for(People_Tracing__c trace : peoplelst )
        {
           if(!checkDuplicate.containsKey(trace.Person_1__c))
           {
              checkDuplicate.put(trace.person_1__c, new set<id>());
           }
            checkDuplicate.get(trace.person_1__c).add(trace.person_2__c);
        
            
             if(!checkDuplicate.containsKey(trace.Person_2__c))
           {
              checkDuplicate.put(trace.person_2__c, new set<id>());
           }
            checkDuplicate.get(trace.person_2__c).add(trace.person_1__c);
            
            
            
            for(People_Tracing__c lst : peopleTraces)
            {
                if(checkDuplicate.containsKey(lst.person_1__c) && checkduplicate.get(lst.person_1__c).contains(trace.person_2__C) 
                  || checkDuplicate.containsKey(lst.person_2__c) && checkduplicate.get(lst.person_2__c).contains(trace.person_1__C) 
                   )
                {
                    peoplelst1.add(lst);
                }
                    
            }
            
        
            
      
       // return[SELECT Id, Name, Contact_Date__c, Contact_Type__c, Person_1__c, Person_1__c FROM People_Tracing__c where id =: recordid order by Contact_Date__c desc nulls last ];
    }
        }
          return peoplelst1;
    }
    

}