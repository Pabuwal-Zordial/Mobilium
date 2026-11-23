public with sharing class ProjectController
{
	@AuraEnabled
	public static ProjectUtils.Response initData(Id recordId)
	{
		try
		{
			IntegrationContext context = new IntegrationContext();

			if (context.insufficientRights)
			{
				return new ProjectUtils.Response(true, 'Success', context);
			}

			context.initContext(recordId);

			return new ProjectUtils.Response(true, 'Success', context);
		}
		catch (Exception ex)
		{
			return new ProjectUtils.Response(false, ex.getMessage(), ex.getStackTraceString());
		}
	}

	@AuraEnabled
	public static ProjectUtils.Response submit(Atlassian_Project__c project, IntegrationContext context)
	{
		try
		{
			context.setSteps(project);
			context.projectRecord = project;

			return new ProjectUtils.Response(true, 'Success', context);
		}
		catch (Exception ex)
		{
			return new ProjectUtils.Response(false, ex.getMessage(), ex.getStackTraceString());
		}
	}

	@AuraEnabled
	public static ProjectUtils.Response upsertProjectRecord(Atlassian_Project__c project)
	{
		try
		{
			upsert project;

			project =
			[
				SELECT Id, Proposal_Code__c, Proposal_Code__r.Customer_Acronym__c, Proposal_Code__r.Customer_Acronym__r.Name, Proposal_Code__r.Name,
					Proposal_Code__r.Opportunity__r.Account.Name, Project_Classifications__c, Proposal_Code__r.Customer_Acronym__r.Atlassian_Key__c,
					Project_Director_Name__c, Project_Director_Username__c, Project_Director_Email__c,
					Project_Manager_Name__c, Project_Manager_Username__c, Project_Manager_Email__c, Project_Name__c, Project_Status__c, Name,
					Customer_Eid_Page__c, Customer_Space__c, Eid_Project__c, Eid_Space__c, Published_in_Jira__c, Published_in_Confluence__c
				FROM Atlassian_Project__c
				WHERE Id = :project.Id
			];

			return new ProjectUtils.Response(true, 'Success', project);
		}
		catch (Exception ex)
		{
			return new ProjectUtils.Response(false, ex.getMessage(), ex.getStackTraceString());
		}
	}

	@AuraEnabled
	public static ProjectUtils.Response createCustomerSpace(Atlassian_Project__c project)
	{
		Atlassian_Configs__c atlassianConfigs = Atlassian_Configs__c.getOrgDefaults();

		AtlassianModel.Space spaceModel = new AtlassianModel.Space();
		spaceModel.keyUsers = getKeyUsers(project.Project_Director_Name__c, project.Project_Director_Username__c, project.Project_Manager_Name__c, project.Project_Manager_Username__c);
		spaceModel.key = project.Proposal_Code__r.Customer_Acronym__r.Atlassian_Key__c;
		spaceModel.name = project.Proposal_Code__r.Opportunity__r.Account.Name;
		spaceModel.category = AtlassianConstants.CONFLUENCE_SPACE_CATEGORY_CUSTOMER;

		ProjectUtils.Response response = AtlassianServices.createSpace(spaceModel, project);
		if (!response.isSuccess)
		{
			String body = '<br/><b>Error publishing ' + project.Proposal_Code__r.Name +'</b><br/>';
			body += response.message + '<br/><br/>' + response.value;

			ProjectUtils.sendEmailNotification(atlassianConfigs.Emails_To_Notify__c.split(','), 'Error publishing EID - ' + project.Proposal_Code__r.Name, body);
		}

		return response;
	}

	@AuraEnabled
	public static ProjectUtils.Response createCustomerSpacePages(Atlassian_Project__c project, ConfluenceResponse.Space space)
	{
		Atlassian_Configs__c atlassianConfigs = Atlassian_Configs__c.getOrgDefaults();

		AtlassianModel.Space spaceModel = new AtlassianModel.Space();

		spaceModel.keyUsers = getKeyUsers(project.Project_Director_Name__c, project.Project_Director_Username__c, project.Project_Manager_Name__c, project.Project_Manager_Username__c);
		spaceModel.id = String.valueOf(space.id);
		spaceModel.key = project.Proposal_Code__r.Customer_Acronym__r.Atlassian_Key__c;
		spaceModel.name = project.Proposal_Code__r.Opportunity__r.Account.Name;
		spaceModel.category = AtlassianConstants.CONFLUENCE_SPACE_CATEGORY_CUSTOMER;
		spaceModel.spaceTemplateKey = atlassianConfigs.CustomerSpaceTemplateKey__c;
		spaceModel.spaceTemplateTitle = atlassianConfigs.CustomerSpaceTemplatePageTitle__c;

		String projectManager = spaceModel.keyUsers.containsKey('project-manager') ? spaceModel.keyUsers.get('project-manager').name : '';
		String projectDirector = spaceModel.keyUsers.containsKey('project-director') ? spaceModel.keyUsers.get('project-director').name : '';

		spaceModel.data = new Map<String, String>
		{
			'&lt;CUSTOMER_NAME&gt;' => project.Proposal_Code__r.Opportunity__r.Account.Name.escapeHtml4(),
			'&lt;LONG_EID&gt;' => project.Proposal_Code__r.Name.escapeHtml4(),
			'&lt;PROJECT_CLASSIFICATION&gt;' =>  project.Project_Classifications__c.escapeHtml4(),
			'&lt;PROJECT_NAME&gt;' =>  project.Project_Name__c.escapeHtml4(),
			'&lt;PROJECT_DIRECTOR&gt;' => projectDirector.escapeHtml4(),
			'&lt;PROJECT_MANAGER&gt;' => projectManager.escapeHtml4(),
			'&lt;PROJECT_STATUS&gt;' => project.Project_Status__c.escapeHtml4(),
			'&lt;YYYY-MM-DD&gt;' => Datetime.now().format('yyyy-MM-dd'),
			'&lt;YYYYMMDD&gt;' => Datetime.now().format('yyyy-MM-dd')
		};

		ProjectUtils.Response response = AtlassianServices.createSpacePages(spaceModel, space);
		if (!response.isSuccess)
		{
			String body = '<br/><b>Error publishing ' + project.Proposal_Code__r.Name +'</b><br/>';
			body += response.message + '<br/><br/>' + response.value;

			ProjectUtils.sendEmailNotification(atlassianConfigs.Emails_To_Notify__c.split(','), 'Error publishing EID - ' + project.Proposal_Code__r.Name, body);
		}
		return response;
	}

	@AuraEnabled
	public static ProjectUtils.Response createCustomerEidSpacePage(Atlassian_Project__c project)
	{
		Atlassian_Configs__c atlassianConfigs = Atlassian_Configs__c.getOrgDefaults();

		AtlassianModel.Space spaceModel = new AtlassianModel.Space();

		spaceModel.keyUsers = getKeyUsers(project.Project_Director_Name__c, project.Project_Director_Username__c, project.Project_Manager_Name__c, project.Project_Manager_Username__c);
		spaceModel.key = project.Proposal_Code__r.Customer_Acronym__r.Atlassian_Key__c;
		spaceModel.name = project.Proposal_Code__r.Opportunity__r.Account.Name;
		spaceModel.project = new AtlassianModel.Project();
		spaceModel.project.eid = project.Proposal_Code__r.Name;
		spaceModel.project.acronym = project.Proposal_Code__r.Customer_Acronym__r.Name;
		spaceModel.project.name = project.Project_Name__c;
		spaceModel.category = AtlassianConstants.CONFLUENCE_SPACE_CATEGORY_CUSTOMER;
		spaceModel.spaceTemplateKey = atlassianConfigs.CustomerEidPageSpaceTemplateKey__c;
		spaceModel.spaceTemplateTitle = atlassianConfigs.CustomerEidPageSpaceTemplatePageTitle__c;

		String projectManager = spaceModel.keyUsers.containsKey('project-manager') ? spaceModel.keyUsers.get('project-manager').name : '';
		String projectDirector = spaceModel.keyUsers.containsKey('project-director') ? spaceModel.keyUsers.get('project-director').name : '';

		spaceModel.data = new Map<String, String>
		{
			'&lt;CUSTOMER_NAME&gt;' => project.Proposal_Code__r.Opportunity__r.Account.Name.escapeHtml4(),
			'&lt;LONG_EID&gt;' => project.Proposal_Code__r.Name.escapeHtml4(),
			'&lt;PROJECT_CLASSIFICATION&gt;' =>  project.Project_Classifications__c.escapeHtml4(),
			'&lt;PROJECT_NAME&gt;' =>  project.Project_Name__c.escapeHtml4(),
			'&lt;PROJECT_DIRECTOR&gt;' => projectDirector.escapeHtml4(),
			'&lt;PROJECT_MANAGER&gt;' => projectManager.escapeHtml4(),
			'&lt;PROJECT_STATUS&gt;' => project.Project_Status__c.escapeHtml4(),
			'&lt;YYYY-MM-DD&gt;' => Datetime.now().format('yyyy-MM-dd'),
			'&lt;YYYYMMDD&gt;' => Datetime.now().format('yyyy-MM-dd')
		};

		ProjectUtils.Response response = AtlassianServices.createCustomerEidPage(spaceModel, project);
		if (!response.isSuccess)
		{
			String body = '<br/><b>Error publishing ' + project.Proposal_Code__r.Name +'</b><br/>';
			body += response.message + '<br/><br/>' + response.value;

			ProjectUtils.sendEmailNotification(atlassianConfigs.Emails_To_Notify__c.split(','), 'Error publishing EID - ' + project.Proposal_Code__r.Name, body);
		}
		return response;
	}

	@AuraEnabled
	public static ProjectUtils.Response addCustomerSpacePagesPermissions(Atlassian_Project__c project, Boolean applyPermissionsAllSpace)
	{
		Atlassian_Configs__c atlassianConfigs = Atlassian_Configs__c.getOrgDefaults();

		AtlassianModel.Space spaceModel = new AtlassianModel.Space();

		spaceModel.keyUsers = getKeyUsers(project.Project_Director_Name__c, project.Project_Director_Username__c, project.Project_Manager_Name__c, project.Project_Manager_Username__c);
		spaceModel.key = project.Proposal_Code__r.Customer_Acronym__r.Atlassian_Key__c;
		spaceModel.name = project.Proposal_Code__r.Opportunity__r.Account.Name;
		spaceModel.category = AtlassianConstants.CONFLUENCE_SPACE_CATEGORY_CUSTOMER;

		if (!applyPermissionsAllSpace)
		{
			spaceModel.spacePageRestrictionTitle = project.Proposal_Code__r.Name + ' - ' + project.Project_Name__c;
		}

		ProjectUtils.Response response = AtlassianServices.addSpacePagesPermissions(spaceModel);
		if (!response.isSuccess)
		{
			String body = '<br/><b>Error publishing ' + project.Proposal_Code__r.Name +'</b><br/>';
			body += response.message + '<br/><br/>' + response.value;

			ProjectUtils.sendEmailNotification(atlassianConfigs.Emails_To_Notify__c.split(','), 'Error publishing EID - ' + project.Proposal_Code__r.Name, body);
		}

		return response;
	}

	@AuraEnabled
	public static ProjectUtils.Response createEidSpace(Atlassian_Project__c project)
	{
		Atlassian_Configs__c atlassianConfigs = Atlassian_Configs__c.getOrgDefaults();

		AtlassianModel.Space spaceModel = new AtlassianModel.Space();
		spaceModel.keyUsers = getKeyUsers(project.Project_Director_Name__c, project.Project_Director_Username__c, project.Project_Manager_Name__c, project.Project_Manager_Username__c);
		spaceModel.key = project.Proposal_Code__r.Name.replaceAll('\\.', '');
		spaceModel.name = project.Proposal_Code__r.Name + ' - ' + project.Project_Name__c;
		spaceModel.category = AtlassianConstants.CONFLUENCE_SPACE_CATEGORY_PROJECT;

		ProjectUtils.Response response = AtlassianServices.createSpace(spaceModel, project);
		if (!response.isSuccess)
		{
			String body = '<br/><b>Error publishing ' + project.Proposal_Code__r.Name +'</b><br/>';
			body += response.message + '<br/><br/>' + response.value;

			ProjectUtils.sendEmailNotification(atlassianConfigs.Emails_To_Notify__c.split(','), 'Error publishing EID - ' + project.Proposal_Code__r.Name, body);
		}

		return response;
	}

	@AuraEnabled
	public static ProjectUtils.Response createEidSpacePages(Atlassian_Project__c project, ConfluenceResponse.Space space)
	{
		Atlassian_Configs__c atlassianConfigs = Atlassian_Configs__c.getOrgDefaults();

		AtlassianModel.Space spaceModel = new AtlassianModel.Space();

		spaceModel.keyUsers = getKeyUsers(project.Project_Director_Name__c, project.Project_Director_Username__c, project.Project_Manager_Name__c, project.Project_Manager_Username__c);
		spaceModel.id = String.valueOf(space.id);
		spaceModel.key = project.Proposal_Code__r.Name.replaceAll('\\.', '');
		spaceModel.name = project.Proposal_Code__r.Name + ' - ' + project.Project_Name__c;
		spaceModel.category = AtlassianConstants.CONFLUENCE_SPACE_CATEGORY_PROJECT;
		spaceModel.spaceTemplateKey = atlassianConfigs.EidSpaceTemplateKey__c;
		spaceModel.spaceTemplateTitle = atlassianConfigs.EidSpaceTemplatePageTitle__c;

		String projectManager = spaceModel.keyUsers.containsKey('project-manager') ? spaceModel.keyUsers.get('project-manager').name : '';
		String projectDirector = spaceModel.keyUsers.containsKey('project-director') ? spaceModel.keyUsers.get('project-director').name : '';

		spaceModel.data = new Map<String, String>
		{
			'&lt;CUSTOMER_NAME&gt;' => project.Proposal_Code__r.Opportunity__r.Account.Name.escapeHtml4(),
			'&lt;Customer Name&gt;' => project.Proposal_Code__r.Opportunity__r.Account.Name.escapeHtml4(),
			'&lt;LONG_EID&gt;' => project.Proposal_Code__r.Name.escapeHtml4(),
			'&lt;PROJECT_CLASSIFICATION&gt;' =>  project.Project_Classifications__c.escapeHtml4(),
			'&lt;PROJECT_NAME&gt;' =>  project.Project_Name__c.escapeHtml4(),
			'&lt;Project Name&gt;' =>  project.Project_Name__c.escapeHtml4(),
			'&lt;PROJECT_DIRECTOR&gt;' => projectDirector.escapeHtml4(),
			'&lt; Project Director Name&gt;' => projectDirector.escapeHtml4(),
			'&lt;PROJECT_MANAGER&gt;' => projectManager.escapeHtml4(),
			'&lt;Project Manager Name&gt;' => projectManager.escapeHtml4(),
			'&lt;PROJECT_STATUS&gt;' => project.Project_Status__c.escapeHtml4(),
			'&lt;YYYY-MM-DD&gt;' => Datetime.now().format('yyyy-MM-dd'),
			'&lt;YYYYMMDD&gt;' => Datetime.now().format('yyyy-MM-dd')
		};

		ProjectUtils.Response response = AtlassianServices.createSpacePages(spaceModel, space);
		if (!response.isSuccess)
		{
			String body = '<br/><b>Error publishing ' + project.Proposal_Code__r.Name +'</b><br/>';
			body += response.message + '<br/><br/>' + response.value;

			ProjectUtils.sendEmailNotification(atlassianConfigs.Emails_To_Notify__c.split(','), 'Error publishing EID - ' + project.Proposal_Code__r.Name, body);
		}

		return response;
	}

	@AuraEnabled
	public static ProjectUtils.Response addEidSpacePagesPermissions(Atlassian_Project__c project)
	{
		Atlassian_Configs__c atlassianConfigs = Atlassian_Configs__c.getOrgDefaults();

		AtlassianModel.Space spaceModel = new AtlassianModel.Space();

		spaceModel.keyUsers = getKeyUsers(project.Project_Director_Name__c, project.Project_Director_Username__c, project.Project_Manager_Name__c, project.Project_Manager_Username__c);
		spaceModel.key = project.Proposal_Code__r.Name.replaceAll('\\.', '');
		spaceModel.name = project.Proposal_Code__r.Name + ' - ' + project.Project_Name__c;
		spaceModel.category = AtlassianConstants.CONFLUENCE_SPACE_CATEGORY_PROJECT;
		spaceModel.spacePageRestrictionTitle = AtlassianConstants.CONFLUENCE_PAGE_PERMISSION_TITLE;

		ProjectUtils.Response response = AtlassianServices.addSpacePagesPermissions(spaceModel);
		if (!response.isSuccess)
		{
			String body = '<br/><b>Error publishing ' + project.Proposal_Code__r.Name +'</b><br/>';
			body += response.message + '<br/><br/>' + response.value;

			ProjectUtils.sendEmailNotification(atlassianConfigs.Emails_To_Notify__c.split(','), 'Error publishing EID - ' + project.Proposal_Code__r.Name, body);
		}

		return response;
	}

	@AuraEnabled
	public static ProjectUtils.Response updateCustomerEidPage(Atlassian_Project__c project)
	{
		Atlassian_Configs__c atlassianConfigs = Atlassian_Configs__c.getOrgDefaults();

		AtlassianModel.Space spaceModel = new AtlassianModel.Space();

		spaceModel.keyUsers = getKeyUsers(project.Project_Director_Name__c, project.Project_Director_Username__c, project.Project_Manager_Name__c, project.Project_Manager_Username__c);
		spaceModel.key = project.Proposal_Code__r.Customer_Acronym__r.Atlassian_Key__c;
		spaceModel.name = project.Proposal_Code__r.Opportunity__r.Account.Name;
		spaceModel.project = new AtlassianModel.Project();
		spaceModel.project.eid = project.Proposal_Code__r.Name;
		spaceModel.project.acronym = project.Proposal_Code__r.Customer_Acronym__r.Name;
		spaceModel.project.name = project.Project_Name__c;
		spaceModel.spaceTemplateKey = atlassianConfigs.CustomerEidPageSpaceTemplateKey__c;
		spaceModel.spaceTemplateTitle = atlassianConfigs.CustomerEidPageSpaceTemplatePageTitle__c;

		String projectManager = spaceModel.keyUsers.containsKey('project-manager') ? spaceModel.keyUsers.get('project-manager').name : '';
		String projectDirector = spaceModel.keyUsers.containsKey('project-director') ? spaceModel.keyUsers.get('project-director').name : '';

		spaceModel.data = new Map<String, String>
		{
			'&lt;CUSTOMER_NAME&gt;' => project.Proposal_Code__r.Opportunity__r.Account.Name.escapeHtml4(),
			'&lt;LONG_EID&gt;' => project.Proposal_Code__r.Name.escapeHtml4(),
			'&lt;PROJECT_CLASSIFICATION&gt;' =>  project.Project_Classifications__c.escapeHtml4(),
			'&lt;PROJECT_NAME&gt;' =>  project.Project_Name__c.escapeHtml4(),
			'&lt;PROJECT_DIRECTOR&gt;' => projectDirector.escapeHtml4(),
			'&lt;PROJECT_MANAGER&gt;' => projectManager.escapeHtml4(),
			'&lt;PROJECT_STATUS&gt;' => project.Project_Status__c.escapeHtml4(),
			'&lt;YYYY-MM-DD&gt;' => Datetime.now().format('yyyy-MM-dd'),
			'&lt;YYYYMMDD&gt;' => Datetime.now().format('yyyy-MM-dd')
		};

		ProjectUtils.Response response = AtlassianServices.updateCustomerEidPage(spaceModel, project);
		if (!response.isSuccess)
		{
			String body = '<br/><b>Error update ' + project.Proposal_Code__r.Name +'</b><br/>';
			body += response.message + '<br/><br/>' + response.value;

			ProjectUtils.sendEmailNotification(atlassianConfigs.Emails_To_Notify__c.split(','), 'Error update EID - ' + project.Proposal_Code__r.Name, body);
		}
		return response;
	}

	@AuraEnabled
	public static ProjectUtils.Response updateCustomerSpacePagesPermissions(IntegrationContext context)
	{
		Atlassian_Configs__c atlassianConfigs = Atlassian_Configs__c.getOrgDefaults();
		Atlassian_Project__c project = context.projectRecord;

		Map<String, Map<String, AtlassianModel.User>> usersToChange = context.getUsersToChange();

		AtlassianModel.Space spaceModelToAdd = new AtlassianModel.Space();
		Map<String, AtlassianModel.User> usersToInclude = usersToChange.get('usersToInclude');
		if (usersToInclude <> null)
		{
			spaceModelToAdd.keyUsers = usersToInclude;
			spaceModelToAdd.key = project.Proposal_Code__r.Customer_Acronym__r.Name;
			spaceModelToAdd.category = AtlassianConstants.CONFLUENCE_SPACE_CATEGORY_CUSTOMER;
			spaceModelToAdd.spacePageRestrictionTitle = project.Proposal_Code__r.Name + ' - ' + project.Project_Name__c;
		}

		AtlassianModel.Space spaceModelToRemove = new AtlassianModel.Space();
		Map<String, AtlassianModel.User> usersToExclude = usersToChange.get('usersToExclude');
		if (usersToExclude <> null)
		{
			spaceModelToRemove.keyUsers = usersToExclude;
			spaceModelToRemove.key = project.Proposal_Code__r.Customer_Acronym__r.Name;
			spaceModelToRemove.category = AtlassianConstants.CONFLUENCE_SPACE_CATEGORY_CUSTOMER;
			spaceModelToRemove.spacePageRestrictionTitle = project.Proposal_Code__r.Name + ' - ' + project.Project_Name__c;
		}

		System.debug('usersToChange: ' + usersToChange);

		ProjectUtils.Response response = AtlassianServices.updateSpacePermissions(spaceModelToAdd, null);
		if (!response.isSuccess)
		{
			String body = '<br/><b>Error updating customer space permissions: ' + project.Proposal_Code__r.Name +'</b><br/>';
			body += response.message + '<br/><br/>' + response.value;

			ProjectUtils.sendEmailNotification(atlassianConfigs.Emails_To_Notify__c.split(','), 'Error updating customer space permissions - ' + project.Proposal_Code__r.Name, body);
			return response;
		}

		response = AtlassianServices.updateSpacePagesPermissions(spaceModelToAdd, spaceModelToRemove);
		if (!response.isSuccess)
		{
			String body = '<br/><b>Error updating customer pages permissions: ' + project.Proposal_Code__r.Name +'</b><br/>';
			body += response.message + '<br/><br/>' + response.value;

			ProjectUtils.sendEmailNotification(atlassianConfigs.Emails_To_Notify__c.split(','), 'Error updating customer pages permissions - ' + project.Proposal_Code__r.Name, body);
		}

		return response;
	}

	@AuraEnabled
	public static ProjectUtils.Response updateEidSpacePermissions(IntegrationContext context)
	{
		Atlassian_Configs__c atlassianConfigs = Atlassian_Configs__c.getOrgDefaults();
		Atlassian_Project__c project = context.projectRecord;

		Map<String, Map<String, AtlassianModel.User>> usersToChange = context.getUsersToChange();

		AtlassianModel.Space spaceModelToAdd = new AtlassianModel.Space();
		Map<String, AtlassianModel.User> usersToInclude = usersToChange.get('usersToInclude');
		if (usersToInclude <> null)
		{
			spaceModelToAdd.keyUsers = usersToInclude;
			spaceModelToAdd.key = project.Proposal_Code__r.Name.replaceAll('\\.', '');
			spaceModelToAdd.category = AtlassianConstants.CONFLUENCE_SPACE_CATEGORY_PROJECT;
		}

		AtlassianModel.Space spaceModelToRemove = new AtlassianModel.Space();
		Map<String, AtlassianModel.User> usersToExclude = usersToChange.get('usersToExclude');
		if (usersToExclude <> null)
		{
			spaceModelToRemove.keyUsers = usersToExclude;
			spaceModelToRemove.key = project.Proposal_Code__r.Name.replaceAll('\\.', '');
			spaceModelToRemove.category = AtlassianConstants.CONFLUENCE_SPACE_CATEGORY_PROJECT;
		}

		ProjectUtils.Response response = AtlassianServices.updateSpacePermissions(spaceModelToAdd, spaceModelToRemove);
		if (!response.isSuccess)
		{
			String body = '<br/><b>Error updating eid space permissions: ' + project.Proposal_Code__r.Name +'</b><br/>';
			body += response.message + '<br/><br/>' + response.value;

			ProjectUtils.sendEmailNotification(atlassianConfigs.Emails_To_Notify__c.split(','), 'Error updating eid space permissions - ' + project.Proposal_Code__r.Name, body);
		}

		return response;
	}

	private static void handleKeyUsersChanges(AtlassianModel.User newUser, AtlassianModel.User oldUser, String type, Map<String, AtlassianModel.User> usersToAdd, Map<String, AtlassianModel.User> usersToRemove, Set<String> usernamesToKeep)
	{
		if (newUser <> null && oldUser <> null && newUser.username <> oldUser.username)
		{
			usersToAdd.put(type, newUser);
			usersToRemove.put(type, oldUser);
		}
		else if (newUser <> null && oldUser <> null && newUser.username == oldUser.username)
		{
			usernamesToKeep.add(newUser.username);
		}
		else if (newUser <> null && oldUser == null)
		{
			usersToAdd.put(type, newUser);
		}
		else if (newUser == null && oldUser <> null)
		{
			usersToRemove.put(type, oldUser);
		}
	}

	@AuraEnabled
	public static ProjectUtils.Response createJiraProject(Atlassian_Project__c project)
	{
		Atlassian_Configs__c atlassianConfigs = Atlassian_Configs__c.getOrgDefaults();

		AtlassianModel.Project projectModel = new AtlassianModel.Project();

		projectModel.keyUsers = getKeyUsers(project.Project_Director_Name__c, project.Project_Director_Username__c, project.Project_Manager_Name__c, project.Project_Manager_Username__c);
		projectModel.acronym = project.Proposal_Code__r.Customer_Acronym__r.Name;
		projectModel.eid = 'M' + project.Proposal_Code__r.Name.replaceAll('\\.', '');
		projectModel.name = project.Proposal_Code__r.Name + ' - ' + project.Project_Name__c;
		projectModel.projectTemplateName = atlassianConfigs.ProjectTemplateKey__c;

		ProjectUtils.Response response = AtlassianServices.createEidProject(projectModel, project);
		if (!response.isSuccess)
		{
			String body = '<br/><b>Error publishing ' + project.Proposal_Code__r.Name +'</b><br/>';
			body += response.message + '<br/><br/>' + response.value;

			ProjectUtils.sendEmailNotification(atlassianConfigs.Emails_To_Notify__c.split(','), 'Error publishing EID - ' + project.Proposal_Code__r.Name, body);
		}

		return response;
	}

	@AuraEnabled
	public static ProjectUtils.Response updateJiraProject(Atlassian_Project__c project, JiraResponse.Project jiraProject, JiraResponse.Project templateProject)
	{
		Atlassian_Configs__c atlassianConfigs = Atlassian_Configs__c.getOrgDefaults();

		AtlassianModel.Project projectModel = new AtlassianModel.Project();

		projectModel.keyUsers = getKeyUsers(project.Project_Director_Name__c, project.Project_Director_Username__c, project.Project_Manager_Name__c, project.Project_Manager_Username__c);
		projectModel.acronym = project.Proposal_Code__r.Customer_Acronym__r.Name;
		projectModel.eid = 'M' + project.Proposal_Code__r.Name.replaceAll('\\.', '');
		projectModel.name = project.Proposal_Code__r.Name + ' - ' + project.Project_Name__c;
		projectModel.projectTemplateName = atlassianConfigs.ProjectTemplateKey__c;

		if (String.isNotBlank(project.Project_Director_Username__c) && String.isNotBlank(project.Project_Manager_Username__c))
		{
			ProjectUtils.Response permissonsResponse = AtlassianServices.addEidProjectPermissions(projectModel, jiraProject);
			if (!permissonsResponse.isSuccess)
			{
				String body = '<br/><b>Error publishing ' + project.Proposal_Code__r.Name +'</b><br/>';
				body += permissonsResponse.message + '<br/><br/>' + permissonsResponse.value;

				ProjectUtils.sendEmailNotification(atlassianConfigs.Emails_To_Notify__c.split(','), 'Error publishing EID - ' + project.Proposal_Code__r.Name, body);

				return permissonsResponse;
			}
		}


		if (templateProject.components != null && !templateProject.components.isEmpty())
		{
			ProjectUtils.Response componentsResponse = AtlassianServices.addTemplateComponentsToEidProject(projectModel, templateProject);
			if (!componentsResponse.isSuccess)
			{
				String body = '<br/><b>Error publishing ' + project.Proposal_Code__r.Name +'</b><br/>';
				body += componentsResponse.message + '<br/><br/>' + componentsResponse.value;

				ProjectUtils.sendEmailNotification(atlassianConfigs.Emails_To_Notify__c.split(','), 'Error publishing EID - ' + project.Proposal_Code__r.Name, body);

				return componentsResponse;
			}
		}

		return new ProjectUtils.Response(true, 'Jira project settings updated.', null);
	}

	@AuraEnabled
	public static ProjectUtils.Response updatePublishedJiraProject(IntegrationContext context)
	{
		Atlassian_Project__c project = context.projectRecord;
		Atlassian_Project__c oldProject = context.oldProjectRecord;
		String projectKey = 'M' + project.Proposal_Code__r.Name.replaceAll('\\.', '');

		Map<String, AtlassianModel.User> newKeyUsers = getKeyUsers(project.Project_Director_Name__c, project.Project_Director_Username__c, project.Project_Manager_Name__c, project.Project_Manager_Username__c);
		Map<String, AtlassianModel.User> oldKeyUsers = getKeyUsers(oldProject.Project_Director_Name__c, oldProject.Project_Director_Username__c, oldProject.Project_Manager_Name__c, oldProject.Project_Manager_Username__c);

		AtlassianModel.Project projectModel = new AtlassianModel.Project();
		projectModel.keyUsers = newKeyUsers;
		projectModel.eid = projectKey;

		ProjectUtils.Response projectUpdateResponse = AtlassianServices.updateEidProject(projectModel);
		if (!projectUpdateResponse.isSuccess)
		{
			return new ProjectUtils.Response(false, 'Error updating project.', projectUpdateResponse.message + '\n' + projectUpdateResponse.value);
		}

		AtlassianModel.User newProjectDirector = newKeyUsers.get('project-director');
		AtlassianModel.User oldProjectDirector = oldKeyUsers.get('project-director');
		AtlassianModel.User newProjectManager = newKeyUsers.get('project-manager');
		AtlassianModel.User oldProjectManager = oldKeyUsers.get('project-manager');

		Map<String, AtlassianModel.User> usersToInclude = new Map<String, AtlassianModel.User>();
		Map<String, AtlassianModel.User> usersToExclude = new Map<String, AtlassianModel.User>();
		Set<String> admins = new Set<String>();
		if (newProjectDirector <> null && oldProjectDirector <> null && newProjectDirector.username == oldProjectDirector.username)
		{
			admins.add(newProjectDirector.username);
		}

		if (newProjectManager <> null && oldProjectManager <> null && oldProjectManager.username == oldProjectManager.username)
		{
			admins.add(newProjectManager.username);
		}

		if (newProjectDirector <> null && (oldProjectDirector == null || newProjectDirector.username <> oldProjectDirector.username))
		{
			usersToInclude.put('project-director', newProjectDirector);
			if (oldProjectDirector <> null)
			{
				usersToExclude.put('project-director', oldProjectDirector);
			}
		}
		else if (newProjectDirector == null && oldProjectDirector <> null)
		{
			usersToExclude.put('project-director', oldProjectDirector);
		}

		if (newProjectManager <> null && (oldProjectManager == null || newProjectManager.username <> oldProjectManager.username))
		{
			usersToInclude.put('project-manager', newProjectManager);
			if (oldProjectManager <> null)
			{
				usersToExclude.put('project-manager', oldProjectManager);
			}
		}
		else if (newProjectManager == null && oldProjectManager <> null)
		{
			usersToExclude.put('project-manager', oldProjectManager);
		}

		if (!usersToInclude.isEmpty() || !usersToExclude.isEmpty())
		{
			AtlassianModel.Project modelToAdd = new AtlassianModel.Project();
			modelToAdd.eid = projectKey;
			modelToAdd.keyUsers = usersToInclude;
			AtlassianModel.Project modelToRemove = new AtlassianModel.Project();
			modelToRemove.eid = projectKey;
			modelToRemove.keyUsers = usersToExclude;

			projectUpdateResponse = AtlassianServices.updateEidProjectPermissions(modelToAdd, modelToRemove, admins);
			if (!projectUpdateResponse.isSuccess)
			{
				return new ProjectUtils.Response(false, 'Error updating project.', projectUpdateResponse.message + '\n' + projectUpdateResponse.value);
			}
		}

		return new ProjectUtils.Response(true, 'Success', 'success');
	}

	@AuraEnabled
	public static ProjectUtils.Response notifyUsers(IntegrationContext context, Boolean isNew)
	{
		try {
			Atlassian_Configs__c atlassianConfigs = Atlassian_Configs__c.getOrgDefaults();
			Atlassian_Project__c project =
			[
				SELECT Id, Proposal_Code__r.Name, Customer_Space__c, Customer_Eid_Page__c, Eid_Space__c, Eid_Project__c,
					Project_Director_Email__c, Project_Manager_Email__c, Project_Status__c
				FROM Atlassian_Project__c
				WHERE Id = :context.projectRecord.Id
			];

			String subject = isNew ? 'EID published' : 'EID updated';

			String body = 'Hi team,<br/><br/>' + subject + ' - ' + project.Proposal_Code__r.Name +  '.<br/><br/>';
			body += '<b>Customer Space: </b>';
			body += '<a href="' + project.Customer_Space__c + '">' + project.Customer_Space__c + '</a>';
			body += '<br/><br/><b>Customer EID Page: </b>';
			body += '<a href="' + project.Customer_Eid_Page__c + '">' + project.Customer_Eid_Page__c + '</a>';

			if (project.Project_Status__c == 'Backlog')
			{
				body += '<br/><br/><b>EID Space: </b>';
				body += '<a href="' + project.Eid_Space__c + '">' + project.Eid_Space__c + '</a>';
				body += '<br/><br/><b>EID Project: </b>';
				body += '<a href="' + project.Eid_Project__c + '">' + project.Eid_Project__c + '</a>';
			}

			Set<String> toAddresses = new Set<String>(atlassianConfigs.Emails_To_Notify__c.split(','));
			if (String.isNotBlank(project.Project_Director_Email__c))
			{
				toAddresses.add(project.Project_Director_Email__c);
			}

			if (String.isNotBlank(project.Project_Manager_Email__c))
			{
				toAddresses.add(project.Project_Manager_Email__c);
			}

			ProjectUtils.sendEmailNotification(new List<String>(toAddresses), subject, body);

			return new ProjectUtils.Response(true, 'An email was sent to key users.', 'An email was sent to key users.');
		}
		catch (Exception ex)
		{
			return new ProjectUtils.Response(false, 'Error notifying users. Please contact your System Administrator', ex.getMessage());
		}
	}

	private static Map<String, AtlassianModel.User> getKeyUsers(String projectDirectorName, String projectDirectorUsername, String projectManagerName, String projectManagerUsername)
	{
		if (String.isBlank(projectDirectorUsername) || String.isBlank(projectDirectorUsername) || String.isBlank(projectManagerName) || String.isBlank(projectManagerUsername))
		{
			return new Map<String, AtlassianModel.User>();
		}

		AtlassianModel.User projectDirector = new AtlassianModel.User();
		projectDirector.name = projectDirectorName;
		projectDirector.username = projectDirectorUsername;

		AtlassianModel.User projectManager = new AtlassianModel.User();
		projectManager.name = projectManagerName;
		projectManager.username = projectManagerUsername;

		return new Map<String, AtlassianModel.User> { 'project-director' => projectDirector, 'project-manager' => projectManager };
	}

	public class IntegrationContext
	{
		@AuraEnabled public Boolean insufficientRights { get; set; }
		@AuraEnabled public String accountName { get; set; }
		@AuraEnabled public String eid { get; set; }
		@AuraEnabled public String acronym { get; set; }
		@AuraEnabled public String projectName { get; set; }
		@AuraEnabled public List<String> steps { get; set; }
		@AuraEnabled public Atlassian_Project__c projectRecord { get; set; }
		@AuraEnabled public Atlassian_Project__c oldProjectRecord { get; set; }

		public IntegrationContext()
		{
			List<PermissionSetAssignment> permissionSetAssignments =
			[
				SELECT Id
				FROM PermissionSetAssignment
				WHERE PermissionSet.Name = 'Proposal_Code_Full' AND AssigneeId = :UserInfo.getUserId()
			];

			this.insufficientRights = permissionSetAssignments.isEmpty();
		}

		public void initContext(Id proposalCodeId)
		{
			Proposal_Code__c projectCode =
			[
				SELECT Id, Customer_Acronym__c, Customer_Acronym__r.Name, Customer_Acronym__r.Atlassian_Key__c, Name,
					Opportunity__r.Account.Name, Opportunity__r.Name,
					(
						SELECT Id, Proposal_Code__c, Proposal_Code__r.Customer_Acronym__c, Proposal_Code__r.Customer_Acronym__r.Name, Proposal_Code__r.Name,
						Proposal_Code__r.Opportunity__r.Account.Name, Project_Classifications__c, Proposal_Code__r.Customer_Acronym__r.Atlassian_Key__c,
						Project_Director_Name__c, Project_Director_Username__c, Project_Manager_Name__c, Project_Manager_Username__c, Project_Name__c, Project_Status__c, Name,
						Customer_Eid_Page__c, Customer_Space__c, Eid_Project__c, Eid_Space__c, Published_in_Jira__c, Published_in_Confluence__c
						FROM Atlassian_Projects__r)
				FROM Proposal_Code__c
				WHERE Id = :proposalCodeId
			];

			this.accountName = projectCode.Opportunity__r.Account.Name;
			this.acronym = projectCode.Customer_Acronym__r.Name;
			this.projectName = projectCode.Opportunity__r.Name;
			this.eid = projectCode.Name;

			if (!projectCode.Atlassian_Projects__r.isEmpty())
			{
				this.projectRecord = projectCode.Atlassian_Projects__r[0];
			}
			else
			{
				this.projectRecord = new Atlassian_Project__c
				(
					Proposal_Code__c = proposalCodeId
				);
			}

			this.oldProjectRecord = this.projectRecord;
		}

		public void setSteps(Atlassian_Project__c newProjectRecord)
		{
			this.steps = new List<String>();
			this.steps.add('serverUpsertRecord');

			if (!this.projectRecord.Published_in_Confluence__c)
			{
				this.steps.add('serverCreateCustomerSpace');
				this.steps.add('serverCreateCustomerSpacePages');
				this.steps.add('serverCreateCustomerEidPage');
				this.steps.add('serverAddCustomerSpacePagesPermissions');
				this.steps.add('serverCreateEidSpace');
				this.steps.add('serverCreateEidSpacePages');
				this.steps.add('serverAddEidSpacePagesPermissions');
			}
			else
			{
				this.steps.add('serverUpdateCustomerEidPage');
				if (newProjectRecord.Project_Director_Username__c <> this.oldProjectRecord.Project_Director_Username__c || newProjectRecord.Project_Manager_Username__c <>  this.oldProjectRecord.Project_Manager_Username__c)
				{
					this.steps.add('serverUpdateCustomerSpacePagesPermissions');
					this.steps.add('serverUpdateEidSpacePermissions');
				}
			}

			if (!this.projectRecord.Published_in_Jira__c && newProjectRecord.Project_Status__c == 'Backlog')
			{
				this.steps.add('serverCreateJiraProject');
				this.steps.add('serverUpdateJiraProject');
			}
			else if (this.projectRecord.Published_in_Jira__c && newProjectRecord.Project_Status__c == 'Backlog')
			{
				if (newProjectRecord.Project_Director_Username__c <> this.oldProjectRecord.Project_Director_Username__c || newProjectRecord.Project_Manager_Username__c <>  this.oldProjectRecord.Project_Manager_Username__c)
				{
					this.steps.add('serverUpdatePublishedJiraProject');
				}
			}

			if (!this.projectRecord.Published_in_Confluence__c)
			{
				this.steps.add('serverNotifyNew');
			}
			else
			{
				this.steps.add('serverNotifyUpdate');
			}
		}

		public Map<String, Map<String, AtlassianModel.User>> getUsersToChange()
		{
			Set<String> usersToInclude = new Set<String>();
			Set<String> usersToExclude = new Set<String>();
			Set<String> usersToKeep = new Set<String>();

			this.compareUsers(this.projectRecord.Project_Director_Username__c, this.oldProjectRecord.Project_Director_Username__c, usersToInclude, usersToExclude, usersToKeep);
			this.compareUsers(this.projectRecord.Project_Manager_Username__c, this.oldProjectRecord.Project_Manager_Username__c, usersToInclude, usersToExclude, usersToKeep);

			for (String userToKeep : usersToKeep)
			{
				usersToExclude.remove(userToKeep);
			}

			Map<String, Map<String, AtlassianModel.User>> result = new Map<String, Map<String, AtlassianModel.User>>
			{
				'usersToInclude' => new Map<String, AtlassianModel.User>(),
				'usersToExclude' => new Map<String, AtlassianModel.User>()
			};

			for (String userToInclude : usersToInclude)
			{
				AtlassianModel.User newUser = new AtlassianModel.User();
				String userRole;
				if (userToInclude == this.projectRecord.Project_Director_Username__c)
				{
					newUser.name = this.projectRecord.Project_Director_Name__c;
					newUser.username = this.projectRecord.Project_Director_Username__c;
					userRole = 'project-director';
				}
				else
				{
					newUser.name = this.projectRecord.Project_Manager_Name__c;
					newUser.username = this.projectRecord.Project_Manager_Username__c;
					userRole = 'project-manager';
				}

				Map<String, AtlassianModel.User> usersMap = result.get('usersToInclude');
				if (usersMap == null)
				{
					usersMap = new Map<String, AtlassianModel.User>();
					result.put('usersToInclude', usersMap);
				}
				usersMap.put(userRole, newUser);
			}

			for (String userToExclude : usersToExclude)
			{
				AtlassianModel.User newUser = new AtlassianModel.User();
				String userRole;
				if (userToExclude == this.oldProjectRecord.Project_Director_Username__c)
				{
					newUser.name = this.oldProjectRecord.Project_Director_Name__c;
					newUser.username = this.projectRecord.Project_Director_Username__c;
					userRole = 'project-director';
				}
				else
				{
					newUser.name = this.oldProjectRecord.Project_Manager_Name__c;
					newUser.username = this.oldProjectRecord.Project_Manager_Username__c;
					userRole = 'project-manager';
				}

				Map<String, AtlassianModel.User> usersMap = result.get('usersToExclude');
				if (usersMap == null)
				{
					usersMap = new Map<String, AtlassianModel.User>();
					result.put('usersToExclude', usersMap);
				}
				usersMap.put(userRole, newUser);
			}

			return result;
		}

		private void compareUsers(String newUsername, String oldUsername, Set<String> usersToInclude, Set<String> usersToExclude, Set<String> usersToKeep)
		{
			if (newUsername <> null && newUsername == oldUsername)
			{
				usersToKeep.add(newUsername);
			}
			else if (newUsername <> null && oldUsername <> null && newUsername <> oldUsername)
			{
				usersToInclude.add(newUsername);
				usersToExclude.add(oldUsername);
			}
			else if (newUsername <> null && oldUsername == null)
			{
				usersToInclude.add(newUsername);
			}
			else if (newUsername == null && oldUsername <> null)
			{
				usersToExclude.add(oldUsername);
			}
		}
	}

	public class ProjectControllerException extends Exception {}
}