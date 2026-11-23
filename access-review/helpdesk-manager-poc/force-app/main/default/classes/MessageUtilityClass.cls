public class MessageUtilityClass {
    
     public static void sendMail(AsyncApexJob jobidDetails, decimal amt) {
        // Create an email message object
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {'shivampabuwal500@gmail.com'};
        mail.setToAddresses(toAddresses);
        mail.setSubject(jobidDetails.id + '' + amt);
        mail.setPlainTextBody('qwe');
        // Pass this email message to the built-in sendEmail method 
        // of the Messaging class
       Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        // Call a helper method to inspect the returned results
        //inspectResults(results);
    }

}