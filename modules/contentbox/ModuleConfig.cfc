﻿/**
* ContentBox - A Modular Content Platform
* Copyright since 2012 by Ortus Solutions, Corp
* www.ortussolutions.com/products/contentbox
* ---
* ContentBox main module configuration
*/
component {

	// Module Properties
	this.title 				= "ContentBox Core";
	this.author 			= "Ortus Solutions, Corp";
	this.webURL 			= "http://www.ortussolutions.com";
	this.description 		= "An enterprise modular content platform";
	this.version			= "3.0.0-beta+@build.number@";
	this.viewParentLookup 	= true;
	this.layoutParentLookup = true;
	this.entryPoint			= "cbcore";
	this.modelNamespace 	= "cb";
	this.dependencies 		= [];

	function configure(){
		// contentbox settings
		settings = {
			codename = "Psalm 144:1",
			codenameLink = "https://www.bible.com/bible/114/psa.144.1.nkjv",
			// Auto Updates
			updateSlug_stable 	= "contentbox-stable-updates",
			updateSlug_beta 	= "contentbox-beta-updates",
			updatesURL			= "http://www.coldbox.org/api/forgebox",
			// Officially supported languages for modules
			languages 			= [ "de_DE", "en_US", "es_SV", "it_IT", "pt_BR" ]
		};
		
		// i18n
		i18n = {
			resourceBundles = {
		    	"cbcore" = "#moduleMapping#/i18n/cbcore"
		  	},
		  	defaultLocale = "en_US",
		  	localeStorage = "cookie"
		};

		// CB Module Conventions
		conventions = {
			layoutsLocation = "themes",
			viewsLocation 	= "themes"
		};

		// Parent Affected Settings
		parentSettings = {
			// override messagebox styles
			messagebox_style_override	= true,
			// File Browser module name override
			filebrowser_module_name		= "contentbox-filebrowser",
			// JSMin settings
			jsmin_enable = true
		};

		// interceptor settings
		interceptorSettings = {
			// ContentBox Custom Events
			customInterceptionPoints = arrayToList([
				// Code Rendering
				"cb_onContentRendering","cb_onContentStoreRendering"
			])
		};

		// interceptors
		interceptors = [
			// Rate Limiter
			{ class="contentbox.models.security.RateLimiter", name="RateLimiter@cb" },
			// CB RSS Cache Cleanup Ghost
			{ class="contentbox.models.rss.RSSCacheCleanup", name="RSSCacheCleanup@cb" },
			// CB Content Cache Cleanup Ghost
			{ class="contentbox.models.content.util.ContentCacheCleanup", name="ContentCacheCleanup@cb" },
			// Notification service interceptor
			{ class="contentbox.models.system.NotificationService", name="NotificationService@cb" },
			// Content Renderers, remember order is important.
			{ class="contentbox.models.content.renderers.LinkRenderer", name="LinkRenderer@cb" },
			{ class="contentbox.models.content.renderers.WidgetRenderer", name="WidgetRenderer@cb" },
			{ class="contentbox.models.content.renderers.SettingRenderer", name="SettingRenderer@cb" },
			{ class="contentbox.models.security.LoginTracker", name="LoginTracker@cb" }
		];

		// Manual Mappings
		binder.map( "customFieldService@cb" ).toDSL( "entityService:cbCustomField" );

		// ColdBox Integrations
		binder.map( "ColdBoxRenderer" ).toDSL( "coldbox:Renderer" );
		binder.map( "SystemUtil@cb" ).to( "coldbox.system.core.util.Util" );
		
		// Verify if the AOP mixer is loaded, if not, load it
		if( !isAOPMixerLoaded() ){
			loadAOPMixer();
		}
		
		// Load Hibernate Transactions for ContentBox
		loadHibernateTransactions( binder );
	}
	
	/**
	* Development tier
	*/
	function development(){
		//parentSettings.jsmin_enable = false;
	}

	/**
	* Fired when the module is registered and activated.
	*/
	function onLoad(){
		// Startup the Editor Service, needed for markup translations support
		wirebox.getInstance( "EditorService@cb" );
		// Startup the ContentBox modules, if any
		wirebox.getInstance( "moduleService@cb" ).startup();
		// Startup localization settings
		if( controller.getSetting( 'using_i18n' ) ){
			// Load resource bundles here when ready
		} else{
			// Parent app does not have i18n configured, so add settings manually
			controller.setSetting( 'LocaleStorage', 'cookie' );
			// Add Back when Ready -> controller.setSetting( 'defaultResourceBundle', moduleMapping & '/includes/i18n/main' );
			controller.setSetting( 'defaultLocale', "en_US" );
			// initialize i18n plugin
		}
	}

	/**
	* Fired when the module is unregistered and unloaded
	*/
	function onUnload(){
	}

	/************************************** PRIVATE *********************************************/

	/**
	* load hibernatate transactions via AOP
	*/
	private function loadHibernateTransactions(binder){
		// map the hibernate transaction for contentbox
		binder.mapAspect( aspect="CFTransaction", autoBinding=false )
			.to( "coldbox.system.aop.aspects.CFTransaction" );

		// bind the aspect
		binder.bindAspect(
			classes = binder.match().regex( "contentbox.*" ),
			methods = binder.match().annotatedWith( "transactional" ),
			aspects = "CFTransaction"
		);
	}
	
	// Load AOP Mixer
	private function loadAOPMixer(){
		var mixer = new coldbox.system.aop.Mixer();
		// configure it
		mixer.configure( wirebox, {} );
		// register it
		controller.getInterceptorService().registerInterceptor( interceptorObject=mixer, interceptorName="AOPMixer" );
	}
	
	// Verify if wirebox aop mixer is loaded
	private function isAOPMixerLoaded(){
		var listeners 	= wirebox.getBinder().getListeners();
		var results 	= false;
		
		for( var thisListener in listeners ){
			if( thisListener.class eq "coldbox.system.aop.Mixer" ){
				results = true;
				break;
			}
		}
		
		return results;
	}

}
