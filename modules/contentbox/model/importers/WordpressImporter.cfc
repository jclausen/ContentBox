﻿/**
********************************************************************************
ContentBox - A Modular Content Platform
Copyright 2012 by Luis Majano and Ortus Solutions, Corp
www.gocontentbox.org | www.luismajano.com | www.ortussolutions.com
********************************************************************************
Apache License, Version 2.0

Copyright Since [2012] [Luis Majano and Ortus Solutions,Corp] 

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License. 
You may obtain a copy of the License at 

http://www.apache.org/licenses/LICENSE-2.0 

Unless required by applicable law or agreed to in writing, software 
distributed under the License is distributed on an "AS IS" BASIS, 
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
See the License for the specific language governing permissions and 
limitations under the License.
********************************************************************************
* Import a WordPress database into contentbox
*/
component implements="contentbox.model.importers.ICBImporter"{

	// DI
	property name="categoryService"		inject="id:categoryService@cb";
	property name="entryService"		inject="id:entryService@cb";
	property name="pageService"			inject="id:pageService@cb";
	property name="authorService"		inject="id:authorService@cb";
	property name="roleService"			inject="id:roleService@cb";
	property name="commentService"		inject="id:commentService@cb";
	property name="customFieldService" 	inject="id:customFieldService@cb";
	property name="log"					inject="logbox:logger:{this}";
	property name="htmlHelper"			inject="coldbox:plugin:HTMLHelper";


	/**
	* Constructor
	*/
	WordPressImporter function init(){
		return this;
	}

	/**
	* Import from WordPress blog, returns the string console.
	*/
	function execute(required dsn,dsnUsername="",dsnPassword="",defaultPassword="",required roleID,tableprefix=""){
		var authorMap 	= {};
		var catMap 		= {};
		var entryMap 	= {};
		var pageMap		= {};
		var slugMap 	= {};
		var pageSlugMap = {};

		log.info("Starting import process: #arguments.toString()#");

		try{

			/************************************** CATEGORIES *********************************************/

			var q = new Query(datasource=arguments.dsn,username=arguments.dsnUsername,
						      password=arguments.dsnPassword,
						      sql="select * from #arguments.tableprefix#_terms a, #arguments.tableprefix#_term_taxonomy b where a.term_id = b.term_id AND b.taxonomy = 'category'").execute().getResult();
			for(var x=1; x lte q.recordcount; x++){
				var props 	= {category=q.name[x], slug=q.slug[x]};
				var cat 	= categoryService.new(properties=props);
				var exists = categoryService.findAllBySlug( q.slug[ x ] );
				
				if( arrayLen( exists ) ){
					cat = exists[ 1 ];
				}else{
					entitySave( cat );
				}

				log.info("Imported category: #props.category#");
				catMap[ q.term_id[x] ] = cat.getCategoryID();
			}
			log.info("Categories imported successfully!");

			/************************************** AUTHORS *********************************************/

			log.info("Starting to import Authors....");
			// Get the default role
			var defaultRole = roleService.get( arguments.roleID );
			// Import Authors
			var q = new Query(datasource=arguments.dsn,username=arguments.dsnUsername,
								password=arguments.dsnPassword,sql="select * from #arguments.tableprefix#_users").execute().getResult();
			var selectedRole = roleService.get(arguments.roleID);
			for(var x=1; x lte q.recordcount; x++){
				var props = {email=q.user_email[x], username=q.user_login[x], password=hash(defaultPassword, authorService.getHashType() ),isActive=1,role=selectedRole,
						     firstName=listFirst(q.display_name[x]," "), lastName=trim(replacenocase(q.display_name[x], listFirst(q.display_name[x]," "), "" ))};
				var author = authorService.new(properties=props);
				author.setRole( defaultRole );
				
				// duplicate usernames
				var exists = authorService.findAllByUsername( props.username );
				if( arrayLen( exists ) ){
					author = exists[ 1 ];
				}
				entitySave( author );
				log.info("Imported author: #props.firstName# #props.lastName#");
				authorMap[ q.id[x] ] = author.getAuthorID();
			}
			log.info("Authors imported successfully!");

			/************************************** PAGES *********************************************/
			log.info("Starting to import Pages....");
			// Import Pages
			var qPages = new Query(datasource=arguments.dsn,username=arguments.dsnUsername,
						     password=arguments.dsnPassword,
						     sql="select id,post_title AS title,post_name AS name,post_content AS content,post_status,comment_status,post_password,post_date AS last_modified,post_author AS author_id from #arguments.tableprefix#_posts where post_type='page'").execute().getResult();
			for(var x=1; x lte qPages.recordcount;x++){
				// Get properties
				var published = true;
				var commentStatus = true;
				if( trim(qPages.post_status[x]) neq "publish" ){ published = false; }
				if( qPages.comment_status[x] neq "open" ){ commentSatus = false; }

				var props = {title=qPages.title[x], slug=qPages.name[x], content=fixWordPressContent(qPages.content[x]), excerpt="", publishedDate=qPages.last_modified[x],
							 createdDate=qPages.last_modified[x], isPublished=published, allowComments=commentStatus, layout="pages"};

				var moreLoc = findnocase("<!--more-->", props.content);
				if( moreLoc ){
					props.excerpt = left(props.content,moreLoc-1);
				}

				// slug checks
				if( !len(Trim(props.slug)) ){
					props.slug = htmlHelper.slugify(props.title);
				}
				// check if slug already in map
				if( structKeyExists(pageSlugMap, props.slug) ){
					// unique it
					props.slug &= "-" & left(hash(now()),5);
				}
				pageSlugMap[ props.slug ] = "found";

				var page = pageService.new(properties=props);
				// Add content versionized!
				page.addNewContentVersion(content=props.content,changelog="Imported content",author=authorService.get( authorMap[qPages.author_id[x]] ));
				// Add Creator
				page.setCreator( authorService.get( authorMap[ qPages.author_id[ x ] ] ) );
				// Save page and store in reference map
				pageMap[ qPages.id[x] ] = page;
				var c = pageService.newCriteria();
				var counter=1;
				var count = new query(sql="SELECT COUNT(*) AS ct FROM cb_content WHERE contentType = 'page' AND slug = '#page.getSlug()#';").execute().getResult()['ct'];
				do{
					var count = new query(sql="SELECT COUNT(*) AS ct FROM cb_content WHERE contentType = 'page' AND slug = '#page.getSlug()#';").execute().getResult()['ct'];
					if(count eq 0){break;}
					// verify no slug exists & append if it does
					counter++;
					page.setSlug(props.slug & '-' & counter);
				}while( count );

				log.info("Starting to import Page Comments....");
				// Import page comments
				var qComments = new Query(datasource=arguments.dsn,username=arguments.dsnUsername,
											password=arguments.dsnPassword,
											sql="select * from #arguments.tableprefix#_comments 
												WHERE comment_post_ID = '#q.id[x]#'
												  AND comment_approved <> 'spam'").execute().getResult();
				var aComments = [];
				for(var y=1; y lte qComments.recordcount; y++){
					var props = {
						content = qComments.comment_content[y], author = qComments.comment_author[y], authorIP = '127.0.0.1',
						authorEmail = qComments.comment_author_email[y],
						authorURL= qComments.comment_author_url[y],
						createdDate = qComments.comment_date[y], isApproved = qComments.comment_approved[y]
					};
					var comment = commentService.new(properties=props);
					comment.setRelatedContent( page );
					arrayAppend( aComments, comment );
					//entitySave( comment );
					log.info("Page Comment imported: #props.authorEmail#");
				}
				page.setComments( aComments );
				log.info("Comments imported successfully!");
				
				entitySave( page );

			}

			/************************************** ENTRIES *********************************************/

			log.info("Starting to import Entries....");
			// Import Entries
			var qEntries = new Query(datasource=arguments.dsn,username=arguments.dsnUsername,
						     password=arguments.dsnPassword,
						     sql="select id,post_title AS title,post_name AS name,post_content AS content,post_status,comment_status,post_password,post_date AS last_modified,post_author AS author_id from #arguments.tableprefix#_posts where post_type='post'").execute().getResult();
			for(var x=1; x lte qEntries.recordcount;x++){
				// Get properties
				var published = true;
				var commentStatus = true;
				if( trim(qEntries.post_status[x]) neq "publish" ){ published = false; }
				if( qEntries.comment_status[x] neq "open" ){ commentSatus = false; }

				var props = {title=qEntries.title[x], slug=qEntries.name[x], content=fixWordPressContent(qEntries.content[x]), excerpt="", publishedDate=qEntries.last_modified[x],
							 createdDate=qEntries.last_modified[x], isPublished=published, allowComments=commentStatus, layout="entries"};

				var moreLoc = findnocase("<!--more-->", props.content);
				if( (moreLoc-1) GT 0 ){
					props.excerpt = left(props.content, moreLoc-1 );
				}

				// slug checks
				if( !len(Trim(props.slug)) ){
					props.slug = htmlHelper.slugify(props.title);
				}
				// check if slug already in map
				if( structKeyExists(slugMap, props.slug) ){
					// unique it
					props.slug &= "-" & left(hash(now()),5);
				}
				slugMap[ props.slug ] = "found";

				var entry = entryService.new(properties=props);
				// Add content versionized!
				entry.addNewContentVersion(content=props.content,changelog="Imported content",author=authorService.get( authorMap[qEntries.author_id[x]] ));
				entry.setCreator( authorService.get( authorMap[qEntries.author_id[x]] ) );
				
				// Save entry and store in reference map
				entryMap[ qEntries.id[x] ] = entry;
				var c = entryService.newCriteria();
				var counter=1;
				var count = new query(sql="SELECT COUNT(*) AS ct FROM cb_content WHERE contentType = 'post' AND slug = '#entry.getSlug()#';").execute().getResult()['ct'];
				do{
					var count = new query(sql="SELECT COUNT(*) AS ct FROM cb_content WHERE contentType = 'post' AND slug = '#entry.getSlug()#';").execute().getResult()['ct'];
					if(count eq 0){break;}
					// verify no slug exists & append if it does
					counter++;
					entry.setSlug(props.slug & '-' & counter);
				}while( count );
				
				// entry categories
				var thisSQL = "
				select a.term_id, a.name, a.slug, b.term_taxonomy_id, d.post_name, d.id
					from #arguments.tableprefix#_terms a, #arguments.tableprefix#_term_taxonomy b, #arguments.tableprefix#_term_relationships c, #arguments.tableprefix#_posts d
					where a.term_id = b.term_id
					AND b.taxonomy = 'category'
					AND b.term_taxonomy_id = c.term_taxonomy_id
					AND c.object_id = d.id
					AND d.post_type = 'post' 
					AND d.id = '#qEntries.id[x]#'
				";
				var qCategories = new Query(datasource=arguments.dsn,username=arguments.dsnUsername,
						     		    	password=arguments.dsnPassword,
						     		    	sql=thisSQL).execute().getResult();
				var aCategories = [];
				for(var y=1; y lte qCategories.recordcount; y++){
					arrayAppend( aCategories, categoryService.get( catMap[ qCategories.term_id[y] ] ) );
				}
				entry.setCategories( aCategories );
				
				log.info("Starting to import Post Comments....");
				// Import entry comments
				var qComments = new Query(datasource=arguments.dsn,username=arguments.dsnUsername,
											password=arguments.dsnPassword,
											sql="select * from #arguments.tableprefix#_comments 
												WHERE comment_post_ID = '#qEntries.id[x]#'
												  AND comment_approved <> 'spam'").execute().getResult();

				var aComments = [];
				for(var y=1; y lte qComments.recordcount; y++){
					var props = {
						content = qComments.comment_content[y], 
						author = qComments.comment_author[y], 
						authorIP = '127.0.0.1',
						authorEmail = qComments.comment_author_email[y],
						authorURL= qComments.comment_author_url[y],
						createdDate = qComments.comment_date[y], 
						isApproved = qComments.comment_approved[y]
					};
					var comment = commentService.new(properties=props);
					comment.setRelatedContent( entry );
					arrayAppend( aComments, comment );
					//entitySave( comment );
					log.info("Post Comment imported: #props.authorEmail#");
				}
				entry.setComments( aComments );
				log.info("Comments imported successfully!");
				
				// Save entry
				entitySave( entry );
			}
		}
		// end of try
		catch(any e){
			log.error("Error importing blog: #e.message# #e.detail#",e);
			writeDump(e);abort;
			rethrow;
		}

		// Commit All entities
		transaction action="commit"{}

	}

	private function fixWordPressContent(required string str){
		var myStr = trim(arguments.str);

		myStr = replaceNoCase(myStr,chr(10),'</p><p>','all');
		myStr = replaceNoCase(myStr,chr(13),'</p><p>','all');
		myStr = replaceNoCase(myStr,'<p></p>','','all');
		myStr = replaceNoCase(myStr,'<p></p>','','all');
		myStr = replaceNoCase(myStr,'<p></p>','','all');
		myStr = replaceNoCase(myStr,'<p></p>','','all');
		myStr = replaceNoCase(myStr,'<p></p>','','all');
		myStr = replaceNoCase(myStr,'<p><h1','<h1','all');
		myStr = replaceNoCase(myStr,'</h1></p>','</h1>','all');

		myStr = replaceNoCase(myStr,'<p><h2','<h2','all');
		myStr = replaceNoCase(myStr,'</h2></p>','</h2>','all');

		myStr = replaceNoCase(myStr,'<p><h3','<h3','all');
		myStr = replaceNoCase(myStr,'</h3></p>','</h3>','all');

		myStr = reReplace(myStr,'\[caption[^\]]*\]','','all');
		myStr = replaceNoCase(myStr,'[/caption]','','all');

		return myStr;
	}

}