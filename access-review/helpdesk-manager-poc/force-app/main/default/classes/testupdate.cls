public class testupdate {
public static void main(integer n)
{
    list<contact> con1 = new list<contact>();
    integer counter =1;
    while(counter<n)
    {
      contact con = new contact();
    con.firstname = 'Shivam' + n;
    con.lastname = 'testlist' + n;
      //   system.debug(con.id);

   con1.add(con);
        counter = counter +1;
    }
   insert con1;
    if(con1 != null)
    {
        for(contact con12 : con1)
            system.debug(con12.id);
    }
   
}
}