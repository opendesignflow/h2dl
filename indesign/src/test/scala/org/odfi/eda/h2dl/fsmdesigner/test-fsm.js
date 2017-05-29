console.info("Test");
var fsmStr='"FSM":{"name": "Counter FSM","Input":[{"name": "start"},{"name": "stop"}],"Output":[{"name": "counting"}],"State":[{"id": "IDLE"},{"id": "COUNTING"},{"id": "OVERFLOW"},{"id": "OVERFLOW_ERROR"}]}';

var fsm =JSON.parse("{"+fsmStr+"}").FSM;

console.info(fsm.name);

var fsmdesigner = {
		
	
	createFSMDiagram: function (divId) {

		
	    var $ = go.GraphObject.make;  // for conciseness in defining templates

	    myDiagram =
	      $(go.Diagram, divId,  // must name or refer to the DIV
											// HTML element
	        {
	          // start everything in the middle of the viewport
	          initialContentAlignment: go.Spot.Center,
	          // have mouse wheel events zoom in and out instead of scroll up
				// and down
	          "toolManager.mouseWheelBehavior": go.ToolManager.WheelZoom,
	          // support double-click in background creating a new node
	          "clickCreatingTool.archetypeNodeData": { text: "New State" },
	          // enable undo & redo
	          "undoManager.isEnabled": true
	        });

	    // when the document is modified, add a "*" to the title and enable the
		// "Save" button
	    myDiagram.addDiagramListener("Modified", function(e) {
	      var button = document.getElementById("SaveButton");
	      if (button) button.disabled = !myDiagram.isModified;
	      var idx = document.title.indexOf("*");
	      if (myDiagram.isModified) {
	        if (idx < 0) document.title += "*";
	      } else {
	        if (idx >= 0) document.title = document.title.substr(0, idx);
	      }
	    });

	    // define the Node template
	    myDiagram.nodeTemplate =
	      $(go.Node, "Auto",
	        new go.Binding("location", "loc", go.Point.parse).makeTwoWay(go.Point.stringify),
	        // define the node's outer shape, which will surround the TextBlock
	        $(go.Shape, "RoundedRectangle",
	          {
	            parameter1: 20,  // the corner has a large radius
	            fill: $(go.Brush, "Linear", { 0: "rgb(254, 201, 0)", 1: "rgb(254, 162, 0)" }),
	            stroke: null,
	            portId: "",  // this Shape is the Node's port, not the whole
								// Node
	            fromLinkable: true, fromLinkableSelfNode: true, fromLinkableDuplicates: true,
	            toLinkable: true, toLinkableSelfNode: true, toLinkableDuplicates: true,
	            cursor: "pointer"
	          }),
	        $(go.TextBlock,
	          {
	            font: "bold 11pt helvetica, bold arial, sans-serif",
	            editable: true  // editing the text automatically updates the
								// model data
	          },
	          new go.Binding("text").makeTwoWay())
	      );

	    // unlike the normal selection Adornment, this one includes a Button
	    myDiagram.nodeTemplate.selectionAdornmentTemplate =
	      $(go.Adornment, "Spot",
	        $(go.Panel, "Auto",
	          $(go.Shape, { fill: null, stroke: "blue", strokeWidth: 2 }),
	          $(go.Placeholder)  // a Placeholder sizes itself to the
									// selected Node
	        ),
	        // the button to create a "next" node, at the top-right corner
	        $("Button",
	          {
	            alignment: go.Spot.TopRight,
	            click: addNodeAndLink  // this function is defined below
	          },
	          $(go.Shape, "PlusLine", { width: 6, height: 6 })
	        ) // end button
	      ); // end Adornment

	    // clicking the button inserts a new node to the right of the selected
		// node,
	    // and adds a link to that new node
	    function addNodeAndLink(e, obj) {
	      var adornment = obj.part;
	      var diagram = e.diagram;
	      diagram.startTransaction("Add State");

	      // get the node data for which the user clicked the button
	      var fromNode = adornment.adornedPart;
	      var fromData = fromNode.data;
	      // create a new "State" data object, positioned off to the right of
			// the adorned Node
	      var toData = { text: "new" };
	      var p = fromNode.location.copy();
	      p.x += 200;
	      toData.loc = go.Point.stringify(p);  // the "loc" property is a
												// string, not a Point object
	      // add the new node data to the model
	      var model = diagram.model;
	      model.addNodeData(toData);

	      // create a link data from the old node data to the new node data
	      var linkdata = {
	        from: model.getKeyForNodeData(fromData),  // or just: fromData.id
	        to: model.getKeyForNodeData(toData),
	        text: "transition"
	      };
	      // and add the link data to the model
	      model.addLinkData(linkdata);

	      // select the new Node
	      var newnode = diagram.findNodeForData(toData);
	      diagram.select(newnode);

	      diagram.commitTransaction("Add State");

	      // if the new node is off-screen, scroll the diagram to show the new
			// node
	      diagram.scrollToRect(newnode.actualBounds);
	    }

	    // replace the default Link template in the linkTemplateMap
	    myDiagram.linkTemplate =
	      $(go.Link,  // the whole link panel
	        {
	          curve: go.Link.Bezier, adjusting: go.Link.Stretch,
	          reshapable: true, relinkableFrom: true, relinkableTo: true,
	          toShortLength: 3
	        },
	        new go.Binding("points").makeTwoWay(),
	        new go.Binding("curviness"),
	        $(go.Shape,  // the link shape
	          { strokeWidth: 1.5 }),
	        $(go.Shape,  // the arrowhead
	          { toArrow: "standard", stroke: null }),
	        $(go.Panel, "Auto",
	          $(go.Shape,  // the label background, which becomes transparent
							// around the edges
	            {
	              fill: $(go.Brush, "Radial",
	                      { 0: "rgb(240, 240, 240)", 0.3: "rgb(240, 240, 240)", 1: "rgba(240, 240, 240, 0)" }),
	              stroke: null
	            }),
	          $(go.TextBlock, "transition",  // the label text
	            {
	              textAlign: "center",
	              font: "9pt helvetica, arial, sans-serif",
	              margin: 4,
	              editable: true  // enable in-place editing
	            },
	            // editing the text automatically updates the model data
	            new go.Binding("text").makeTwoWay())
	        )
	      );

	    // Return
	    return myDiagram;
	  },

	  // Show the diagram's model in JSON format
	  save : function() {
	    document.getElementById("mySavedModel").value = myDiagram.model.toJson();
	  },
	  
	  load : function() {
	    myDiagram.model = go.Model.fromJson(document.getElementById("mySavedModel").value);
	  }
		
		
};

