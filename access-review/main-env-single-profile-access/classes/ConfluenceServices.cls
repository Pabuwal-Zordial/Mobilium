public with sharing class ConfluenceServices
{
	public static final String CONFLUENCE_BASE_URL = Atlassian_Configs__c.getOrgDefaults().Confluence_Base_URL__c;
	public static final String CONFLUENCE_RPC_BASE_URL = Atlassian_Configs__c.getOrgDefaults().Confluence_RPC_Base_URL__c;
	public static final String CONFLUENCE_EXPERIMENTAL_BASE_URL = Atlassian_Configs__c.getOrgDefaults().Confluence_Experimental_Base_URL__c;

	public static ProjectUtils.Response getSpace(String key)
	{
		String endpoint = CONFLUENCE_BASE_URL + 'space/' + key + '?expand=homepage';
		return  AtlassianConnector.doRequest(endpoint, 'GET', null);
	}

	public static ProjectUtils.Response createSpace(ConfluenceRequest.Space space)
	{
		String endpoint = CONFLUENCE_BASE_URL + 'space';
		return  AtlassianConnector.doRequest(endpoint, 'POST', space);
	}

	public static ProjectUtils.Response addSpacePermissions(ConfluenceRequest.SpacePermission spacePermission)
	{
		String endpoint = CONFLUENCE_RPC_BASE_URL + 'addPermissionsToSpace';

		List<Object> request = new List<Object>
		{
			spacePermission.permissions,
			spacePermission.userOrGroup,
			spacePermission.spaceKey
		};

		return  AtlassianConnector.doRequest(endpoint, 'POST', request);
	}

	public static ProjectUtils.Response addSpaceCategory(String spaceKey, String category)
	{
		String endpoint = CONFLUENCE_RPC_BASE_URL + 'addLabelByNameToSpace';

		List<String> request = new List<String>
		{
			'team:' + category,
			spaceKey
		};

		return AtlassianConnector.doRequest(endpoint, 'POST', request);
	}


	public static ProjectUtils.Response createPage(ConfluenceRequest.SpacePage page)
	{
		String endpoint = CONFLUENCE_BASE_URL + 'content';

		return AtlassianConnector.doRequest(endpoint, 'POST', page);
	}

	public static ProjectUtils.Response updatePage(ConfluenceRequest.SpacePage page)
	{
		String endpoint = CONFLUENCE_BASE_URL + 'content/' + page.id;

		return AtlassianConnector.doRequest(endpoint, 'PUT', page);
	}

	public static ProjectUtils.Response getAllSpacePages(String spaceKey)
	{
		String endpoint = CONFLUENCE_BASE_URL + 'space/' + spaceKey + '/content?expand=childTypes.page';

		return AtlassianConnector.doRequest(endpoint, 'GET', null);
	}

	public static ProjectUtils.Response getPagesByTitle(String title, String spaceKey)
	{
		List<String> params = new List<String>();

		if (String.isNotBlank(title))
		{
			params.add('title=' + EncodingUtil.urlEncode(title, 'UTF-8'));
		}

		if (String.isNotBlank(spaceKey))
		{
			params.add('spaceKey=' + EncodingUtil.urlEncode(spaceKey, 'UTF-8'));
		}

		params.add('expand=body.storage,version');

		String queryString = String.join(params, '&');
		String endpoint = CONFLUENCE_BASE_URL + 'content?' + queryString;

		return AtlassianConnector.doRequest(endpoint, 'GET', null);
	}

	public static ProjectUtils.Response getPagesByParentId(String pageId)
	{
		String endpoint = CONFLUENCE_BASE_URL + 'content/search?cql=parent=' + pageId + '&expand=body.storage,version';

		return AtlassianConnector.doRequest(endpoint, 'GET', null);
	}

	public static ProjectUtils.Response addSpacePagePermission(ConfluenceRequest.SpacePagePermission pagePermission)
	{
		String endpoint = CONFLUENCE_EXPERIMENTAL_BASE_URL + 'content/' + pagePermission.pageId + '/restriction/byOperation/' + pagePermission.permission + '/' + pagePermission.type;
		endpoint += (pagePermission.type == AtlassianConstants.PERMISSION_TYPE_GROUP ? '/' : '?userName=') + pagePermission.userOrGroup;

		return AtlassianConnector.doRequest(endpoint, 'PUT', null);
	}

	public static ProjectUtils.Response removeSpacePermission(ConfluenceRequest.SpacePermission spacePermission)
	{
		String endpoint = CONFLUENCE_RPC_BASE_URL + 'removePermissionFromSpace';

		List<Object> request = new List<Object>
		{
			spacePermission.permissions,
			spacePermission.userOrGroup,
			spacePermission.spaceKey
		};

		return  AtlassianConnector.doRequest(endpoint, 'POST', request);
	}

	public static ProjectUtils.Response removeSpacePagePermission(ConfluenceRequest.SpacePagePermission pagePermission)
	{
		String endpoint = CONFLUENCE_EXPERIMENTAL_BASE_URL + 'content/' + pagePermission.pageId + '/restriction/byOperation/' + pagePermission.permission + '/' + pagePermission.type;
		endpoint += (pagePermission.type == AtlassianConstants.PERMISSION_TYPE_GROUP ? '/' : '?userName=') + pagePermission.userOrGroup;

		return AtlassianConnector.doRequest(endpoint, 'DELETE', null);
	}
}