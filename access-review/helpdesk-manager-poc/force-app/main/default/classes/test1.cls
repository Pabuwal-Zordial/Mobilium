public class test1 {
       
    public static void main()
    {
       
        string query = 'select id,name from contact where accountid = null order by lastname asc ';
        list<contact> con = database.query(query);
        if(!con.isempty())
        {
            for(contact con1 : con)
                system.debug(con1);
            system.debug(con.size());
        }
    }
}