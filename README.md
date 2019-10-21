# Preside admin Launcher

The Preside admin launcher extension brings "quick find/launch" functionality to the Preside admin.

## Installation

```
box install preside-ext-launcher
```


## Configuration

The launcher will work as is out of the box if you have a standard Preside admin layout. However, there are some configuration options that you should be aware of to help you tweak the functionality to your requirements.

In Config.cfc

```cfc
// default datasources list:
// tweak this to add your own datasources
// and/or change the priority order of datasources
settings.launcher.datasources = [ "thispage", "recent", "pages", "objectdata", "navigation"];

// default objects for the objectData + recentObjectData datasources
// you should configure this array with key objects that
// should be quick findable in your application.
settings.launcher.objectDatasources = [ "crm_contact", "crm_organisation" ]; // empty by default

// whether or not to auto inject the launcher
// into the admin layout header. If you are not
// using the default admin layout, you may need to set this
// to false and render the launcher yourself in your header
settings.launcher.autoInjectInHeader = true;

// maximum number of items to store in the recently
// visited records datasource (stores in the database)
settings.launcher.maxRecentlyVisitedItems = 20;
```

## Custom datasources

You can add your own custom datasources by adding them to the `settings.launcher.datasources` array. e.g.

```settings.launcher.datasources.append( "mycustomdatasource" )```

Each datasource must then implement:

### i18n entry

Two entries in `/i18n/launcher.properties`, one for the title and one for the iconClass. e.g.

```properties
datasource.mycustomdatasource.title=My datasource
datasource.mycustomdatasource.iconClass=fa-database purple
```

### Config handler

Create a handler with a `config` method at `/handlers/admin/launcher/datasource/{datasourcename}.cfc`. The `config` method should return a configuration struct for the datasource (see reference below).

You may also optionally implement `recordRecentlyVisited()` and `renderRecentlyVisitedItem()` actions to allow visits to pages in your datasource to appear in the 'Recently visited' menu. For example:

```cfc
component {

	property name="launcherService" inject="launcherService";

	private array function config( event, rc, prc ) {
		return launcherService.getObjectDataDatasources();
	}

	/**
	 * Runs at the end of a request and should return a
	 * struct of data to identify the recently visited page
	 * (empty struct if current page not relevent to your datasource)
	 * Logic to determine this is up to you. Receives no arguments.
	 */
	private struct function recordRecentlyVisited( event, rc, prc ) {
		if ( Len( Trim( prc.objectName ?: "" ) ) && Len( Trim( prc.recordId ?: "" ) ) ) {
			return {
				  objectName = prc.objectName
				, recordId   = prc.recordId
			}
		}

		return {};
	}

	/**
	 * Must return a launcher item struct representing the saved
	 * recently visited item. Receives the data you returned in
	 * recordRecentlyVisited() as arguments.
	 * Return {} to have the item ignored.
	 */
	private struct function renderRecentlyVisitedItem( event, rc, prc, objectName="", recordId="" ) {
		if ( Len( Trim( arguments.recordId ) ) && Len( Trim( arguments.objectName ) ) ) {
			return {
				  id          = "recent-" & arguments.recordId
				, icon        = translateResource( uri="preside-objects.#arguments.objectName#:iconClass", defaultValue="fa-database" )
				, text        = renderLabel( arguments.objectName, arguments.recordId )
				, description = ""
				, url         = event.buildAdminLink( objectName=arguments.objectName, recordId=arguments.recordId )
			};
		}

		return {};
	}
}
```

### Datasource config reference

Each datasource config is defined as a struct with the following keys:

* `local` (optional, required if no `remoteURL`): an array of items (see item reference below) for the launcher
* `defaultSuggestions` (optional): an array of items that will be shown as soon as the launcher is focused
* `remoteUrl` (optional, required if no `local`): URL that will return a json array of items given a search query. Should contain a `%QUERY` token that will be replaced with the currently active search term
* `prefetchUrl` (optional): URL that will return a json array of items to prepopulate search for the datasource
* `javascriptSrc` (optional): `boolean`. If `true`, then a javascript event will be triggered on the `$( "#preside-launcher-input" )` input matching the datasource name that allows you to configure the datasource in javascript. See javascript datasource below

### Item reference

Each item in a datasource is represented as a struct with the following items:

* `id`: unique ID of the item
* `text`: searchable and displayed text
* `description`: optional description of the item
* `icon`: font-awesome icon class to display with the item
* `url`: URL to browse to when item is selected

### Javascript datasources

Javascript based datasources can be created by setting a `javascriptSrc=true` configuration in your datasource config handler and providing javascript that listens for the jQuery event `prepare{lower-cased-datasource-name}Datasource`. The event will be passed three arguments:

1. the javascript event object
2. an empty 'helper' object. You are expected to set a 'bh' key in here with a configured BloodHound instance
3. a 'config' object containing the launcher datasource from Preside

Example:

```js
( function( $ ){
	( "#preside-launcher-input" ).on( "preparethispageDatasource", function( ev, helper, config ){
		var items = [{text:"Oranges", ...}, {text:"Apples", ...}]; // should have same keys as item definition, above

		helper.bh = new Bloodhound( $.extend( {}, {
			  datumTokenizer : function(d) { return Bloodhound.tokenizers.whitespace( d.text); }
			, queryTokenizer: Bloodhound.tokenizers.whitespace
			, local : items
		}, config.bloodhoundOptions ) );

		config.typeaheadOptions.minLength = 0;
		config.typeaheadOptions.source = function(q, sync) {
			if ( q === '' ) {
				sync( items );
			} else {
				helper.bh.ttAdapter()(q, sync);
			}
		}
	} );
} );
```

### ObjectData datasource

The ObjectData datasource allows you to search preside objects (configured in `settings.launcher.objectDatasources`) within your application. By default, the launcher will search the `labelfield` of the given object. If you want a specific set of fields to be used for searching you can add a `launcherSearchFields` attribute to your object cfc.

```cfc
/**
 * @launcherSearchFields   productId,label
 */
component {
	property name="productId" ype="string" dbtype="varchar" maxlength=40 uniqueIndexes="product_identifers";
    // .. etc.
}
```
