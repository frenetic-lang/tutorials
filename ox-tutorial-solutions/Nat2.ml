open OxPlatform
open Packet
open OpenFlow0x01_Core

module MyApplication = struct

  include OxStart.DefaultTutorialHandlers

  let mappings = Hashtbl.create 50

  let publicIP = 167772259l
  let publicMAC = 153L

  let privateIP1 = 167772161l
  let privateIP2 = 167772162l

  let publicPort1 = 5000

  let publicPort2 = 5001

  let switch_connected (sw:switchId) feats : unit = 
    Printf.printf "Switch Connected %Ld\n%!" sw

  let packet_in (sw: switchId) (xid : xid) (pktIn : packetIn) : unit = 
    let pk = parse_payload pktIn.input_payload in
    if (pktIn.port = 1 || pktIn.port = 2) 
      && Packet.dlTyp pk = 0x800 
      && Packet.nwProto pk = 0x06 
    then
      begin
	Printf.printf "Outgoing flow %s\n%!" (packetIn_to_string pktIn);
	let privateMAC = pk.Packet.dlSrc in 
        let privateIP =  Packet.nwSrc pk in
        let src_port =  pktIn.port in
	let publicPort = 
	  if src_port = 1 
	  then publicPort1 
	  else publicPort2 in
        let tcp_src = Packet.tpSrc pk (* with _ -> Printf.printf "ERRRR\n%!"; 0 *) in
        let action = 
        [SetDlSrc publicMAC;
         SetNwSrc publicIP; 
         SetTpSrc publicPort; 
         Output (PhysicalPort 3)] in
        let match_pk = 
	{ match_all with 
          inPort = Some src_port; 
          dlSrc = Some privateMAC;
	  dlTyp = Some 0x800; 
	  nwSrc = Some privateIP; 
	  nwProto = Some 0x06; 
	  tpSrc = Some tcp_src } in
        Printf.printf "Translating Private IP: %ld:%d to Public IP: %ld:%d.\n%!" privateIP tcp_src publicIP publicPort;
        Hashtbl.add mappings (publicPort) (privateMAC, privateIP, src_port, tcp_src);
        send_flow_mod sw 0l (add_flow 20 match_pk action);
        send_packet_out sw 0l {
  	  output_payload = pktIn.input_payload;
          port_id = None;
          apply_actions = action };
       end
    else 
      try
	Printf.printf "Non TCP or incoming flow %s\n%!" (packetIn_to_string pktIn);
        let (mac_dst, ip_dst ,inPort, tcp_dst) = Hashtbl.find mappings (Packet.tpDst pk) in
	Printf.printf "Found a mapping in the hashtable\n%!";
        let src_port = pktIn.port in
        let pubPort = Packet.tpDst pk in 
        let match_pk = 
	  { match_all with 
	    inPort = Some src_port; 
	    dlSrc = Some publicMAC;
	    dlTyp = Some 0x800;	
	    nwSrc = Some publicIP; 
	    nwProto = Some 0x06; 
	    tpDst = Some pubPort } in 
        let action = 
	  [ SetDlDst mac_dst;
	    SetNwDst ip_dst; 
	    SetTpDst tcp_dst; 
	    Output (PhysicalPort inPort)] in
          send_flow_mod sw 0l (add_flow 20 match_pk action);
          send_packet_out sw 0l {
  	    output_payload = pktIn.input_payload;
            port_id = None;
            apply_actions = action
          }           
      with Not_found -> 
	begin
	  Printf.printf "Didn't find a mapping in the hashtable\n%!";
          send_packet_out sw 0l {
            output_payload = pktIn.input_payload;
            port_id = None;
            apply_actions = []
          }
	end
      
end

module Controller = OxStart.Make (MyApplication)
