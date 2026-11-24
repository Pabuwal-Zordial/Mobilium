trigger replica on Account (after insert, after update) {
    if(trigger.isafter && (trigger.isupdate || trigger.isinsert))
    {
        list<contact> con = new list<contact>();
        for(account acc : trigger.new)
        {
            contact c = new contact();
            c.Phone = acc.phone;
            c.Fax=acc.fax;
            
            con.add(c);

                }
        insert con;
    }

}