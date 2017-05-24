$(function() {
	
	// Create Plugin
	
	
	// Init
	//---------
	/*
	console.log("Setting up diagrams...")
	$(".h2dl-hdl-diagram").each(function(i,d) {
		
		$(d).sticky();
		
		console.log("Found diagram...");
		var descStr = $(d).data("outline");
		console.log("Desc: "+descStr);
		
		var desc = jQuery.parseJSON("{"+descStr+"}");
		console.log("D: "+desc.Hierarchy.Name);
		
		// Is There a code next to us ? 
		//----------
		var codeAndOutline = $(d).closest(".code-and-outline");
		var editorElement = $(codeAndOutline).find(".code .ace-editor");
		if (editorElement) {
			
			var editor = $(editorElement).data("editor");
			console.log("Found Diagram Editor..."+editor);
			
			
		}
		// Create SVG Diagram
		//--------------
		
		//- Target size
		var targetWidth = 100
		var targetHeight = 100
		
		var diagramDiv = d3.select(d);
		var svg = diagramDiv.append("svg");
		svg.attr("viewBox","0 0 "+targetWidth+" "+targetHeight);
		
		// Add Box Groups
		//------------
		var leftSizePercent = .20
		var middleSizePercent = .60
		var rightSizePercent = .20
		
		var leftIOBox = svg.append("g");
		var leftIOBox = svg.append("g");
		var rightIOBox = svg.append("g");
		
		// Make Hier Box
		//-----------------
		
		//-- Params
		var textSize = "6";
		
		//-- Box
		var boxGroup = svg.append("g");
		
		//-- Rect
		var boxRect = boxGroup.append("rect")
			.attr("fill","darkblue")
			.attr("width",targetWidth*middleSizePercent)
			.attr("height",targetHeight)
			.attr("x",targetWidth*leftSizePercent);
		
		//-- Text parseInt(boxRect.attr("width"))/2
		boxGroup.append("text")
			.attr("x",parseFloat(boxRect.attr("x")) + parseFloat(boxRect.attr("width"))/2)
			.attr("y",0)
			.attr("text-anchor","middle") // Use to have text centered on X
			.attr("dominant-baseline","text-before-edge") // Use to have text vertical starting at y (not middle of text at y)
			.attr("font-family","Sans-Serif")
			.attr("font-size",textSize)
			.attr("fill","white")
			.append("tspan").text(desc.Hierarchy.Name);
		
		// Left Box
		//------------
		var startY = 20;
		var ioSpacing = 15;
		var spacing = 10;
		var leftIoCount = 0 ;
		$(desc.Hierarchy.OutlineElement).each(function(i,element) {
			
			if (element.Type=="input" || element.Type=="output") {
				
				//-- Line
				var line = leftIOBox.append("line")
				line.attr("x1",0)
					.attr("x2",targetWidth*leftSizePercent)
					.attr("y1",startY + leftIoCount * ioSpacing)
					.attr("y2",startY + leftIoCount * ioSpacing)
					.attr("stroke","black")
					
				//-- Text on top
				var ioText = leftIOBox.append("text")
				ioText
					.attr("x",(line.attr("x2")-line.attr("x1"))/2)
					.attr("y",line.attr("y1"))
					.attr("text-anchor","middle") // Use to have text centered on X
					.attr("dominant-baseline","text-after-edge") // Use to have text vertical starting at y (not middle of text at y)
					.attr("font-family","Sans-Serif")
					.attr("font-size",textSize)
					.append("tspan").text(element.Name);
				
				//-- Line Hint
				if (editor) {
					
					$(element.Hint).each(function(i,hint) {
						
						if (hint.Name=="line") {
							
							var hintLine = parseInt(hint.Value);
							
							console.log("Listening to cursor");
							$(editor).on("click",function(e) {
								
								var line = editor.getCursorPosition().row+1
								console.log("Line: "+line);
								if (hintLine==line) {
									ioText.attr("stroke","red");
								} else {
									ioText.attr("stroke","");
								}
								
								
							});
						}
						
					});
					
					
				}
				
				leftIoCount++;
			}
			
			
		});
			
		
	});*/
	
});