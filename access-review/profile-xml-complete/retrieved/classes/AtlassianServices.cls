public with sharing class AtlassianServices
{
	public static ProjectUtils.Response createSpace(AtlassianModel.Space spaceModel, Atlassian_Project__c projectRecord)
	{
		try
		{
			ProjectUtils.Response spaceResponse = ConfluenceServices.getSpace(spaceModel.key);
			if (!spaceResponse.isSuccess && spaceResponse.message <> '404')
			{
				return spaceResponse;
			}
			else if (spaceResponse.isSuccess)
			{
				ConfluenceResponse.Space space = ConfluenceResponse.getSpaceObject(String.valueOf(spaceResponse.value));

				if (spaceModel.category == AtlassianConstants.CONFLUENCE_SPACE_CATEGORY_CUSTOMER)
				{
					projectRecord.Customer_Space__c = space.links.get('base') + space.links.get('webui');
				}
				else
				{
					projectRecord.Eid_Space__c = space.links.get('base') + space.links.get('webui');
				}

				update projectRecord;

				return new ProjectUtils.Response(true, spaceModel.category + ': Space already exists.', new Map<String, Object> { 'record' => projectRecord, 'space' => space });
			}
			else
			{
				ConfluenceRequest.Space spaceRequest = new ConfluenceRequest.Space();
				spaceRequest.key = spaceModel.key;
				spaceRequest.name = spaceModel.name;

				spaceResponse = ConfluenceServices.createSpace(spaceRequest);
				if (!spaceResponse.isSuccess)
				{
					return new ProjectUtils.Response(false, spaceModel.category + ': Error creating space.', spaceResponse.message + '\n' + spaceResponse.value);
				}

				List<Atlassian_Space_Permission__mdt> defaultPermissions =
				[
					SELECT Entity_Name__c, VIEWSPACE__c, EXPORTSPACE__c, SETSPACEPERMISSIONS__c, SETPAGEPERMISSIONS__c, REMOVEPAGE__c, REMOVEOWNCONTENT__c,
						EDITSPACE__c, REMOVEBLOG__c, EDITBLOG__c, REMOVEMAIL__c, REMOVECOMMENT__c, COMMENT__c, REMOVEATTACHMENT__c, CREATEATTACHMENT__c
					FROM Atlassian_Space_Permission__mdt
					WHERE Space__c = :spaceModel.category
					ORDER BY Entity_Name__c
				];

				for (Atlassian_Space_Permission__mdt defaultPermission : defaultPermissions)
				{
					if (AtlassianConstants.KEY_USERS_NAME.contains(defaultPermission.Entity_Name__c) && spaceModel.keyUsers.isEmpty())
					{
						continue;
					}

					ConfluenceRequest.SpacePermission spacePermission = new ConfluenceRequest.SpacePermission();
					spacePermission.spaceKey = spaceModel.key;
					spacePermission.permissions = new List<String>();
					for (String spacePermissionValue : AtlassianConstants.SPACE_PERMISSIONS)
					{
						if (Boolean.valueOf(defaultPermission.get(spacePermissionValue + '__c')))
						{
							spacePermission.permissions.add(spacePermissionValue);
						}
					}
					spacePermission.userOrGroup = spaceModel.keyUsers.containsKey(defaultPermission.Entity_Name__c) ? spaceModel.keyUsers.get(defaultPermission.Entity_Name__c).username : defaultPermission.Entity_Name__c;

					ProjectUtils.Response spacePermissionResponse = ConfluenceServices.addSpacePermissions(spacePermission);
					if (!spacePermissionResponse.isSuccess)
					{
						return new ProjectUtils.Response(false, spaceModel.category + ': Error while assigning space permissions.', spacePermissionResponse.message + '\n' + spacePermissionResponse.value);
					}
				}

				ProjectUtils.Response spaceCategoryResponse = ConfluenceServices.addSpaceCategory(spaceModel.key, spaceModel.category);
				if (!spaceCategoryResponse.isSuccess)
				{
					return new ProjectUtils.Response(false, spaceModel.category + ': Error while assigning space category.', spaceCategoryResponse.message + '\n' + spaceCategoryResponse.value);
				}

				ConfluenceResponse.Space space = ConfluenceResponse.getSpaceObject(String.valueOf(spaceResponse.value));

				if (spaceModel.category == AtlassianConstants.CONFLUENCE_SPACE_CATEGORY_CUSTOMER)
				{
					projectRecord.Customer_Space__c = space.links.get('base') + space.links.get('webui');
				}
				else
				{
					projectRecord.Eid_Space__c = space.links.get('base') + space.links.get('webui');
					projectRecord.Published_in_Confluence__c = true;
				}

				update projectRecord;

				return new ProjectUtils.Response(true, spaceModel.category + ': space created.', new Map<String, Object> { 'record' => projectRecord, 'space' => space });
			}
		}
		catch (Exception ex)
		{
			return new ProjectUtils.Response(false, ex.getMessage(), ex.getStackTraceString());
		}
	}

	public static ProjectUtils.Response createSpacePages(AtlassianModel.Space model, ConfluenceResponse.Space space)
	{
		try
		{
			ProjectUtils.Response spaceTemplateResponse = ConfluenceServices.getPagesByTitle(model.spaceTemplateTitle, model.spaceTemplateKey);
			if (!spaceTemplateResponse.isSuccess)
			{
				return new ProjectUtils.Response(false, model.category + ': Error getting space template.', spaceTemplateResponse.message + '\n' + spaceTemplateResponse.value);
			}

			ConfluenceResponse.ContentArray contentArray = ConfluenceResponse.getContentArrayObject(String.valueOf(spaceTemplateResponse.value));
			ConfluenceResponse.Content homepageTemplate = contentArray.results[0];

			ConfluenceRequest.SpacePage homepageRequest = new ConfluenceRequest.SpacePage();
			homepageRequest.id = space.homepage.id;
			homepageRequest.version = new Map<String, Integer> { 'number' => 2 };
			homepageRequest.title = space.homepage.title;
			homepageRequest.type = space.homepage.type;
			homepageRequest.space = new ConfluenceRequest.Space();
			homepageRequest.space.key = model.key;
			homepageRequest.body = new ConfluenceRequest.SpacePageBody();
			homepageRequest.body.storage = new ConfluenceRequest.SpacePageStorage();
			homepageRequest.body.storage.value = ProjectUtils.replaceBodyVariables(homepageTemplate.body.storage.value, model.data);

			ProjectUtils.Response spaceHomepageResponse = ConfluenceServices.updatePage(homepageRequest);
			if (!spaceHomepageResponse.isSuccess)
			{
				return new ProjectUtils.Response(false, model.category + ': Error updating space homepage.', spaceTemplateResponse.message + '\n' + spaceTemplateResponse.value);
			}

			Map<String, String> mapParentPages = new Map<String, String> { homepageTemplate.id => space.homepage.id };
			List<String> pageTemplateIds = new List<String> { homepageTemplate.id };
			while (!pageTemplateIds.isEmpty())
			{
				String pageId = pageTemplateIds.remove(0);

				ProjectUtils.Response childPagesTemplateResponse = ConfluenceServices.getPagesByParentId(pageId);
				if (!childPagesTemplateResponse.isSuccess)
				{
					return new ProjectUtils.Response(false, model.category + ': Error getting sub-pages template.', childPagesTemplateResponse.message + '\n' + childPagesTemplateResponse.value);
				}

				ConfluenceResponse.ContentArray subPagesTemplate = ConfluenceResponse.getContentArrayObject(String.valueOf(childPagesTemplateResponse.value));
				for (ConfluenceResponse.Content subPageTemplate : subPagesTemplate.results)
				{
					ConfluenceRequest.SpacePage subPageRequest = new ConfluenceRequest.SpacePage();
					subPageRequest.title = subPageTemplate.title;
					subPageRequest.extensions = new ConfluenceRequest.SpacePageExtensions();
					subPageRequest.extensions.position = subPageTemplate.extensions.position;
					subPageRequest.space = new ConfluenceRequest.Space();
					subPageRequest.space.key = model.key;
					subPageRequest.body = new ConfluenceRequest.SpacePageBody();
					subPageRequest.body.storage = new ConfluenceRequest.SpacePageStorage();
					subPageRequest.body.storage.value = ProjectUtils.replaceBodyVariables(subPageTemplate.body.storage.value, model.data);
					subPageRequest.ancestors = new List<ConfluenceRequest.SpacePage>();
					ConfluenceRequest.SpacePage ancestor = new ConfluenceRequest.SpacePage();
					ancestor.id = mapParentPages.get(pageId);
					subPageRequest.ancestors.add(ancestor);

					ProjectUtils.Response subPageResponse = ConfluenceServices.createPage(subPageRequest);
					if (!subPageResponse.isSuccess)
					{
						return new ProjectUtils.Response(false, model.category + ': Error creating sub-pages template.', subPageResponse.message + '\n' + subPageResponse.value);
					}

					ConfluenceResponse.Content subPage = ConfluenceResponse.getContentObject(String.valueOf(subPageResponse.value));
					mapParentPages.put(subPageTemplate.id, subPage.id);
					pageTemplateIds.add(subPageTemplate.id);
				}
			}

			return new ProjectUtils.Response(true, model.category + ': space pages created.', mapParentPages.values());
		}
		catch (Exception ex)
		{
			return new ProjectUtils.Response(false, ex.getMessage(), ex.getStackTraceString());
		}
	}

	public static ProjectUtils.Response addSpacePagesPermissions(AtlassianModel.Space model)
	{
		try
		{
			List<String> pageIds = new List<String>();

			if (String.isNotBlank(model.spacePageRestrictionTitle))
			{
				ProjectUtils.Response restrictedPageResponse = ConfluenceServices.getPagesByTitle(model.spacePageRestrictionTitle, model.key);
				if (!restrictedPageResponse.isSuccess)
				{
					return new ProjectUtils.Response(false, model.category + ': Error getting retricted pages to assign permissions.', restrictedPageResponse.message + '\n' + restrictedPageResponse.value);
				}

				ConfluenceResponse.ContentArray contentArray = ConfluenceResponse.getContentArrayObject(String.valueOf(restrictedPageResponse.value));
				ConfluenceResponse.Content retrictedPage = contentArray.results[0];

				if (model.spacePageRestrictionTitle == AtlassianConstants.CONFLUENCE_PAGE_PERMISSION_TITLE)
				{
					pageIds.add(retrictedPage.id);
				}
				else
				{
					List<String> parentIds = new List<String> { retrictedPage.id };
					while (!parentIds.isEmpty())
					{
						String pageId = parentIds.remove(0);
						pageIds.add(pageId);

						ProjectUtils.Response childPagesResponse = ConfluenceServices.getPagesByParentId(pageId);
						if (!childPagesResponse.isSuccess)
						{
							return new ProjectUtils.Response(false, model.category + ': Error getting sub-pages off restricted page.', childPagesResponse.message + '\n' + childPagesResponse.value);
						}

						ConfluenceResponse.ContentArray subPages = ConfluenceResponse.getContentArrayObject(String.valueOf(childPagesResponse.value));
						for (ConfluenceResponse.Content subPage : subPages.results)
						{
							pageIds.add(subPage.id);
						}
					}
				}
			}
			else
			{
				ProjectUtils.Response spacePagesResponse = ConfluenceServices.getAllSpacePages(model.key);
				if (!spacePagesResponse.isSuccess)
				{
					return new ProjectUtils.Response(false, model.category + ': Error getting space pages to assign permissions.', spacePagesResponse.message + '\n' + spacePagesResponse.value);
				}

				ConfluenceResponse.SpacePages pages = ConfluenceResponse.getSpacePagesObject(String.valueOf(spacePagesResponse.value));
				for (ConfluenceResponse.Content content : pages.response.results)
				{
					pageIds.add(content.id);
				}
			}

			List<Atlassian_Page_Permission__mdt> defaultPermissions =
			[
				SELECT Entity_Name__c, Entity_Type__c, Read__c, Update__c
				FROM Atlassian_Page_Permission__mdt
				WHERE Space__c = :model.category
				ORDER BY Entity_Name__c
			];

			for (String pageId : pageIds)
			{
				for (Atlassian_Page_Permission__mdt defaultPermission : defaultPermissions)
				{
					if (AtlassianConstants.KEY_USERS_NAME.contains(defaultPermission.Entity_Name__c) && model.keyUsers.isEmpty())
					{
						continue;
					}

					for (String pagePermissionValue : AtlassianConstants.PAGE_PERMISSIONS)
					{
						if (Boolean.valueOf(defaultPermission.get(pagePermissionValue + '__c')))
						{
							ConfluenceRequest.SpacePagePermission pagePermissionRequest = new ConfluenceRequest.SpacePagePermission();
							pagePermissionRequest.pageId = pageId;
							pagePermissionRequest.permission = pagePermissionValue;
							pagePermissionRequest.type = defaultPermission.Entity_Type__c;
							pagePermissionRequest.userOrGroup = model.keyUsers.containsKey(defaultPermission.Entity_Name__c) ? model.keyUsers.get(defaultPermission.Entity_Name__c).username : defaultPermission.Entity_Name__c;

							ProjectUtils.Response pagePermissionResponse = ConfluenceServices.addSpacePagePermission(pagePermissionRequest);
							if (!pagePermissionResponse.isSuccess)
							{
								return new ProjectUtils.Response(false, model.category + ': Error adding pages permission.', pagePermissionResponse.message + '\n' + pagePermissionResponse.value);
							}
						}
					}
				}
			}

			return new ProjectUtils.Response(true, model.category + ': Pages permission added successfully.', null);
		}
		catch (Exception ex)
		{
			return new ProjectUtils.Response(false, ex.getMessage(), ex.getStackTraceString());
		}
	}

	public static ProjectUtils.Response updateSpacePermissions(AtlassianModel.Space modelToAdd, AtlassianModel.Space modelToRemove)
	{
		try
		{
			List<Atlassian_Space_Permission__mdt> defaultPermissions =
			[
				SELECT Entity_Name__c, VIEWSPACE__c, EXPORTSPACE__c, SETSPACEPERMISSIONS__c, SETPAGEPERMISSIONS__c, REMOVEPAGE__c, REMOVEOWNCONTENT__c,
					EDITSPACE__c, REMOVEBLOG__c, EDITBLOG__c, REMOVEMAIL__c, REMOVECOMMENT__c, COMMENT__c, REMOVEATTACHMENT__c, CREATEATTACHMENT__c
				FROM Atlassian_Space_Permission__mdt
				WHERE Space__c = :modelToAdd.category AND Entity_Name__c IN :AtlassianConstants.KEY_USERS_NAME
				ORDER BY Entity_Name__c
			];

			Map<String, Atlassian_Space_Permission__mdt> permissionsByEntity = new Map<String, Atlassian_Space_Permission__mdt>();
			for (Atlassian_Space_Permission__mdt defaultPermission : defaultPermissions)
			{
				permissionsByEntity.put(defaultPermission.Entity_Name__c, defaultPermission);
			}

			if (modelToAdd.keyUsers <> null && !modelToAdd.keyUsers.isEmpty())
			{
				for (String keyUserRole : modelToAdd.keyUsers.keySet())
				{
					AtlassianModel.User user = modelToAdd.keyUsers.get(keyUserRole);

					ConfluenceRequest.SpacePermission spacePermission = new ConfluenceRequest.SpacePermission();
					spacePermission.spaceKey = modelToAdd.key;
					spacePermission.permissions = getSpacePermissions(permissionsByEntity.get(keyUserRole));
					spacePermission.userOrGroup = user.username;

					ProjectUtils.Response spacePermissionResponse = ConfluenceServices.addSpacePermissions(spacePermission);
					if (!spacePermissionResponse.isSuccess)
					{
						return new ProjectUtils.Response(false, modelToAdd.category + ': Error while assigning space permissions.', spacePermissionResponse.message + '\n' + spacePermissionResponse.value);
					}
				}
			}

			if (modelToRemove <> null && modelToRemove.keyUsers <> null && !modelToRemove.keyUsers.isEmpty())
			{
				for (String keyUserRole : modelToAdd.keyUsers.keySet())
				{
					AtlassianModel.User user = modelToAdd.keyUsers.get(keyUserRole);

					ConfluenceRequest.SpacePermission spacePermission = new ConfluenceRequest.SpacePermission();
					spacePermission.spaceKey = modelToAdd.key;
					spacePermission.permissions = getSpacePermissions(permissionsByEntity.get(keyUserRole));
					spacePermission.userOrGroup = user.username;

					ProjectUtils.Response spacePermissionResponse = ConfluenceServices.removeSpacePermission(spacePermission);
					if (!spacePermissionResponse.isSuccess)
					{
						return new ProjectUtils.Response(false, modelToRemove.category + ': Error while removing space permissions.', spacePermissionResponse.message + '\n' + spacePermissionResponse.value);
					}
				}
			}

			return new ProjectUtils.Response(true, modelToAdd.category + ': Success updating space permissions.', null);
		}
		catch (Exception ex)
		{
			return new ProjectUtils.Response(false, ex.getMessage(), ex.getStackTraceString());
		}
	}

	private static List<String> getSpacePermissions(Atlassian_Space_Permission__mdt permission)
	{
		List<String> result = new List<String>();
		for (String spacePermissionValue : AtlassianConstants.SPACE_PERMISSIONS)
		{
			if (Boolean.valueOf(permission.get(spacePermissionValue + '__c')))
			{
				result.add(spacePermissionValue);
			}
		}

		return result;
	}

	public static ProjectUtils.Response updateSpacePagesPermissions(AtlassianModel.Space modelToAdd, AtlassianModel.Space modelToRemove)
	{
		try
		{
			List<String> pageIds = new List<String>();

			if (String.isNotBlank(modelToAdd.spacePageRestrictionTitle))
			{
				ProjectUtils.Response restrictedPageResponse = ConfluenceServices.getPagesByTitle(modelToAdd.spacePageRestrictionTitle, modelToAdd.key);
				if (!restrictedPageResponse.isSuccess)
				{
					return new ProjectUtils.Response(false, modelToAdd.category + ': Error getting retricted pages to update permissions.', restrictedPageResponse.message + '\n' + restrictedPageResponse.value);
				}

				ConfluenceResponse.ContentArray contentArray = ConfluenceResponse.getContentArrayObject(String.valueOf(restrictedPageResponse.value));
				ConfluenceResponse.Content retrictedPage = contentArray.results[0];

				if (modelToAdd.spacePageRestrictionTitle == AtlassianConstants.CONFLUENCE_PAGE_PERMISSION_TITLE)
				{
					pageIds.add(retrictedPage.id);
				}
				else
				{
					List<String> parentIds = new List<String> { retrictedPage.id };
					while (!parentIds.isEmpty())
					{
						String pageId = parentIds.remove(0);
						pageIds.add(pageId);

						ProjectUtils.Response childPagesResponse = ConfluenceServices.getPagesByParentId(pageId);
						if (!childPagesResponse.isSuccess)
						{
							return new ProjectUtils.Response(false, modelToAdd.category + ': Error getting sub-pages off restricted page.', childPagesResponse.message + '\n' + childPagesResponse.value);
						}

						ConfluenceResponse.ContentArray subPages = ConfluenceResponse.getContentArrayObject(String.valueOf(childPagesResponse.value));
						for (ConfluenceResponse.Content subPage : subPages.results)
						{
							pageIds.add(subPage.id);
						}
					}
				}
			}
			else
			{
				ProjectUtils.Response spacePagesResponse = ConfluenceServices.getAllSpacePages(modelToAdd.key);
				if (!spacePagesResponse.isSuccess)
				{
					return new ProjectUtils.Response(false, modelToAdd.category + ': Error getting space pages to update permissions.', spacePagesResponse.message + '\n' + spacePagesResponse.value);
				}

				ConfluenceResponse.SpacePages pages = ConfluenceResponse.getSpacePagesObject(String.valueOf(spacePagesResponse.value));
				for (ConfluenceResponse.Content content : pages.response.results)
				{
					pageIds.add(content.id);
				}
			}

			List<Atlassian_Page_Permission__mdt> defaultPermissions =
			[
				SELECT Entity_Name__c, Entity_Type__c, Read__c, Update__c
				FROM Atlassian_Page_Permission__mdt
				WHERE Space__c = :modelToAdd.category AND Entity_Name__c IN :AtlassianConstants.KEY_USERS_NAME
				ORDER BY Entity_Name__c
			];

			Map<String, Atlassian_Page_Permission__mdt> mapPermissions = new Map<String, Atlassian_Page_Permission__mdt>();
			for (Atlassian_Page_Permission__mdt defaultPermission : defaultPermissions)
			{
				mapPermissions.put(defaultPermission.Entity_Name__c, defaultPermission);
			}

			for (String pageId : pageIds)
			{
				for (String entityName : mapPermissions.keySet())
				{
					Atlassian_Page_Permission__mdt defaultPermission = mapPermissions.get(entityName);
					if (defaultPermission == null)
					{
						continue;
					}

					AtlassianModel.User userToExclude = modelToRemove.keyUsers <> null ? modelToRemove.keyUsers.get(entityName) : null;
					if (userToExclude <> null)
					{
						ConfluenceRequest.SpacePagePermission pagePermissionRequest = new ConfluenceRequest.SpacePagePermission();
						pagePermissionRequest.pageId = pageId;
						pagePermissionRequest.type = defaultPermission.Entity_Type__c;
						pagePermissionRequest.userOrGroup = userToExclude.username;

						if (defaultPermission.Update__c)
						{
							pagePermissionRequest.permission = 'update';
						}
						else if (defaultPermission.Read__c)
						{
							pagePermissionRequest.permission = 'read';
						}

						if (pagePermissionRequest.permission <> null)
						{
							ProjectUtils.Response pagePermissionResponse = ConfluenceServices.removeSpacePagePermission(pagePermissionRequest);
							if (!pagePermissionResponse.isSuccess)
							{
								return new ProjectUtils.Response(false, modelToAdd.category + ': Error removing pages permission.', pagePermissionResponse.message + '\n' + pagePermissionResponse.value);
							}
						}
					}

					AtlassianModel.User userToInclude = modelToAdd.keyUsers <> null ? modelToAdd.keyUsers.get(entityName) : null;
					if (userToInclude <> null)
					{
						ConfluenceRequest.SpacePagePermission pagePermissionRequest = new ConfluenceRequest.SpacePagePermission();
						pagePermissionRequest.pageId = pageId;
						pagePermissionRequest.type = defaultPermission.Entity_Type__c;
						pagePermissionRequest.userOrGroup = userToInclude.username;

						if (defaultPermission.Update__c)
						{
							pagePermissionRequest.permission = 'update';
						}
						else if (defaultPermission.Read__c)
						{
							pagePermissionRequest.permission = 'read';
						}

						if (pagePermissionRequest.permission <> null)
						{
							ProjectUtils.Response pagePermissionResponse = ConfluenceServices.addSpacePagePermission(pagePermissionRequest);
							if (!pagePermissionResponse.isSuccess)
							{
								return new ProjectUtils.Response(false, modelToAdd.category + ': Error removing pages permission.', pagePermissionResponse.message + '\n' + pagePermissionResponse.value);
							}
						}
					}
				}
			}

			return new ProjectUtils.Response(true, modelToAdd.category + ': Pages permission updated successfully.', null);
		}
		catch (Exception ex)
		{
			return new ProjectUtils.Response(false, ex.getMessage(), ex.getStackTraceString());
		}
	}

	public static ProjectUtils.Response createCustomerEidPage(AtlassianModel.Space model, Atlassian_Project__c projectRecord)
	{
		try
		{
			ProjectUtils.Response psoPageResponse = ConfluenceServices.getPagesByTitle(AtlassianConstants.CONFLUENCE_PSO_PAGE_TITLE, model.key);
			if (!psoPageResponse.isSuccess)
			{
				return new ProjectUtils.Response(false, model.category + ': Error adding pages permission.', psoPageResponse.message + '\n' + psoPageResponse.value);
			}

			ProjectUtils.Response eidPageTemplateResponse = ConfluenceServices.getPagesByTitle(model.spaceTemplateTitle, model.spaceTemplateKey);
			if (!eidPageTemplateResponse.isSuccess)
			{
				return new ProjectUtils.Response(false, model.category + ': Error getting customer eid page template.', eidPageTemplateResponse.message + '\n' + eidPageTemplateResponse.value);
			}

			ConfluenceResponse.ContentArray contentArray = ConfluenceResponse.getContentArrayObject(String.valueOf(psoPageResponse.value));
			ConfluenceResponse.Content psoPage = contentArray.results[0];

			contentArray = ConfluenceResponse.getContentArrayObject(String.valueOf(eidPageTemplateResponse.value));
			ConfluenceResponse.Content eidPageTemplate = contentArray.results[0];

			ConfluenceRequest.SpacePage eidPageRequest = new ConfluenceRequest.SpacePage();
			eidPageRequest.title = model.project.eid + ' - ' + model.project.name;
			eidPageRequest.space = new ConfluenceRequest.Space();
			eidPageRequest.space.key = model.key;
			eidPageRequest.ancestors = new List<ConfluenceRequest.SpacePage>();
			ConfluenceRequest.SpacePage ancestor = new ConfluenceRequest.SpacePage();
			ancestor.id = psoPage.id;
			eidPageRequest.ancestors.add(ancestor);
			eidPageRequest.extensions = new ConfluenceRequest.SpacePageExtensions();
			eidPageRequest.extensions.position = 'none';
			eidPageRequest.body = new ConfluenceRequest.SpacePageBody();
			eidPageRequest.body.storage = new ConfluenceRequest.SpacePageStorage();
			eidPageRequest.body.storage.value = ProjectUtils.replaceBodyVariables(eidPageTemplate.body.storage.value, model.data);

			ProjectUtils.Response eidPageResponse = ConfluenceServices.createPage(eidPageRequest);
			if (!eidPageResponse.isSuccess)
			{
				return new ProjectUtils.Response(false, model.category + ': Error creating customer eid page.', eidPageResponse.message + '\n' + eidPageResponse.value);
			}

			ConfluenceResponse.Content eidPage =ConfluenceResponse.getContentObject(String.valueOf(eidPageResponse.value));
			projectRecord.Customer_Eid_Page__c = eidPage.links.get('base') + eidPage.links.get('webui');
			update projectRecord;

			return new ProjectUtils.Response(true, 'Customer eid page created.', null);
		}
		catch (Exception ex)
		{
			return new ProjectUtils.Response(false, ex.getMessage(), ex.getStackTraceString());
		}
	}

	public static ProjectUtils.Response updateCustomerEidPage(AtlassianModel.Space model, Atlassian_Project__c projectRecord)
	{
		try
		{
			String pageTitle = model.project.eid + ' - ' + model.project.name;
			ProjectUtils.Response eidPageResponse = ConfluenceServices.getPagesByTitle(pageTitle, model.key);
			if (!eidPageResponse.isSuccess)
			{
				return new ProjectUtils.Response(false, 'Error getting customer eid page.', eidPageResponse.message + '\n' + eidPageResponse.value);
			}

			ProjectUtils.Response eidPageTemplateResponse = ConfluenceServices.getPagesByTitle(model.spaceTemplateTitle, model.spaceTemplateKey);
			if (!eidPageTemplateResponse.isSuccess)
			{
				return new ProjectUtils.Response(false, model.category + ': Error getting customer eid page template.', eidPageTemplateResponse.message + '\n' + eidPageTemplateResponse.value);
			}

			ConfluenceResponse.ContentArray contentArray = ConfluenceResponse.getContentArrayObject(String.valueOf(eidPageResponse.value));
			ConfluenceResponse.Content eidPage = contentArray.results[0];

			contentArray = ConfluenceResponse.getContentArrayObject(String.valueOf(eidPageTemplateResponse.value));
			ConfluenceResponse.Content eidPageTemplate = contentArray.results[0];

			ConfluenceRequest.SpacePage eidPageRequest = new ConfluenceRequest.SpacePage();
			eidPageRequest.space = new ConfluenceRequest.Space();
			eidPageRequest.space.key = model.key;
			eidPageRequest.id = eidPage.id;
			eidPageRequest.title = pageTitle;
			eidPageRequest.version = new Map<String, Integer> { 'number' => eidPage.version.versionNumber + 1 };
			eidPageRequest.body = new ConfluenceRequest.SpacePageBody();
			eidPageRequest.body.storage = new ConfluenceRequest.SpacePageStorage();
			eidPageRequest.body.storage.value = ProjectUtils.replaceBodyVariables(eidPageTemplate.body.storage.value, model.data);

			ProjectUtils.Response eidRequestPageResponse = ConfluenceServices.updatePage(eidPageRequest);
			if (!eidRequestPageResponse.isSuccess)
			{
				return new ProjectUtils.Response(false, model.category + ': Error creating customer eid page.', eidRequestPageResponse.message + '\n' + eidRequestPageResponse.value);
			}

			return new ProjectUtils.Response(true, 'Customer eid page updated.', null);
		}
		catch (Exception ex)
		{
			System.debug(ex.getLineNumber());
			return new ProjectUtils.Response(false, ex.getMessage(), ex.getStackTraceString());
		}
	}

	public static ProjectUtils.Response createEidProject(AtlassianModel.Project model, Atlassian_Project__c projectRecord)
	{
		try
		{
			ProjectUtils.Response projectTemplateResponse = JiraServices.getProject(model.projectTemplateName);
			if (!projectTemplateResponse.isSuccess)
			{
				return new ProjectUtils.Response(false, 'Error getting project template.', projectTemplateResponse.message + '\n' + projectTemplateResponse.value);
			}

			JiraResponse.Project projectTemplate = JiraResponse.getProjectObject(String.valueOf(projectTemplateResponse.value));

			JiraRequest.Project project = new JiraRequest.Project();
			project.key = model.eid.replace('.', '').toUpperCase();
			project.name = model.name;
			if (model.keyUsers.containsKey('project-director'))
			{
				project.lead = model.keyUsers.get('project-director').username;
			}

			ProjectUtils.Response projectResponse = JiraServices.createProjectWithTemplate(projectTemplate.id, project);
			if (!projectResponse.isSuccess)
			{
				return new ProjectUtils.Response(false, 'Error creating project.', projectResponse.message + '\n' + projectResponse.value);
			}

			project.assigneeType = AtlassianConstants.JIRA_ASSIGNEE_TYPE;
			project.avatarId = AtlassianConstants.JIRA_AVATAR_ID;
			project.categoryId = AtlassianConstants.JIRA_CATEGORY_ID;
			project.description = model.eid;
			project.issueSecurityScheme = AtlassianConstants.JIRA_ISSUE_SECURITY_SCHEME;
			project.notificationScheme = AtlassianConstants.JIRA_NOTIFICATION_SCHEME;
			project.permissionScheme =AtlassianConstants.JIRA_PERMISSION_SCHEME;
			project.projectTemplateKey = AtlassianConstants.JIRA_PROJECT_TEMPLATE_KEY;
			project.projectTypeKey = AtlassianConstants.JIRA_PROJECT_TYPE_KEY;

			ProjectUtils.Response projectUpdateResponse = JiraServices.updateProject(project);
			if (!projectUpdateResponse.isSuccess)
			{
				return new ProjectUtils.Response(false, 'Error updating project.', projectResponse.message + '\n' + projectResponse.value);
			}

			JiraResponse.Project jiraProject = JiraResponse.getProjectObject(String.valueOf(projectUpdateResponse.value));

			Map<String, JiraResponse.Project> jiraProjects = new Map<String, JiraResponse.Project>
			{
				'template' => projectTemplate, 'project' => jiraProject
			};

			projectRecord.Eid_Project__c = 'https://wdtjira.wedotechnologies.com/projects/' + jiraProject.key +  '/summary';
			projectRecord.Published_in_Jira__c = true;
			update projectRecord;

			return new ProjectUtils.Response(true, 'Jira project created successfully.', jiraProjects);
		}
		catch (Exception ex)
		{
			return new ProjectUtils.Response(false, ex.getMessage(), ex.getStackTraceString());
		}
	}

	public static ProjectUtils.Response updateEidProject(AtlassianModel.Project model)
	{
		try
		{
			JiraRequest.Project project = new JiraRequest.Project();
			project.key = model.eid;
			project.name = model.name;
			if (model.keyUsers.containsKey('project-director'))
			{
				project.lead = model.keyUsers.get('project-director').username;
			}

			ProjectUtils.Response projectResponse = JiraServices.updateProject(project);
			if (!projectResponse.isSuccess)
			{
				return new ProjectUtils.Response(false, 'Error creating project.', projectResponse.message + '\n' + projectResponse.value);
			}

			return new ProjectUtils.Response(true, 'Success', 'success');
		}
		catch (Exception ex)
		{
			return new ProjectUtils.Response(false, ex.getMessage(), ex.getStackTraceString());
		}
	}

	public static ProjectUtils.Response addEidProjectPermissions(AtlassianModel.Project model,  JiraResponse.Project jiraProject)
	{
		try
		{
			JiraRequest.ProjectPermission adminPermission = new JiraRequest.ProjectPermission();
			adminPermission.projectKey = jiraProject.key;
			adminPermission.role = AtlassianConstants.JIRA_ADMIN_ROLE;
			adminPermission.usersOrGroups = new List<String> { model.keyUsers.get('project-manager').username, model.keyUsers.get('project-director').username };

			ProjectUtils.Response adminPermissionResponse = JiraServices.addProjectPermission(adminPermission);
			if (!adminPermissionResponse.isSuccess)
			{
				return new ProjectUtils.Response(false, 'Error adding project admin permissions.', adminPermissionResponse.message + '\n' + adminPermissionResponse.value);
			}

			JiraRequest.ProjectPermission managerPermission = new JiraRequest.ProjectPermission();
			managerPermission.projectKey = jiraProject.key;
			managerPermission.role = AtlassianConstants.JIRA_MANAGER_ROLE;
			managerPermission.usersOrGroups = new List<String> { model.keyUsers.get('project-manager').username };

			ProjectUtils.Response managerPermissionResponse = JiraServices.addProjectPermission(managerPermission);
			if (!managerPermissionResponse.isSuccess)
			{
				return new ProjectUtils.Response(false, 'Error adding project manager permissions.', managerPermissionResponse.message + '\n' + managerPermissionResponse.value);
			}

			return new ProjectUtils.Response(true, 'Project permissions added successfully.', null);
		}
		catch (Exception ex)
		{
			return new ProjectUtils.Response(false, ex.getMessage(), ex.getStackTraceString());
		}
	}

	public static ProjectUtils.Response updateEidProjectPermissions(AtlassianModel.Project modelToAdd, AtlassianModel.Project modelToRemove, Set<String> admins)
	{
		try
		{
			if (modelToRemove.keyUsers <> null && !modelToRemove.keyUsers.isEmpty())
			{
				System.debug('modelToRemove.keyUsers: ' + modelToRemove.keyUsers);

				JiraRequest.ProjectPermission adminPermission = new JiraRequest.ProjectPermission();
				adminPermission.projectKey = modelToAdd.eid;
				adminPermission.role = AtlassianConstants.JIRA_ADMIN_ROLE;
				adminPermission.usersOrGroups = new List<String>();
				AtlassianModel.User projectManager = modelToRemove.keyUsers.get('project-manager');
				AtlassianModel.User projectDirector = modelToRemove.keyUsers.get('project-director');

				if (projectManager <> null && !admins.contains(projectManager.username))
				{
					adminPermission.usersOrGroups.add(projectManager.username);
				}

				if (projectDirector <> null && !admins.contains(projectDirector.username))
				{
					adminPermission.usersOrGroups.add(projectDirector.username);
				}

				for (String username : adminPermission.usersOrGroups)
				{
					ProjectUtils.Response adminPermissionResponse = JiraServices.deleteProjectPermission(adminPermission.projectKey, adminPermission.role, username);
					if (!adminPermissionResponse.isSuccess)
					{
						return new ProjectUtils.Response(false, 'Error removing project admin permissions.', adminPermissionResponse.message + '\n' + adminPermissionResponse.value);
					}
				}

				JiraRequest.ProjectPermission managerPermission = new JiraRequest.ProjectPermission();
				managerPermission.projectKey = modelToAdd.eid;
				managerPermission.role = AtlassianConstants.JIRA_MANAGER_ROLE;

				if (projectManager <> null)
				{
					ProjectUtils.Response managerPermissionResponse = JiraServices.deleteProjectPermission(managerPermission.projectKey, managerPermission.role, projectManager.username);
					if (!managerPermissionResponse.isSuccess)
					{
						return new ProjectUtils.Response(false, 'Error removing project manager permissions.', managerPermissionResponse.message + '\n' + managerPermissionResponse.value);
					}
				}
			}

			if (modelToAdd.keyUsers <> null && !modelToAdd.keyUsers.isEmpty())
			{
				JiraRequest.ProjectPermission adminPermission = new JiraRequest.ProjectPermission();
				adminPermission.projectKey = modelToAdd.eid;
				adminPermission.role = AtlassianConstants.JIRA_ADMIN_ROLE;
				adminPermission.usersOrGroups = new List<String>();
				AtlassianModel.User projectManager = modelToAdd.keyUsers.get('project-manager');
				AtlassianModel.User projectDirector = modelToAdd.keyUsers.get('project-director');

				if (projectManager <> null && !admins.contains(projectManager.username))
				{
					adminPermission.usersOrGroups.add(projectManager.username);
				}

				if (projectDirector <> null && !admins.contains(projectDirector.username))
				{
					adminPermission.usersOrGroups.add(projectDirector.username);
				}

				if (!adminPermission.usersOrGroups.isEmpty())
				{
					ProjectUtils.Response adminPermissionResponse = JiraServices.addProjectPermission(adminPermission);
					if (!adminPermissionResponse.isSuccess)
					{
						return new ProjectUtils.Response(false, 'Error updating project admin permissions.', adminPermissionResponse.message + '\n' + adminPermissionResponse.value);
					}
				}

				JiraRequest.ProjectPermission managerPermission = new JiraRequest.ProjectPermission();
				managerPermission.projectKey = modelToAdd.eid;
				managerPermission.role = AtlassianConstants.JIRA_MANAGER_ROLE;
				managerPermission.usersOrGroups = new List<String>();

				if (projectManager <> null)
				{
					managerPermission.usersOrGroups.add(projectManager.username);
					ProjectUtils.Response managerPermissionResponse = JiraServices.addProjectPermission(managerPermission);
					if (!managerPermissionResponse.isSuccess)
					{
						return new ProjectUtils.Response(false, 'Error updating project manager permissions.', managerPermissionResponse.message + '\n' + managerPermissionResponse.value);
					}
				}
			}

			return new ProjectUtils.Response(true, 'Project permissions updated successfully.', null);
		}
		catch (Exception ex)
		{
			return new ProjectUtils.Response(false, ex.getMessage(), ex.getStackTraceString());
		}
	}

	public static ProjectUtils.Response addTemplateComponentsToEidProject(AtlassianModel.Project model, JiraResponse.Project templateProject)
	{
		try
		{
			for (JiraResponse.Component component : templateProject.components)
			{
				JiraRequest.ProjectComponent projectComponent = new JiraRequest.ProjectComponent();
				projectComponent.assigneeType = component.assigneeType;
				projectComponent.lead = component.lead;
				projectComponent.project = component.project;
				projectComponent.projectId = component.projectId;

				ProjectUtils.Response componentResponse = JiraServices.addProjectComponent(projectComponent);
				if (!componentResponse.isSuccess)
				{
					return new ProjectUtils.Response(false, 'Error adding project components.', componentResponse.message + '\n' + componentResponse.value);
				}
			}

			return new ProjectUtils.Response(true, 'Project components added successfully.', null);
		}
		catch (Exception ex)
		{
			return new ProjectUtils.Response(false, ex.getMessage(), ex.getStackTraceString());
		}
	}
}