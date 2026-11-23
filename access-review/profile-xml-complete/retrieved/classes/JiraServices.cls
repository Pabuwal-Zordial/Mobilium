public with sharing class JiraServices
{
	public static final String JIRA_BASE_URL = Atlassian_Configs__c.getOrgDefaults().Jira_Base_URL__c;

	public static ProjectUtils.Response createProjectWithTemplate(String templateId, JiraRequest.Project project)
	{
		String endpoint = JIRA_BASE_URL + 'project-templates/1.0/createshared/' +  templateId;

		return AtlassianConnector.doRequest(endpoint, 'POST', project);
	}

	public static ProjectUtils.Response updateProject(JiraRequest.Project project)
	{
		String endpoint = JIRA_BASE_URL + 'api/2/project/' + project.key;

		return AtlassianConnector.doRequest(endpoint, 'PUT', project);
	}

	public static ProjectUtils.Response createProject(JiraRequest.Project project)
	{
		String endpoint = JIRA_BASE_URL + 'api/2/project';

		return AtlassianConnector.doRequest(endpoint, 'POST', project);
	}

	public static ProjectUtils.Response getProject(String projectIdOrKey)
	{
		String endpoint = JIRA_BASE_URL + 'api/2/project/' + projectIdOrKey;

		return AtlassianConnector.doRequest(endpoint, 'GET', null);
	}

	public static ProjectUtils.Response addProjectPermission(JiraRequest.ProjectPermission projectPermission)
	{
		String endpoint = JIRA_BASE_URL + 'api/2/project/' + projectPermission.projectKey + '/role/' + projectPermission.role;
		Map<String, List<String>> body = new Map<String, List<String>>
		{
			'user' => projectPermission.usersOrGroups
		};

		return AtlassianConnector.doRequest(endpoint, 'POST', body);
	}

	public static ProjectUtils.Response deleteProjectPermission(String projectKey, String roleId, String username)
	{
		String endpoint = JIRA_BASE_URL + 'api/2/project/' + projectKey + '/role/' + roleId + '?user=' + username;

		return AtlassianConnector.doRequest(endpoint, 'DELETE', null);
	}

	public static ProjectUtils.Response addProjectComponent(JiraRequest.ProjectComponent component)
	{
		String endpoint = JIRA_BASE_URL + 'api/2/component';

		return AtlassianConnector.doRequest(endpoint, 'POST', component);
	}

	public static ProjectUtils.Response searchUsers(String searchTerm)
	{
		String endpoint = JIRA_BASE_URL + 'api/2/user/search?username=' + EncodingUtil.urlEncode(searchTerm, 'UTF-8');

		return AtlassianConnector.doRequest(endpoint, 'GET', null);
	}
}