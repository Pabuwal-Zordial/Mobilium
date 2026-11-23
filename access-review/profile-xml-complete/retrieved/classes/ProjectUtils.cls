public with sharing class ProjectUtils
{
	public class Response
	{
		@AuraEnabled public Boolean isSuccess { get; set; }
		@AuraEnabled public String message { get; set; }
		@AuraEnabled public Object value { get; set; }

		public Response(Boolean isSuccess, String message, Object value)
		{
			this.isSuccess = isSuccess;
			this.message = message;
			this.value = value;
		}
	}

	public static String replaceBodyVariables(String body, Map<String,String> data)
	{
		for (String variable : data.keySet())
		{
			body = body.replace(variable, data.get(variable));
		}

		return body;
	}

	public static void sendEmailNotification(List<String> toAddresses, String subject, String body)
	{
		try
		{
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			mail.setToAddresses(toAddresses);
			mail.setSubject(subject);
			mail.setHtmlBody(body);
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
		}
		catch (System.EmailException e)
		{
			if (!e.getMessage().contains('NO_MASS_MAIL_PERMISSION'))
			{
				throw e;
			}
			System.debug('Email Deliverability disabled: ' + e.getMessage());
		}
	}
}