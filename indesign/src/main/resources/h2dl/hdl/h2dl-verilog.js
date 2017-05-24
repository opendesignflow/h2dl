$(function() {

	hljs.configure({
	  tabReplace: '    ', // 4 spaces
	 
	});
	hljs.initHighlighting();
	$(".code").each(function(i,e) {
		hljs.highlightBlock(e);
	});
	
	
	console.log("Init Verilog View..."+hljs.listLanguages());
});