var fsmdiagram = fsmdesigner.createFSMDiagram("fsmtest");
//fsmdiagram.model = 

var log = function(msg, separate) {
    /*count = count + (separate ? 1 : 0);
    output.value = count + ": " + msg + "\n" + (separate ? "\n" : "") + output.value;
    demo.className = fsm.current;
    panic.disabled = fsm.cannot('panic');
    warn.disabled  = fsm.cannot('warn');
    calm.disabled  = fsm.cannot('calm');
    clear.disabled = fsm.cannot('clear');*/
  };
  
var fsmS = StateMachine.create({
	
	  events: [
	      { name: 'start', from: 'none',   to: 'green'  },
	      { name: 'warn',  from: 'green',  to: 'yellow' },
	      { name: 'panic', from: 'green',  to: 'red'    },
	      { name: 'panic', from: 'yellow', to: 'red'    },
	      { name: 'calm',  from: 'red',    to: 'yellow' },
	      { name: 'clear', from: 'red',    to: 'green'  },
	      { name: 'clear', from: 'yellow', to: 'green'  },
	    ],
	    callbacks: {
	        onbeforestart: function(event, from, to) { log("STARTING UP"); },
	        onstart:       function(event, from, to) { log("READY");       },

	        onbeforewarn:  function(event, from, to) { log("START   EVENT: warn!",  true);  },
	        onbeforepanic: function(event, from, to) { log("START   EVENT: panic!", true);  },
	        onbeforecalm:  function(event, from, to) { log("START   EVENT: calm!",  true);  },
	        onbeforeclear: function(event, from, to) { log("START   EVENT: clear!", true);  },

	        onwarn:        function(event, from, to) { log("FINISH  EVENT: warn!");         },
	        onpanic:       function(event, from, to) { log("FINISH  EVENT: panic!");        },
	        oncalm:        function(event, from, to) { log("FINISH  EVENT: calm!");         },
	        onclear:       function(event, from, to) { log("FINISH  EVENT: clear!");        },

	        onleavegreen:  function(event, from, to) { log("LEAVE   STATE: green");  },
	        onleaveyellow: function(event, from, to) { log("LEAVE   STATE: yellow"); },
	        onleavered:    function(event, from, to) { log("LEAVE   STATE: red");    async(to); return StateMachine.ASYNC; },

	        ongreen:       function(event, from, to) { log("ENTER   STATE: green");  },
	        onyellow:      function(event, from, to) { log("ENTER   STATE: yellow"); },
	        onred:         function(event, from, to) { log("ENTER   STATE: red");    },

	        onchangestate: function(event, from, to) { log("CHANGED STATE: " + from + " to " + to); }
	      }
});

fsmS.start();