public with sharing class JiraRequest
{
	public class Project
	{
		public String key { get; set; }
		public String name { get; set; }
		public String projectTypeKey { get; set; }
		public String projectTemplateKey { get; set; }
		public String description { get; set; }
		public String lead { get; set; }
		public String url { get; set; }
		public String assigneeType { get; set; }
		public Integer avatarId { get; set; }
		public Integer issueSecurityScheme { get; set; }
		public Integer permissionScheme { get; set; }
		public Integer notificationScheme { get; set; }
		public Integer categoryId { get; set; }
	}

	public class ProjectPermission
	{
		public String projectKey { get; set; }
		public String role { get; set; }
		public List<String> usersOrGroups { get; set; }
	}

	public class ProjectComponent
	{
		public Object lead { get; set; }
		public String assigneeType { get; set; }
		public String project { get; set; }
		public Integer projectId { get; set; }
	}
}