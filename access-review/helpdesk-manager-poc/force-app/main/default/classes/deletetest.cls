public class deletetest {
    public static void main(string na)
    {
        if(na != null && na!= '')
        {
             na += '%';
            list<contact> con = [select id, name from contact where name like : na];
            if(con!= null)
            {
                delete con;
                system.debug(con.size());
            }
               
                }
    }

}