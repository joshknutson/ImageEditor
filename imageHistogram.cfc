	<!---
	Project      : ColdFusion 8 Image Histogram
	Version      : 0.1
	URL          : http://leavethatthingalone.com/projects/cfhistogram/
	Name         : imageHistogramCF8.cfc
	Author       : Seth Duffey - sethduffey@gmail.com (send feedback, bugs, feature requests, etc)
	Purpose		 : creates image histograms
	Created      : 6/1/2007
	Last Updated : 
	
	History      : 
					6/1/2007 - Code modified from original imageHistogram.cfc to take advantage cfimage features in ColdFusion 8 (cfimage and JAI).
					
	Purpose     : 
	
		This component creates B/W & color histograms and histogram images. 
		- Will return a structure containing histogram array(s) and statistics (mean,standard deviation,min,max).
		- Will return an image (cfimage format) of a B/W or color histogram

	NOTES        : 
				Requires ColdFusion 8 
	
	LICENSE:
		
	
	PUBLIC METHODS:
		getHistogram - retuns a structure that contains a histogram array[256] and histogram statistics
		getColorHistogram - returns a structure that contains a color histogram array[3][256] and histogram statistics
		getHistogramImage - Returns an image histogram in cfimage format
		getColorHistogramImage - Returns a color image histogram in cfimage format
		setBufferedImage - allows you to define a buffered image to retrieve histogram from
	
	
	EXAMPLE USES:
	-------------------------------------------------
	Example use to get color histogram array from an image:
		<!--- Create histogram object --->
		<cfset ih = createObject("component","imageHistogramCF8").init() />
		<!--- input image --->
		<cfset image = expandPath("01.jpg") />
		<!--- get color histogram --->
		<cfset hist = ih.getColorHistogram(image) />
		<cfdump var="#hist#">
	
	-------------------------------------------------
	Example of displaying a color histogram image:
		
		<cfimage action="read" source="01.jpg" name="image" />
		<cfset ih = createObject("component","imageHistogramCF8").init() />
		<cfset hist = ih.getColorHistogramImage(image) />
		<cfimage action="writeToBrowser" source="#hist#" />
				
		OR
		
		<cfscript>
			ih = createObject("component","imageHistogramCF8").init();
			image = expandPath("01.jpg");
			hist = ih.getColorHistogramImage(image);
		</cfscript>
		<cfimage action="writeToBrowser" source="#hist#" />
	
	-------------------------------------------------
	Example of displaying a color histogram image from a buffered image:
	
		<cfimage action="read" source="01.jpg" name="image" />
		<cfset bufferedImage = imageGetBufferedImage(image) />
		<cfset ih = createObject("component","imageHistogramCF8").init() />
		<cfset ih.setBufferedImage(bufferedImage) />
		<cfset hist = ih.getColorHistogramImage("") />
		<cfimage action="writeToBrowser" source="#hist#" />
	
	
	-------------------------------------------------
	Example of a differently sized a color histogram image:
	
		<cfimage action="read" source="02.jpg" name="image" />
		<cfset ih = createObject("component","imageHistogramCF8").init() />
		<cfset hist = ih.getColorHistogramImage(image,128,60) />
		<cfimage action="writeToBrowser" source="#hist#" />
	
	
	==============================================================
	==============================================================
	Apache License Version 2.0
	
	Copyright 2007 - Seth Duffey sethduffey@gmail.com
	
	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at
	
	http://www.apache.org/licenses/LICENSE-2.0
	
	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
	==============================================================
	==============================================================
	
	 --->

<cfcomponent output="false">
<!--- ===================================================================== --->
<!--- init --->
	<cffunction name="init" access="public" output="false" hint="I'm the constructor">
		<cfscript>
			//holder for image to get histogram from
			variables.inputImage = "";
			//create JAI object 
			variables.JAI = createObject("Java","javax.media.jai.JAI");
			//input Image Is Planar Image (would be set from buffered image Buffered)
			variables.inputImageIsPlanarImage = false;
		</cfscript>
		<cfreturn this/>
	</cffunction>
	
	
