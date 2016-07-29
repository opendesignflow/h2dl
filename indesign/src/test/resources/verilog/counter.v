
module counter #(parameter SIZE = 8) (

	// System
    // IO Definition -- pdfjs-lecturepdf#11,9,10
	input clk,
	input res_n,

	// Control
	input hold,
	input clear,

	// Output
	output reg [SIZE-1:0] value

	);

	always @(posedge clk or negedge res_n) begin

		// Reset
		if (!res_n) begin

			value <= {SIZE {1'b0} };
			
		end
		// Main
		else begin
			
			if (clear) begin
				value <= {SIZE {1'b0} };
			end
			else if (!hold) begin

				value <= value +1;

			end

		end
	end

endmodule