public class soqltets1 {

    public static void main()
    {
       /* list<String> str1 = new list<string>{'Shivam'};
     list<Account>  list1 = [Select name, id from Account where name NOT IN : str1 ];
        //system.debug(list1.size());
        system.debug('>>>>' + list1);*/
        string str = 'Closed Won';

List<opportunity> caseList = [SELECT  amount, stagename from opportunity 
WHERE OwnerId=:UserInfo.getUserID() 
And Stagename =:str];
        system.debug(caselist.size());
        for(opportunity opp : caselist)
            
            system.debug('...' + opp);
    }
}