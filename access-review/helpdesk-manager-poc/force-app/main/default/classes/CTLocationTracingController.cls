public class CTLocationTracingController {
    public static list<Location_Tracing__c> getVisitors(String LocationID)
{
    return [SELECT Id, Name, Person__c, Location__c, Visit_Date__c FROM Location_Tracing__c where id =: locationID order by Visit_Date__c DESC nulls last];
}
    public static list<Location_Tracing__c> getLocationbyPersonIds(Set<id> personIDs)
{
    return [SELECT Id, Name, Person__c, Location__c, Visit_Date__c, person__r.id FROM Location_Tracing__c where person__r.id =: personIDs and visit_date__c = LAST_N_DAYS:10 order by Visit_Date__c DESC nulls last];
}
     public static list<Location_Tracing__c> getLocationbyLocationIds(Set<id> LocationIDs)
{
    return [SELECT Id, Name, Person__c, Location__c, Visit_Date__c FROM Location_Tracing__c where Location__c =: LocationIDs and person__r.Health_Status__c = 'Green' and  visit_date__c = LAST_N_DAYS:10 order by Visit_Date__c DESC nulls last];
}
    public static list<Location_Tracing__c> checkDuplicates(list<Location_Tracing__c> LocationTraces)
    {
       // list<Location_Tracing__c> locationLst  = [Select  Id, Name, Person__c, Location__c, Visit_Date__c FROM Location_Tracing__c];
        set<id> locid = new set<id>();
        set<id> perId = new set<id>();
        map<id, set<id>> mapdup = new map<id, set<id>>();
        for(Location_Tracing__c trace : LocationTraces )
        {
            locid.add(trace.location__c);
            perId.add(trace.person__C);
            
        }
           list<Location_Tracing__c> locationLst  = [Select  Id, Name, Person__c, Location__c, Visit_Date__c FROM Location_Tracing__c where person__c =: perid and location__c =: locid];
         list<Location_Tracing__c> duplicate =  new list<Location_Tracing__c>();
        if(locationLst.size()>0 && locationLst!=null)
        {
           for(Location_Tracing__c trace : locationLst )
           {
               if(!mapdup.containskey(trace.Location__c))
               {
                   mapdup.put(trace.Location__c, new set<id>());
               }
               mapdup.get(trace.Location__c).add(trace.Person__c);
               
           }
        }
        for(location_tracing__c trace : LocationTraces )
        {
            if(mapdup.containskey(trace.Location__c) && mapdup.get(trace.Location__c).contains(trace.Person__c))
            {
               duplicate.add(trace);
            }
        }
        return duplicate;
    }
    
    

    

}