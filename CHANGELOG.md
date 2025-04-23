# Changelog

## v1.0.10

* Tidy up task manager displaygroup title

## v1.0.9

* Fix issues with duplicate entry errors recording "recently visited" entries for launcher

## v1.0.8

* [#10](https://github.com/pixl8/preside-ext-launcher/issues/10) compat issue: siteTreeService not available in admin only apps

## v1.0.7

* [#9](https://github.com/pixl8/preside-ext-launcher/issues/9) Prevent duplicate entry attempts for 'recently visited' data

## v1.0.6

* [#8](https://github.com/pixl8/preside-ext-launcher/issues/8) Cascade delete 'recently visisted' records when deleting admin users

## v1.0.5

* Quick find not working properly for multi-word search terms
* Build using GitHub Actions

## v1.0.4

* Fix umlaut characters in the German translations

## v1.0.3

* Only do launcher operations for admin requests.

## v1.0.2

* Cache navigation items that otherwise require expensive permissioning checks, etc.

## v1.0.1

* Added German translations for the UI

## v1.0.0

* Public release

## v0.2.11

* Tidy up build files (remove redundant test parts)
* Update install instructions in README

## v0.2.10

* Fix issue where prefetch was very slow due to no limit on the number of records fetched

## v0.2.9

* Added changelog :)

## v0.2.8

* Move to MIS publishing method

## v0.2.7

* Try/catch rendering of links to remembered objects + fix i18n for system config recently visited items. Try catch necessary because either DB entries could be falsified OR become out of date where application objects no longer exist, etc.

## v0.2.6

* Add ability to configure search fields per object for the object datasource search (thanks to Sacha)

## v0.2.5

* Fix issue with getting 'recently visited' entries for objects that don't render for launcher, etc.

## v0.2.4

* Add a feature flag for launcher extension installation detection
* Always initialize launcher context data pre layout, regardless of autoinjection

## v0.2.3

* Ensure we don't add duplicate items to the launcher + remove bad shortcut descriptions

## v0.2.2

* Fix issue with missing 'args'

## v0.2.1

* Fix bad config reference

## v0.2.0

* Add some documentation
* Add interception point to be able to modify core datasource configs
* Add a 'navigation' datasource and merge with datamanager + system config
* Always have the 'this page' datasource say 'This page' rather than change with the page title
* Add tab navigation to 'this page' datasource
* Add concept of javascript generated datasources + implement datasource that finds action links buttons on pages

## v0.1.5

* Document the recently visited features of datasources
* Harden the recently visited system so that we can have abritrary recording and rendering of recently visited items per datasource (rather than only catering for object data)

## v0.1.4

* Ensure that box does not overlap other top nav items when not focused

## v0.1.3

* Add site tree pages to datasource

## v0.1.2

* Tweak positioning of autosuggest search box
* Add a more in-depth hint when activating search
* Fix js errors when local datasources are empty (e.g. recently viewed)

## v0.1.1

* Add README

## v0.1.0

* First alpha release
