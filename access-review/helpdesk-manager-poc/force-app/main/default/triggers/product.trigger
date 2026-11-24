trigger product on Lead (before insert, before update) {
    if(trigger.isbefore && (trigger.isinsert || trigger.isupdate))
    {
        for(lead ld : trigger.new)
        {
            if(ld.industry == null || ld.Industry == '' || ld.Industry == 'none')
                ld.adderror('enter the industrt');
        }
    }

}