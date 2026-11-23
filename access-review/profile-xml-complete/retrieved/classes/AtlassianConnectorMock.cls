global class AtlassianConnectorMock implements HttpCalloutMock
{
	global HTTPResponse respond(HTTPRequest request)
	{
		String endpoint = request.getEndpoint();
		String method = request.getMethod();
		if (endpoint == 'https://www.confluence.com/base/space/TESTCA?expand=homepage' && method == 'GET')
		{
			return this.generateGetSpaceResponse();
		}
		else if (endpoint == 'https://www.confluence.com/base/space' && method == 'POST')
		{
			return this.generateCreateSpaceResponse();
		}
		else if (endpoint == 'https://www.confluence.com/rpcbase/addPermissionsToSpace' && method == 'POST')
		{
			return this.generateAddSpacePermissionseResponse();
		}
		else if (endpoint == 'https://www.confluence.com/rpcbase/addLabelByNameToSpace' && method == 'POST')
		{
			return this.generateAddLabelByNameToSpaceResponse();
		}
		else if (endpoint == 'https://www.confluence.com/base/content?title=customer_space_template_page_title&spaceKey=customer_space_template_key&expand=body.storage,version' && method == 'GET')
		{
			return this.generateGetPagesByTitleResponse();
		}
		else if (endpoint == 'https://www.confluence.com/base/content?title=Project+Support+Office&spaceKey=TESTCA&expand=body.storage,version' && method == 'GET')
		{
			return this.generateGetPagesByTitleResponse();
		}
		else if (endpoint == 'https://www.confluence.com/base/content?title=Project+Deliverables+Map&spaceKey=11TESTCA01001&expand=body.storage,version' && method == 'GET')
		{
			return this.generateGetPagesByTitleResponse();
		}
		else if (endpoint == 'https://www.confluence.com/base/content?title=eid_space_template_title&spaceKey=eid_space_template_key&expand=body.storage,version' && method == 'GET')
		{
			return this.generateGetPagesByTitleResponse();
		}
		else if (endpoint == 'https://www.confluence.com/base/content?title=customer_eid_page_space_template_page_title&spaceKey=customer_eid_page_space_template_key&expand=body.storage,version' && method == 'GET')
		{
			return this.generateGetPagesByTitleResponse();
		}
		else if (endpoint == 'https://www.confluence.com/base/content/12345' && method == 'PUT')
		{
			return this.generateUpdatePageResponse();
		}
		else if (endpoint == 'https://www.confluence.com/base/content/search?cql=parent=12345&expand=body.storage,version' && method == 'GET')
		{
			return this.generateGetPagesByParentIdWithContentResponse();
		}
		else if (endpoint == 'https://www.confluence.com/base/content/search?cql=parent=67890&expand=body.storage,version' && method == 'GET')
		{
			return this.generateGetPagesByParentIdWithoutContentResponse();
		}
		else if (endpoint == 'https://www.confluence.com/base/content' && method == 'POST')
		{
			return this.generateCreatePageResponse();
		}
		else if (endpoint == 'https://www.confluence.com/base/space/TESTCA/content?expand=childTypes.page' && method == 'GET')
		{
			return this.generateGetAllSpacePagesResponse();
		}
		else if (endpoint.startsWith('https://www.confluence.com/expbase/content/12345678/restriction/byOperation') && method == 'PUT')
		{
			return this.generateAddSpacePermissionsResponse();
		}
		else if (endpoint.startsWith('https://www.confluence.com/expbase/content/12345/restriction/byOperation') && method == 'PUT')
		{
			return this.generateAddSpacePermissionsResponse();
		}
		else if (endpoint.startsWith('https://www.confluence.com/expbase/content/67890/restriction/byOperation') && method == 'PUT')
		{
			return this.generateAddSpacePermissionsResponse();
		}
		else if (endpoint == 'https://www.confluence.com/base/space/11TESTCA01001?expand=homepage' && method == 'GET')
		{
			return this.generateGetSpaceResponse();
		}
		else if (endpoint == 'https://www.jira.com/base/api/2/project/project_template_key' && method == 'GET')
		{
			return this.generateCreateJiraProjectResponse();
		}
		else if (endpoint == 'https://www.jira.com/base/project-templates/1.0/createshared/12345' && method == 'POST')
		{
			return this.generateUpdateJiraProjectResponse();
		}
		else if (endpoint == 'https://www.jira.com/base/api/2/project/M11TESTCA01001' && method == 'PUT')
		{
			return this.generateCreateJiraProjectResponse();
		}
		else if (endpoint.startsWith('https://www.jira.com/base/api/2/project/project/role/') && method == 'POST')
		{
			return this.generateJiraPermissionsResponse();
		}
		else if (endpoint.startsWith('https://www.jira.com/base/api/2/project/M11TESTCA01001/role/') && method == 'POST')
		{
			return this.generateJiraPermissionsResponse();
		}
		else if (endpoint.startsWith('https://www.jira.com/base/api/2/project/M11TESTCA01001/role/') && method == 'DELETE')
		{
			return this.generateJiraPermissionsResponse();
		}
		else if (endpoint.startsWith('https://www.confluence.com/base/content?title=11TESTCA.01.001+-+Test+Project&spaceKey=TESTCA&expand=body.storage,version') && method == 'GET')
		{
			return this.generateGetPagesByTitleResponse();
		}
		else if (endpoint.startsWith('https://www.jira.com/base/api/2/user/search?username=test') && method == 'GET')
		{
			return this.generateSearchUserResponse();
		}
		else if (endpoint.startsWith('https://www.jira.com/base/api/2/user/search?username=fail') && method == 'GET')
		{
			return this.generateFailedSearchUserResponse();
		}
		else if (endpoint.startsWith('https://www.jira.com/base/api/2/component') && method == 'POST')
		{
			return this.generateAddSComponentResponse();
		}
		return null;
	}

	private HttpResponse generateAddSComponentResponse()
	{
		HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json');
		response.setBody('');
		response.setStatusCode(200);
		return response;
	}

	private HttpResponse generateSearchUserResponse()
	{
		HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json');
		response.setBody('[{"key":"test","name":"test","displayName":"test","emailAddress":"test@test.com"}]');
		response.setStatusCode(200);
		return response;
	}

	private HttpResponse generateFailedSearchUserResponse()
	{
		HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json');
		response.setBody('[]');
		response.setStatusCode(404);
		response.setStatus('404');
		return response;
	}

	private HttpResponse generateGetSpaceResponse()
	{
		HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json');
		response.setBody('Not found');
		response.setStatusCode(404);
		return response;
	}

	private HttpResponse generateCreateSpaceResponse()
	{
		ConfluenceResponse.Space space = new ConfluenceResponse.Space();
		space.id = 12345;
		space.key = 'TESTCA';
		space.name = 'Test Account';
		space.homepage = new ConfluenceResponse.Content();
		space.homepage.id = '12345';
		space.homepage.body = new ConfluenceResponse.ContentBody();
		space.homepage.body.storage = new ConfluenceResponse.Storage();
		space.homepage.body.storage.value = 'storage';
		space.links = new Map<String, String> { 'base' => 'http://www.confluence.com/', 'webui' => 'TESTCA' };

		HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json');
		response.setBody(JSON.serialize(space));
		response.setStatusCode(200);
		return response;
	}


	private HttpResponse generateAddSpacePermissionseResponse()
	{
		HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json');
		response.setBody('');
		response.setStatusCode(200);
		return response;
	}

	private HttpResponse generateAddLabelByNameToSpaceResponse()
	{
		ConfluenceResponse.Space space = new ConfluenceResponse.Space();
		space.id = 12345;
		space.key = 'TESTCA';
		space.name = 'Test Account';
		space.homepage = new ConfluenceResponse.Content();
		space.homepage.id = '12345';
		space.homepage.body = new ConfluenceResponse.ContentBody();
		space.homepage.body.storage = new ConfluenceResponse.Storage();
		space.homepage.body.storage.value = 'storage';
		space.links = new Map<String, String> { 'base' => 'http://www.confluence.com/', 'webui' => 'TESTCA' };

		HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json');
		response.setBody(JSON.serialize(space));
		response.setStatusCode(200);
		return response;
	}

	private HttpResponse generateGetPagesByTitleResponse()
	{
		ConfluenceResponse.ContentArray contentArray = new ConfluenceResponse.ContentArray();
		contentArray.results = new List<ConfluenceResponse.Content>();
		ConfluenceResponse.Content homepageTemplate = new ConfluenceResponse.Content();
		homepageTemplate.id = '12345';
		homepageTemplate.body = new ConfluenceResponse.ContentBody();
		homepageTemplate.body.storage = new ConfluenceResponse.Storage();
		homepageTemplate.body.storage.value = '&lt;CUSTOMER_NAME&gt;&lt;LONG_EID&gt;&lt;PROJECT_CLASSIFICATION&gt;&lt;PROJECT_NAME&gt;&lt;PROJECT_DIRECTOR&gt;&lt;PROJECT_MANAGER&gt;&lt;PROJECT_TYPE&gt&lt;PROJECT_STATUS&gt&lt;YYYY-MM-DD&gt;&lt;YYYYMMDD&gt;';
		homepageTemplate.body.storage.representation = 'text';
		homepageTemplate.version = new ConfluenceResponse.ContentPageVersion();
		homepageTemplate.version.versionNumber = 1;
		contentArray.results.add(homepageTemplate);

		HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json');
		response.setBody(JSON.serialize(contentArray));
		response.setStatusCode(200);
		return response;
	}

	private HttpResponse generateUpdatePageResponse()
	{
		HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json');
		response.setBody('');
		response.setStatusCode(200);
		return response;
	}

	private HttpResponse generateGetPagesByParentIdWithContentResponse()
	{
		ConfluenceResponse.ContentArray contentArray = new ConfluenceResponse.ContentArray();
		ConfluenceResponse.Content content = new ConfluenceResponse.Content ();
		content.id = '67890';
		content.title = 'Sub Page';
		content.extensions = new ConfluenceResponse.ContentExtensions();
		content.extensions.position = '2';
		content.space = new ConfluenceResponse.Space();
		content.space.id = 12345;
		content.body = new ConfluenceResponse.ContentBody();
		content.body.storage = new ConfluenceResponse.Storage();
		content.body.storage.value = '';
		content.body.storage.representation = 'storage';
		contentArray.results = new List<ConfluenceResponse.Content>();
		contentArray.results.add(content);

		HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json');
		response.setBody(JSON.serialize(contentArray));
		response.setStatusCode(200);
		return response;
	}

	private HttpResponse generateGetPagesByParentIdWithoutContentResponse()
	{
		ConfluenceResponse.ContentArray contentArray = new ConfluenceResponse.ContentArray();
		contentArray.results = new List<ConfluenceResponse.Content>();

		HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json');
		response.setBody(JSON.serialize(contentArray));
		response.setStatusCode(200);
		return response;
	}

	private HttpResponse generateCreatePageResponse()
	{
		ConfluenceResponse.Content content = new ConfluenceResponse.Content();
		content.id = '67890';
		content.links = new Map<String, String> { 'base' => 'http://www.confluence.com/', 'webui' => 'TESTCA' };

		HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json');
		response.setBody(JSON.serialize(content));
		response.setStatusCode(200);
		return response;
	}

	private HttpResponse generateGetAllSpacePagesResponse()
	{
		ConfluenceResponse.SpacePages pages = new ConfluenceResponse.SpacePages();
		pages.response = new ConfluenceResponse.ContentArray();
		pages.response.results = new List<ConfluenceResponse.Content>();
		ConfluenceResponse.Content page = new ConfluenceResponse.Content();
		page.id = '12345678';
		pages.response.results.add(page);

		HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json');
		response.setBody(JSON.serialize(pages));
		response.setStatusCode(200);
		return response;
	}

	private HttpResponse generateAddSpacePermissionsResponse()
	{
		HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json');
		response.setBody('');
		response.setStatusCode(200);
		return response;
	}

	private HttpResponse generateCreateJiraProjectResponse()
	{
		JiraResponse.Project project = new JiraResponse.Project();
		project.id = '12345';
		project.key = 'project_template_key';

		HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json');
		response.setBody(JSON.serialize(project));
		response.setStatusCode(200);
		return response;
	}

	private HttpResponse generateUpdateJiraProjectResponse()
	{
		HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json');
		response.setBody('');
		response.setStatusCode(200);
		return response;
	}

	private HttpResponse generateJiraPermissionsResponse()
	{
		HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json');
		response.setBody('');
		response.setStatusCode(200);
		return response;
	}
}