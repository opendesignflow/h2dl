h2dl.fsmdesigner = {

	fsms : {},
		
	dagre : {

		load : function(fsm, targetSelector) {

			h2dl.fsmdesigner.fsms[targetSelector] = fsm;
			
			// Create a new directed graph
			// --------
			var g = new dagreD3.graphlib.Graph().setGraph({});
			h2dl.fsmdesigner.gr = g;
			
			// Create States from FSM
			// -------------------

			// Create Nodes for states
			var states = fsm.State.forEach(function(state) {

				console.log("State iinitial: " + state.initial)
				var shape = "rect";
				if (state.initial && state.initial == true) {
					shape = "circle";
				}
				var config = {
						label : state.id,
						shape : shape
				}
				if (state.highlight) {
					config.highlight = true;
				}
				g.setNode(state.id,config);
			})

			// Create Edges from Transitions
			// -----------------
			fsm.State.forEach(function(state) {
				if (state.Transition) {
					state.Transition.forEach(function(transition) {

						if (transition.name) {
							g.setEdge(state.id, transition.to, {
								label : transition.name,
							});
						} else {
							g.setEdge(state.id, transition.to, {});
						}

					});
				}
			});

			// Default Styling of nodes
			// -----------
			g.nodes().forEach(function(v) {
				var node = g.node(v);
				
				if (node.highlight) {
					node.style = "fill:yellow;stroke: #333";
				} else {
					node.style = "fill:white;stroke: #333";
				}
				
				
				node.rx = node.ry = 5;
			});

			g.edges().forEach(function(e) {
				var edge = g.edge(e);
				edge.style = "stroke:black;stroke-width:1px;fill:white";

			});

			// Create Renderer on SVG
			// ---------------
			var container = $(targetSelector);
			container.empty();
			container.data("fsm",fsm);
			
			// Create svg
			container.append($("<svg style='width:100%;height:100%'><g></g></svg>"));


			// var d3container = d3.select(targetSelector);
			console.log("W: " + container.width());

			// var svg = d3container.select("svg");
			console.log("Selected: " + targetSelector + " svg");
			var svg = d3.select(targetSelector + " svg");
			var inner = svg.select("g");

			// Create the renderer
			var render = new dagreD3.render();

			// Create Zoom
			// --------------
			var zoom = d3.behavior.zoom().on(
					"zoom",
					function() {
						inner.attr("transform", "translate("
								+ d3.event.translate + ")" + "scale("
								+ d3.event.scale + ")");
					});
			svg.call(zoom);

			// Call Rendering
			// -----------
			render(inner, g);

			// Set Size of viewport
			// -------------

			// Center the graph
			var initialScale = 0.9;
			zoom.translate(
					[ (container.width() - g.graph().width * initialScale) / 2,
							20 ]).scale(initialScale).event(svg);

			svg.attr('height', g.graph().height * initialScale + 40);
		}

	}

};

// Messaging support
$(function() {

	
	fwapp.websocket.onPushData("FSMSelectState", function(payload) {
		
		console.log("Select state: "+payload.id);
		console.log("Select FSM: "+payload.TargetID);
		
		var tid = "#" + payload.TargetID;
		//var fsm = $(tid).data("fsm");
		var fsm = h2dl.fsmdesigner.fsms[tid];
		console.log("FSM: "+fsm);
		 
		fsm.State.forEach(function(state) {
			
			if(state.id==payload.id) {
				console.log("Found State to highlight");
				state.highlight = true;
			} else {
				state.highlight = false;
			}
		});
		
		// Reload
		h2dl.fsmdesigner.dagre.load(fsm,tid);
		
		/*
		//var graph = fsmDiv.data("graph");
		
		// Get node
		var node = h2dl.fsmdesigner.gr.node(payload.id);
		
		node.style = "fill:yellow;stroke: #333";
		
		 h2dl.fsmdesigner.gr.nodes().forEach(function(v) {
			var node =  h2dl.fsmdesigner.gr.node(v);
			node.style = "fill:yellow;stroke: #333"
			node.rx = node.ry = 5;
		});*/
		
		
		
	});
	fwapp.websocket.makeEventConnection();

});
