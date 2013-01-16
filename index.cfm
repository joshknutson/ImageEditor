<cfsilent>
	<cfset dataDirectory = "#getDirectoryFromPath(getCurrentTemplatePath()) & "data/"#" />
<cfif isdefined("form") and !structisempty(form)>
	<cfset asset = {} />
	<cfif fileexists("#dataDirectory#data.json")>
		<cfset asset = deserializeJSON(fileRead( "#dataDirectory#data.json" )) />
	</cfif>

	<cfloop list="edit,active,original" index="folder">
		<cffile action = "upload"
        fileField = "image_upload"
        destination = "#getDirectoryFromPath(getCurrentTemplatePath()) & "#folder#/"#"
        accept = "image/jpg,image/jpeg,image/png"
        nameConflict = "MakeUnique" />

		<cfimage action="read" source="#folder#/#cffile.serverFile#" name="image" />

		<cfset asset[cffile.serverFile][folder] = {image=BinaryEncode(ImageGetBlob(image),"base64")} />
	</cfloop>
	<cfset fileWrite("#dataDirectory#data.json",serializeJSON( asset )) />
	<cflocation addtoken="false" url="?imageName=#cffile.serverFile#" />
	</cfif>
	<cfset ih = createObject("component","imageHistogram").init() />
</cfsilent>
<!doctype html>
<html lang="en">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
	<title>Image Editor</title>

	<style type="text/css">@import "ImageEditor.css";</style>
	<script type="text/javascript" src="PageInfo.js"></script>
	<script type="text/javascript" src="ImageEditor.js"></script>
	<script type="text/javascript">
	//<![CDATA[
		if (window.opener){
			window.moveTo(0, 0);
			window.resizeTo(screen.width, screen.height - 28);
			window.focus();
		}
		window.onload = function(){
			<cfif isDefined("url.imageName")>
				<cfoutput>ImageEditor.init("#trim(url.imageName)#");</cfoutput>
				<cfimage action="read" source="active/#url.imageName#" name="image" />
			</cfif>
		};
	//]]>
	</script>
</head>
<body>
	<div id="ImageEditorContainer">
		<div id="ImageEditorToolbar">
			<form method="post" enctype="multipart/form-data">
				<input type="file" name="image_upload" />
				<input type="submit" value="upload" />
			</form>
			<button onclick="ImageEditor.save()">Save As Active</button><button onclick="ImageEditor.viewActive()">View Active</button><button onclick="ImageEditor.viewOriginal()">View Original</button>
			<span class="spacer"> || </span>w:<input id="ImageEditorTxtWidth" type="text" size="3" maxlength="4" />&nbsp;h:<input id="ImageEditorTxtHeight" type="text" size="3" maxlength="4" /><input id="ImageEditorChkConstrain" type="checkbox" checked="checked" />Constrain&nbsp;<button onclick="ImageEditor.resize();">Resize</button>
			<span class="spacer"> || </span>
			<button onclick="ImageEditor.crop()">Crop</button>
			<span class="spacer"> || </span>
			<button onclick="ImageEditor.rotate(90)">90&deg;CCW</button><button onclick="ImageEditor.rotate(270)">90&deg;CW</button>
			<span class="spacer"> || </span>
			<span id="ImageEditorCropSize"></span>
		</div>
		<div id="imageEditorSidebar">
		<fieldset><legend>Histogram</legend>
		<cfif isDefined("url.imageName")>
		<cfset hist = ih.getHistogramImage(image) />
		<cfimage action="writeToBrowser" source="#hist#">
		</cfif>
		</fieldset>
		</div>
		<div id="ImageEditorImage">&nbsp;</div>
	</div>

</body>
</html>