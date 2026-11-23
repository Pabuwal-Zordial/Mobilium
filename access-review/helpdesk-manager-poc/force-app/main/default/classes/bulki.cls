public class bulki {
    public static void main()
    {
        list<contact> con = new list<contact>();
for(integer i = 1;i<10;i++)
{
    contact con1 = new contact();
    con1.FirstName = 'shicam' + i;
    con1.Email= ' shivam' +i + 'pa'+ i + '@gmail'+ i + '.com';
    con.add(con1);
    con1.Phone = '894794256'+i;
    con1.AccountId = '0012w000007GfnXAAS';
    con1.LastName = 'pa' + i;
}
if(con!= null){
    
insert con;
    for(contact con12 : con)
    {
        system.debug('contact record is ' + con12);
        system.debug('contact record is ' + con.size());
    }
}
    }
}