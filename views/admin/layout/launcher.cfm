<cfscript>
	launcherPlaceholder     = htmlEditFormat( translateResource( "launcher:search.placeholder" ) );
	launcherPlaceholderLong = htmlEditFormat( translateResource( "launcher:search.placeholder.long" ) );
</cfscript>

<cfoutput>
	<div class="navbar-header pull-left launcher-menu-container">
		<ul class="nav ace-nav">
			<li class="launcher-menu clearfix">
				<label for="preside-launcher-input" class="launcher-menu-icon"><i class="fa fa-fw fa-bolt"></i></label>
				<input name="preside-launcher-input" id="preside-launcher-input" class="launcher-menu-input compact" placeholder="#launcherPlaceholder#" data-placeholder-long="#launcherPlaceholderLong#" />

				<div class="launcher-results-footer hide">
					<p class="text-right grey"><em>#translateResource( uri="launcher:keyboard.help", data=[ "<code>/</code>", "<code>esc</code>" ] )#</em></p>
				</div>
			</li>
		</ul>
		&nbsp;
	</div>
</cfoutput>