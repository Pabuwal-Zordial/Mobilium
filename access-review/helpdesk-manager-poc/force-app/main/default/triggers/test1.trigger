trigger test1 on Contact (before insert, before update) {
    if(trigger.isbefore && (trigger.isinsert || trigger.isupdate))
    {
        for(contact con : trigger.new)
        {
            integer a = 10;
            if(con.Phone == null || con.Phone=='')
            {
              

                con.adderror('Enter the 10 digit phone number');
            }
            else if( con.Email== null || con.Email == '')
            {
                con.adderror('enter email');
            }
        }
    }
}