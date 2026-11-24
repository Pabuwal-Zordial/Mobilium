public class data {
    public static void main()
    {
        list<contact> updatecontact = new list<contact>();
        list<account> acc = [select id,name, phone, fax ,(select name, phone from contacts ) from account where name = 'Burlington Textiles Corp of America' ];
        if(acc != null)
        {
            for(account acc1 : acc)
            {
                for(contact con : acc1.contacts)
                {
                    con.phone = acc1.phone;
                updatecontact.add(con);
                    
                }
            }
            if(updatecontact!= null)
            {
                update updatecontact;
            }
        }
    }

}