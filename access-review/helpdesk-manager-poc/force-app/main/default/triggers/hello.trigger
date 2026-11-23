trigger hello on Account (before insert) {
    if(trigger.isbefore && trigger.isinsert)
    {
        for(account acc : trigger.new)
        {
            if(acc.hello__c != 'world')
            acc.hello__c = 'world';
                
        }
    }

}