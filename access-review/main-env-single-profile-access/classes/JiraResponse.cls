public with sharing class JiraResponse
{

	public static Project getProjectObject(String jsonString)
	{
		return (Project) JSON.deserialize(jsonString, Project.class);
	}

	public class Project
	{
		@AuraEnabled public String id { get; set; }
		@AuraEnabled public String self { get; set; }
		@AuraEnabled public String key { get; set; }
		@AuraEnabled public List<Component> components { get; set; }
	}

	public class Component
	{
		@AuraEnabled public String assigneeType { get; set; }
		@AuraEnabled public String project { get; set; }
		@AuraEnabled public Object lead { get; set; }
		@AuraEnabled public Integer projectId { get; set; }
	}

	public class JiraUser
	{
		@AuraEnabled public String key { get; set; }
		@AuraEnabled public String name { get; set; }
		@AuraEnabled public String displayName { get; set; }
		@AuraEnabled public String emailAddress { get; set; }
	}
}