<!--- ===================================================================== --->
<!--- getHistogram --->
	<cffunction name="getHistogram" access="public" returntype="any" output="false" hint="">
		<cfargument name="inputImage" required="no" type="string" default="" hint="I return a histogram structure containing the histogram array and statistical values" />
		<cfscript>
			var histogram = "";
			//if input image is supplied then use it (otherwise image will come from set buffered image)
			if(len(arguments.inputImage)) {
				createInputImage(arguments.inputImage);
			};
			histogram = createJAIHistogram();
			//return histogram
			return histogram;
		</cfscript>
	</cffunction>
	
	
<!--- ===================================================================== --->
<!--- getColorHistogram --->
	<cffunction name="getColorHistogram" access="public" returntype="struct" output="false" hint="I return a color histogram structure containing the histogram array and statistical values">
		<cfargument name="inputImage" required="no" type="string" default="" hint="Filename and path of image to create histogram of" />
		<cfscript>
			var histogram = "";
			//if input image is supplied then use it (otherwise image will come from set buffered image)
			if(len(arguments.inputImage)) {
				createInputImage(arguments.inputImage);
			};
			histogram = createJAIColorHistogram();
			//return histogram
			return histogram;
		</cfscript>
	</cffunction>
<!--- ===================================================================== --->
<!--- getHistogramImage --->
	<cffunction name="getHistogramImage" access="public" returntype="any" output="false" hint="I create a color histogram PNG">
		<cfargument name="inputImage" required="yes" type="string" hint="Filename and path of image to create histogram of" />
		<cfargument name="width" required="yes" default="256" type="numeric" hint="height of png to create" />
		<cfargument name="height" required="yes" default="120" type="numeric" hint="height of png to create" />
		
		<cfscript>
			//create color histgram
			var histogram = getHistogram(arguments.inputImage);
			//draw and return image
			return drawHistogram(histogram,arguments.width,arguments.height);
		</cfscript>
	</cffunction>
	
<!--- ===================================================================== --->
<!--- getColorHistogramImage --->
	<cffunction name="getColorHistogramImage" access="public" returntype="any" output="false" hint="I create a color histogram PNG">
		<cfargument name="inputImage" required="yes" type="string" hint="Filename and path of image to create histogram of" />
		<cfargument name="width" required="yes" default="256" type="numeric" hint="height of png to create" />
		<cfargument name="height" required="yes" default="120" type="numeric" hint="height of png to create" />
		<cfscript>
			//create color histgram
			var histogram = getColorHistogram(arguments.inputImage);
			//draw and return image
			return drawColorHistogram(histogram,arguments.width,arguments.height);
		</cfscript>
	</cffunction>

	
<!--- ===================================================================== --->
<!--- createInputImage --->
	<cffunction name="createInputImage" access="private" returntype="void" output="false" hint="I create an image new">
		<cfargument name="inputImage" required="yes" type="string" default="" hint="Filename and path of image to create histogram of" />
			<cfset variables.inputImage = imageNew(arguments.inputImage) />
	</cffunction>

<!--- ===================================================================== --->
<!--- setBufferedImage --->
	<cffunction name="setBufferedImage" access="public" returntype="void" output="false" hint="I set the the buffered image, i can be used if you want to set a buffered image instead of specifying a image file name and path">
		<cfargument name="bufferedImage" required="yes" hint="Buffered image" />
		<cfset var pb = "" />
		<cfscript>
			pb = createObject("Java","java.awt.image.renderable.ParameterBlock").init();
			//add image source
			pb.add(arguments.bufferedImage);
			//create JAI PlanarImage 
			variables.inputImage = variables.JAI.create("AWTImage", pb);
			//
			variables.inputImageIsPlanarImage = true;
		</cfscript>
	</cffunction>
	
