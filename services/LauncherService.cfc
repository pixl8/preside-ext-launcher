/**
 * @presideService true
 * @singleton      true
 */
component {

// CONSTRUCTOR
	/**
	 * @configuredDatasources.inject coldbox:setting:launcher.datasources
	 * @configuredObjectDatasources.inject coldbox:setting:launcher.objectDatasources
	 * @datamanagerService.inject delayedInjector:datamanagerService
	 * @labelRendererService.inject labelRendererService
	 *
	 */
	public any function init(
		  required array configuredDatasources
		, required array configuredObjectDatasources
		, required any   datamanagerService
		, required any   labelRendererService
	) {
		_setConfiguredDatasources( arguments.configuredDatasources );
		_setConfiguredObjectDatasources( arguments.configuredObjectDatasources );
		_setDatamanagerService( arguments.datamanagerService );
		_setLabelRendererService( arguments.labelRendererService );

		return this;
	}

// PUBLIC API METHODS
	public void function prepareDatasources() {
		var datasources = [];

		for( var datasource in _getConfiguredDatasources() ) {
			var args   = { config=getDatasourceConfig( datasource ), datasource=datasource };

			$announceInterception( "onPrepareDatasource", args );

			if ( isArray( args.config ) ) {
				datasources.append( args.config, true );
			} else if ( args.config.count() ) {
				datasources.append( args.config );
			}
		}

		$getRequestContext().includeData( { launcherDatasources=datasources } );
	}

	public any function getDatasourceConfig( required string datasource ) {
		var handler = "admin.launcher.datasource.#datasource#.config";
		var coldbox = $getColdbox();
		var config  = {};

		if ( coldbox.handlerExists( handler ) ) {
			config = coldbox.runEvent( event=handler, private=true, prepostExempt=true );
			if ( ( IsStruct( local.config ?: "" ) && config.count() ) || ( IsArray( local.config ?: "" ) && config.len() ) ) {
				config = _validateConfig( config, datasource );
			} else {
				config = {};
			}
		}

		return config;
	}

	public array function getObjectDataDatasources() {
		var configured  = _getConfiguredObjectDatasources();
		var event       = $getRequestContext();
		var baseRemoteLink = event.buildAdminLink( linkto="launcher.searchObjectRecordsForLauncher", queryString="object={object}&q=%QUERY" );
		var basePrefetchLink = event.buildAdminLink( linkto="launcher.prefetchObjectRecordsForLauncher", queryString="object={object}&prefetchCachebuster={prefetchCachebuster}" );
		var datasources = [];

		for( var configuredObject in configured ) {
			if ( IsSimpleValue( configuredObject ) ) {
				configuredObject = { id=configuredObject };
			}
			var objectName = configuredObject.id ?: "";

			configuredObject.remoteUrl                  = configuredObject.remoteUrl   ?: baseRemoteLink.replace( "{object}", objectName );
			configuredObject.prefetchUrl                = configuredObject.prefetchUrl ?: basePrefetchLink.replace( "{object}", objectName ).replace( "{prefetchCachebuster}", _getDatamanagerService().getPrefetchCachebusterForAjaxSelect( objectName ) );
			configuredObject.title                      = configuredObject.title       ?: $translateResource( uri="preside-objects.#objectName#:title", defaultValue=objectName );
			configuredObject.iconClass                  = configuredObject.iconClass   ?: $translateResource( uri="preside-objects.#objectName#:iconClass", defaultValue="" );
			configuredObject.typeaheadOptions           = configuredObject.typeaheadOptions  ?: {}
			configuredObject.typeaheadOptions.minLength = configuredObject.typeaheadOptions.minLength ?: 2;

			configuredObject.id = "object-" & configuredObject.id;

			datasources.append( _validateConfig( configuredObject, configuredObject.id ) );
		}

		return datasources;
	}

	public array function prefetchObjectRecordsForLauncher() {
		// todo, some smarter things here
		return searchObjectRecordsForLauncher( argumentCollection=arguments );
	}

	public array function searchObjectRecordsForLauncher(
		  required string  object
		,          string  q                        = ""
		,          struct  additionalSelectDataArgs = {}
		,          string  labelRenderer            = _getObjectLabelRendererForLauncher( arguments.object )
		,          numeric maxRows                  = 100
	) {
		var event          = $getRequestContext();
		var recordLinkBase = event.buildAdminLink( objectName=arguments.object, recordId="{id}" );
		var objectIcon     = $translateResource( uri="preside-objects.#arguments.object#:iconclass", defaultValue="fa-database" );
		var labelField     = $getPresideObjectService().getLabelField( arguments.object );
		var idField        = $getPresideObjectService().getIdField( arguments.object );
		var selectFields   = _getLabelRendererService().getSelectFieldsForLabel( arguments.labelRenderer );
		var result         = [];
		var idFieldFound   = false;

		var args           = {
			  objectName   = arguments.object
			, selectFields = selectFields
			, autoGroupBy  = true
			, orderBy      = labelField
			, maxRows      = arguments.maxRows
		};


		if ( len( arguments.labelRenderer ) ) {
			args.orderBy = _getLabelRendererService().getOrderByForLabels( arguments.labelRenderer, { orderBy=args.orderBy } );
		}

		var searchFields = getLauncherSearchFields( arguments.object );
		if ( !arrayLen( searchFields ) ) {
			searchFields = args.selectFields;
		}

		if ( Len( Trim( arguments.q ) ) ) {
			var queryText = listToArray( decodeFromURL( arguments.q ), " " );

			args.filterParams = {};
			args.filter       = _buildSearchFilter(
				  queryText    = queryText
				, objectName   = arguments.object
				, labelfield   = labelfield
				, searchFields = searchFields
			);

			for ( var i=1; i<=arrayLen( queryText ); i++ ) {
				args.filterParams[ "q#i#" ] = { type="varchar", value="%" & queryText[i] & "%" };
			}
		}

		for( var field in selectFields ) {
			if ( field.refindNoCase( "\bid$" ) ) {
				idFieldFound = true;
				break;
			}
		}
		if ( !idFieldFound ) {
			selectFields.append( "#arguments.object#.#idField# as id" );
		}

		args.append( arguments.additionalSelectDataArgs, false );
		var records = $getPresideObjectService().selectData( argumentCollection = args );
		for( var record in records ) {
			result.append( {
				  text  = ReplaceList(_getLabelRendererService().renderLabel( arguments.labelRenderer, record ), "&lt;,&gt;,&amp;,&quot;", '<,>,&,"' )
				, id    = record.id
				, url   = recordLinkBase.replace( "{id}", record.id )
				, icon  = objectIcon & " light-grey"
				, description = "" // TODO
			} );
		}

		return result;
	}

	public array function getLauncherSearchFields( required string objectName ) {
		var fields = $getPresideObjectService().getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "launcherSearchFields"
		);

		return listToArray( fields );
	}

