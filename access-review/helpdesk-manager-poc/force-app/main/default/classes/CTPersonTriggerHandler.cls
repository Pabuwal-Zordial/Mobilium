public class CTPersonTriggerHandler {
    public static void beforeperson(list<person__c> newRecords)
    {
        for(person__c person : newRecords)
        {
           person.Health_Status__c = 'green';
           person.Token__c = CTPersonController.getToken(person.Mobile__c);
            
        }
    }
    public static void afterupdate(list<person__c> newRecords, map<id,person__c> oldPersonMap)
    {
        set<id> statusChange = new set<id>();
        set<id> RedStatus = new set<id>();
            set<id> orangeStatus = new set<id>();
            set<id> yellowStatus = new set<id>();
         set<id> alreadyProcessed = new set<id>();
       
       
        for(person__C person : newRecords )
        {
            if( person.health_status__c != oldPersonMap.get(person.id).health_status__c)
            {
                statusChange.add(person.id);
               
            }
            if( person.health_status__c == 'Red' && oldPersonMap.get(person.id).health_status__c != 'Red')
            {
                RedStatus.add(person.id);
               
            }
         
        }
        orangeStatus.addall(CTPersonController.getCohabitants(Redstatus, alreadyProcessed));
        yellowStatus.addall(CTPersonController.getNeighbour(Redstatus, alreadyProcessed));
       
        orangeStatus.addall(CTPersonController.getPrimaryContact(Redstatus, alreadyProcessed));
        yellowStatus.addall(CTPersonController.getCohabitants(Redstatus, alreadyProcessed));
        
        
       // for(Location_Tracing__c loc :  [ select id ])
    }
    

}