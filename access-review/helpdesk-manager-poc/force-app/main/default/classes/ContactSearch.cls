public class ContactSearch {
    public static list<contact> searchForContacts(string a, string b)
    {
        list<contact> con = [select id , name,  lastname , MailingPostalCode from contact where lastname =: a and MailingPostalCode =: b];
        system.debug('contact is' + con);
            return con;
        }
    }