// PRIVATE HELPERS
	private any function _validateConfig( required any config, required string datasource ) {
		if ( !isArray( arguments.config ) ) {
			arguments.config = [ arguments.config ];
		}

		for( var i=1; i<=arguments.config.len(); i++ ) {
			arguments.config[ i ].id                 = arguments.config[ i ].id                 ?: arguments.datasource;
			arguments.config[ i ].bloodhoundOptions  = arguments.config[ i ].bloodhoundOptions  ?: {};
			arguments.config[ i ].typeaheadOptions   = arguments.config[ i ].typeaheadOptions   ?: {};
			arguments.config[ i ].local              = arguments.config[ i ].local              ?: [];
			arguments.config[ i ].defaultSuggestions = arguments.config[ i ].defaultSuggestions ?: [];
			arguments.config[ i ].title              = arguments.config[ i ].title              ?: $translateResource( uri="launcher:datasource.#datasource#.title", defaultValue=arguments.datasource );
			arguments.config[ i ].iconClass          = arguments.config[ i ].iconClass          ?: $translateResource( uri="launcher:datasource.#datasource#.iconClass", defaultValue="" );
			arguments.config[ i ].remoteUrl          = arguments.config[ i ].remoteUrl          ?: "";
			arguments.config[ i ].prefetchUrl        = arguments.config[ i ].prefetchUrl        ?: "";
			arguments.config[ i ].javascriptSrc      = arguments.config[ i ].javascriptSrc      ?: false;
		}

		return arguments.config.len() == 1 ? arguments.config[ 1 ] : arguments.config;
	}

	private string function _getObjectLabelRendererForLauncher( required string objectName ) {
		var launcherRenderer = Trim( $getPresideObjectService().getObjectAttribute( arguments.objectName, "launcherLabelRenderer" ) );

		return launcherRenderer.len() ? launcherRenderer : Trim( $getPresideObjectService().getObjectAttribute( arguments.objectName, "labelRenderer" ) );
	}

	private string function _buildSearchFilter(
		  required array  queryText
		, required string objectName
		, required array  searchFields = []
		,          string labelfield   = $getPresideObjectService().getLabelField( arguments.objectName )
	) {
		var field        = "";
		var filter       = "";
		var delim        = "";
		var poService    = $getPresideObjectService();
		var parsedFields = poService.parseSelectFields(
			  objectName   = arguments.objectName
			, selectFields = arguments.searchFields
			, includeAlias = false
		);
		for ( var i=1; i<=arrayLen( arguments.queryText ); i++ ) {
			filter &= "(";

			for( field in parsedFields ){
				field = field.reReplaceNoCase( "\s+as\s+.+$", "" ); // remove alias
				if ( poService.getObjectProperties( arguments.objectName ).keyExists( field ) ) {
					field = _getFullFieldName( field,  arguments.objectName );
				}
				filter &= delim & field & " like :q#i#";
				delim = " or ";
			}

			delim  = "";
			filter &= ")";

			if ( i != arrayLen( arguments.queryText ) ) {
				filter &= " and ";
			}
		}

		return filter;
	}

	private string function _getFullFieldName( required string field, required string objectName ) {
		var poService = $getPresideObjectService();
		var fieldName = arguments.field;
		var objName   = arguments.objectName;
		var fullName  = "";

		if ( fieldName contains "${labelfield}" ) {
			fieldName = poService.getObjectAttribute( arguments.objectName, "labelfield", "label" );
			if ( ListLen( fieldName, "." ) == 2 ) {
				objName = ListFirst( fieldName, "." );
				fieldName = ListLast( fieldName, "." );
			}

			fullName = objName & "." & fieldName;
		} else {
			var prop = poService.getObjectProperty( objectName=objName, propertyName=fieldName );
			var relatedTo = prop.relatedTo ?: "none";

			if(  Len( Trim( relatedTo ) ) && relatedTo != "none" ) {
				var objectLabelField = poService.getObjectAttribute( relatedTo, "labelfield", "label" );

				if( Find( ".", objectLabelField ) ){
					fullName = arguments.field & "$" & objectLabelField;
				} else{
					fullName = arguments.field & "." & objectLabelField;
				}
			} else {
				fullName = objName & "." & fieldName;
			}
		}

		return poService.expandFormulaFields(
			  objectName   = objName
			, expression   = fullName
			, includeAlias = false
		);
	}

// GETTERS AND SETTERS
	private array function _getConfiguredDatasources() {
		return _configuredDatasources;
	}
	private void function _setConfiguredDatasources( required array configuredDatasources ) {
		_configuredDatasources = arguments.configuredDatasources;
	}

	private array function _getConfiguredObjectDatasources() {
		return _configuredObjectDatasources;
	}
	private void function _setConfiguredObjectDatasources( required array configuredObjectDatasources ) {
		_configuredObjectDatasources = arguments.configuredObjectDatasources;
	}

	private any function _getDatamanagerService() {
		return _datamanagerService;
	}
	private void function _setDatamanagerService( required any datamanagerService ) {
		_datamanagerService = arguments.datamanagerService;
	}

	private any function _getLabelRendererService() {
		return _labelRendererService;
	}
	private void function _setLabelRendererService( required any labelRendererService ) {
		_labelRendererService = arguments.labelRendererService;
	}
}