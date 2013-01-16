<cfsilent>
<!---
processImage.cfm
Copyright (C) 2004-2006 Peter Frueh (http://www.ajaxprogrammer.com/)

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
--->

<!--- <cfheader name="Content-Type" value="text/plain" /> --->
<cfset variables.json = "" />

<cfset variables.originalDirectory = getDirectoryFromPath(getCurrentTemplatePath()) & "original/" />
<cfset variables.activeDirectory = getDirectoryFromPath(getCurrentTemplatePath()) & "active/" />
<cfset variables.editDirectory = getDirectoryFromPath(getCurrentTemplatePath()) & "edit/" />

<cfif not isDefined("form.action") or trim(form.action) eq "" or
	  not isDefined("form.imageName") or trim(form.imageName) eq "">
	<cfabort />
</cfif>
<cfif not fileExists("#variables.originalDirectory##form.imageName#") or
	  not fileExists("#variables.activeDirectory##form.imageName#") or
	  not fileExists("#variables.editDirectory##form.imageName#")>
	<cfset variables.json = "{imageFound:false}" />
</cfif>

<cfif trim(variables.json) eq "">
	<cfobject name="image" component="image" />

	<cfswitch expression="#trim(form.action)#">
		<cfcase value="viewOriginal">
			<cffile action="copy" source="#variables.originalDirectory##form.imageName#" destination="#variables.editDirectory##form.imageName#" />
		</cfcase>
		<cfcase value="viewActive">
			<cffile action="copy" source="#variables.activeDirectory##form.imageName#" destination="#variables.editDirectory##form.imageName#" />
		</cfcase>
		<cfcase value="save">
			<cffile action="copy" source="#variables.editDirectory##form.imageName#" destination="#variables.activeDirectory##form.imageName#" />
		</cfcase>
		<cfcase value="resize">
			<cfif not isDefined("form.w") or not isNumeric(form.w) or form.w lt 1 or form.w gt 2000 or
				not isDefined("form.h") or not isNumeric(form.h) or form.h lt 1 or form.h gt 2000>
				<cfabort />
			</cfif>
			<cfset image.resize("", "#variables.editDirectory##form.imageName#", "#variables.editDirectory##form.imageName#", form.w, form.h, false, 100) />
		</cfcase>
		<cfcase value="rotate">
			<cfif not isDefined("form.degrees") or (form.degrees neq 90 and form.degrees neq 180 and form.degrees neq 270)>
				<cfabort />
			</cfif>
			<!--- ADJUST DEGREES FOR IMAGE.CFC (IF YOU'RE WONDERING...IT'S OPPOSITE PHP) --->
			<cfset form.degrees = "-#form.degrees#" />
			<cfset image.rotate("", "#variables.editDirectory##form.imageName#", "#variables.editDirectory##form.imageName#", form.degrees, 100) />
		</cfcase>
		<cfcase value="crop">
			<cfif not isDefined("form.x") or not isNumeric(form.x) or
				  not isDefined("form.y") or not isNumeric(form.y) or
				  not isDefined("form.w") or not isNumeric(form.w) or
				  not isDefined("form.h") or not isNumeric(form.h)>
				<cfabort />
			</cfif>
			<cfset image.crop("", "#variables.editDirectory##form.imageName#", "#variables.editDirectory##form.imageName#", form.x, form.y, form.w, form.h, 100) />
		</cfcase>
	</cfswitch>

	<cfset imageInfo = image.getImageInfo("", "#variables.editDirectory##form.imageName#") />
	<cfset variables.json = '{imageFound:true,imageName:"#form.imageName#",w:#imageInfo.width#,h:#imageInfo.height#}' />
</cfif>
</cfsilent>
<cfoutput>#variables.json#</cfoutput>