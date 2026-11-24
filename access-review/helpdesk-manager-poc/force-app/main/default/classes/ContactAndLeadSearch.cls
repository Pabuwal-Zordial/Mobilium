public class ContactAndLeadSearch {
    public static list<list<sobject>> searchContactsAndLeads(string namee)
    {
       string query = 'find \'' + namee + '\' in all fields returning lead(name, firstname, lastname), contact(firstname, lastname)';
        list<list<sobject>> searchcon = search.query(query);
        return searchcon;

}
}