<!--- ===================================================================== --->
<!--- createJAIHistogram --->
	<cffunction name="createJAIHistogram" access="private" returntype="struct" output="false" hint="I create a histogram with JAI">
		<cfscript>
			var op = "";
			var bins = "";
			var i = 0;
			var histogram = "";
			var rgb = "";
			//create ParameterBlock
			var pb = createObject("Java","java.awt.image.renderable.ParameterBlock").init();
			//create holder structure
			var histogramStruct = createHistogramHolderStruct();
			//add image source

			if (inputImageIsPlanarImage) {
				//already a planar image
				pb.addSource(variables.inputImage);
			} else {
				//need to convert
				pb.addSource(imageGetBufferedImage(variables.inputImage));
			}
			//RenderedOp 
			op = variables.JAI.create("histogram", pb);
			//get histogram (javax.media.jai.Histogram)
			histogram = op.getProperty("histogram");
			//histogram bins - array[3][256]
			bins = histogram.getBins();
			//average colors into single array
			for(i=1;i LTE 256; i=i+1) {
				histogramStruct.histogram[i] = Round((bins[1][i] + bins[2][i] + bins[3][i])/3);
			}
			//get statistics
			rgb = getHistogramStatistics(histogramStruct.histogram);
			histogramStruct.mean = rgb.mean;
			histogramStruct.standarddeviation = rgb.standarddeviation;
			histogramStruct.min = rgb.min;
			histogramStruct.max = rgb.max;
			//return histogram structure
			return histogramStruct;
		</cfscript>
	</cffunction>

<!--- ===================================================================== --->
<!--- createJAIColorHistogram --->
	<cffunction name="createJAIColorHistogram" access="private" returntype="struct" output="false" hint="I create a color histogram with JAI">
		<cfscript>
			var op = "";
			var bins = "";
			var meanArray = "";
			var sdArray = "";
			//create ParameterBlock
			var pb = createObject("Java","java.awt.image.renderable.ParameterBlock").init();
			//create holder struct for histogram
			var colorHistogram = structNew();
			//add image source
			if (inputImageIsPlanarImage) {
				//already a planar image
				pb.addSource(variables.inputImage);
			} else {
				//need to convert
				pb.addSource(imageGetBufferedImage(variables.inputImage));
			}
			//RenderedOp 
			op = variables.JAI.create("histogram", pb);
			//get histogram (javax.media.jai.Histogram)
			histogram = op.getProperty("histogram");
			//histogram bins - array[3][256]
			bins = histogram.getBins();
			meanArray = histogram.getMean();
			sdArray = histogram.getStandardDeviation();
			//red
			colorHistogram.r.histogram = bins[1];
			colorHistogram.r.mean = meanArray[1];
			colorHistogram.r.standarddeviation = sdArray[1];
			colorHistogram.r.min = arrayMin(bins[1]);
			colorHistogram.r.max = arrayMax(bins[1]);
			//green
			colorHistogram.g.histogram = bins[2];
			colorHistogram.g.histogram = bins[2];
			colorHistogram.g.mean = meanArray[2];
			colorHistogram.g.standarddeviation = sdArray[2];
			colorHistogram.g.min = arrayMin(bins[2]);
			colorHistogram.g.max = arrayMax(bins[2]);
			//blue
			colorHistogram.b.histogram = bins[3];
			colorHistogram.b.histogram = bins[3];
			colorHistogram.b.mean = meanArray[3];
			colorHistogram.b.standarddeviation = sdArray[3];
			colorHistogram.b.min = arrayMin(bins[3]);
			colorHistogram.b.max = arrayMax(bins[3]);
			//return histogram structure
			return colorHistogram;
		</cfscript>
	</cffunction>
	
