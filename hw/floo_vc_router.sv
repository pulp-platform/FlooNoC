

// a router with virtual channels in the design of "Simple virtual channel allocation for high throughput and high frequency on-chip routers" 
// using the FVADA VC selection algorithm also described in that paper
module floo_vc_router (
  ports
);
  
/*
Structure:
1 input ports
2 local SA for each input port
3 global SA for each output port
4 look-ahead routing (runs parallel to global SA)
5 output port vc credit counters
6 vc selection (runs parallel to sa local/global)
7 vc assignment (runs after sa global)
8 map input VCs to output VCs
9 SA to ST stage reg
10 ST



*/







endmodule