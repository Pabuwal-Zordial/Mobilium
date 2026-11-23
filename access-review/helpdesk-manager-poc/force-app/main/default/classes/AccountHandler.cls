public class AccountHandler {
 public static Account insertNewAccount( string accname)
 {
     account acc = new account();
     acc.name = accname;
     try{
         insert acc;
     } catch(exception e)
     {
         return null;
     }
 return acc;      
 }
}