<!--- ===================================================================== --->
<!--- drawHistogram --->
	<cffunction name="drawHistogram" access="private" returntype="any" output="false" hint="I draw a histogram image">
		<cfargument name="histogram" required="yes" hint="histogram" />
		<cfargument name="width" required="yes" default="256" type="numeric" hint="width of image to create" />
		<cfargument name="height" required="yes" default="120" type="numeric" hint="height of image to create" />
		<cfscript>
			var ii = "";
			//create image
			var histImage = imageNew("",256,arguments.height,"argb");
			//set drawing color
			ImageSetDrawingColor(histImage,"black");
			//loop thru all bins in color
			for(ii=1;ii LTE 256; ii=ii+1) {
				//set max height based on the max size found in array
				lineHeight = arguments.height-((arguments.histogram.histogram[ii]/arrayMax(arguments.histogram.histogram)) * arguments.height);
				//draw line
				imageDrawLine(histImage,ii-1,arguments.height,ii-1,lineHeight);
			}
			//resize width if needed
			if(arguments.width != 256) {
				ImageSetAntialiasing(histImage,"on");
				ImageResize(histImage,arguments.width,arguments.height,"highestQuality");
			};
			//return image
			return histImage;
			</cfscript>
	</cffunction>

<!--- ===================================================================== --->
<!--- drawColorHistogram --->
	<cffunction name="drawColorHistogram" access="private" returntype="any" output="false" hint="I draw a color histogram image">
		<cfargument name="histogram" required="yes" hint="histogram" />
		<cfargument name="width" required="yes" default="256" type="numeric" hint="width of image to create" />
		<cfargument name="height" required="yes" default="120" type="numeric" hint="height of image to create" />
		<cfscript>
			var i = "";
			var ii = "";
			var color = "";
			//create image
			var histImage = imageNew("",256,arguments.height,"argb");
			//set drawing transpareceny
			ImageSetDrawingTransparency(histImage,66);
			//loop thru color bins r-g-b
			for(i=1;i LTE 3; i=i+1) {
				//set color based on bin
				if (i == 1) {//red
					ImageSetDrawingColor(histImage,"red");
					color = "r";
				} else if (i==2) {//green
					ImageSetDrawingColor(histImage,"green");
					color = "g";
				} else if (i==3) {//blue
					ImageSetDrawingColor(histImage,"blue");
					color = "b";
				}
				//loop thru all bins in color
				for(ii=1;ii LTE 256; ii=ii+1) {
					//set max height based on the max size found in array
					lineHeight = arguments.height-((arguments.histogram[color].histogram[ii]/arrayMax(arguments.histogram[color].histogram)) * arguments.height);
					//draw line
					imageDrawLine(histImage,ii-1,arguments.height,ii-1,lineHeight);
				}
			}
			//resize width if needed
			if(arguments.width != 256) {
				ImageSetAntialiasing(histImage,"on");
				ImageResize(histImage,arguments.width,arguments.height,"highestQuality");
			};
			//return image
			return histImage;
			</cfscript>
	</cffunction>
	
<!--- ===================================================================== --->
<!--- createHistogramHolderStruct --->
	<cffunction name="createHistogramHolderStruct" access="private" returntype="struct" output="false" hint="I create a histogram array">
		<cfscript>
			var holderStruct = structNew();
			holderStruct.histogram = arrayNew(1);
			holderStruct.mean = "";
			holderStruct.standarddeviation = "";
			holderStruct.min = "";
			holderStruct.max = "";
			return holderStruct;
		</cfscript>
	</cffunction>
	
<!--- ===================================================================== --->
<!--- getHistogramStatistics --->
	<cffunction name="getHistogramStatistics" access="private" output="false">
	<cfargument name="values" required="yes">
	<cfscript>
		var returnStruct = structNew();
		//var histArray = arguments.values;
		var NumValues = 0;
		var x = 0;
		var sumx = 0;  
		var i=0;
		//min
		returnStruct.min = arrayMin(arguments.values);
		//max
		returnStruct.max = arrayMax(arguments.values);
		histLength = arrayLen(arguments.values);
		x = arrayAvg(arguments.values);
		for (i=1; i LTE histLength; i=i+1) {
			sumx = sumx + ((arguments.values[i] - x) * (arguments.values[i] - x));
		};
		//mean
		returnStruct.mean = x;
		//SD
		returnStruct.standarddeviation = sqr(sumx/histLength);
		return  returnStruct;
	</cfscript>
</cffunction>
</cfcomponent>