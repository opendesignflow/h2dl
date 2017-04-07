$(function() {
	
	$('.menu.tabular .item')
	  .tab()
	;
	$('.ui.sticky')
	  .sticky({
	    context: '#left-column'
	  })
	;
	
	$('.table.sortable').tablesort();
	
});