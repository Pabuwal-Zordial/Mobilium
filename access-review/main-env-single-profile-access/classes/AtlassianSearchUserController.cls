public with sharing class AtlassianSearchUserController
{
	@AuraEnabled
	public static List<JiraResponse.JiraUser> searchUsers(String searchTerm)
	{
		try
		{
			ProjectUtils.Response response = JiraServices.searchUsers(searchTerm);
			if (response.isSuccess)
			{
				List<JiraResponse.JiraUser> result = (List<JiraResponse.JiraUser>) JSON.deserialize(String.valueOf(response.value), List<JiraResponse.JiraUser>.class);
				return result;
			}
			else
			{
				throw new AtlassianSearchUserControllerException(response.message);
			}
		}
		catch (Exception e)
		{
			throw new AuraHandledException(e.getMessage());
		}
	}

	private class AtlassianSearchUserControllerException extends Exception {}
}