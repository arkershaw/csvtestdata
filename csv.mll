{
	let input = ref "" and
		output = ref "" and
		append = ref 0 and
		populate = ref false;;

	Arg.parse [
		("-o", Arg.String (fun s -> output := s), "Output file");
		("-a", Arg.Int (fun i -> append := i), "Append # records");
		("-p", Arg.Unit (fun () -> populate := true), "Populate records")
	] (fun s -> input := s) "Input file";;

	if !input = "" then
	(
			print_string "Invalid input file.\n";
			exit 0
	);;

	if !output = "" then output := !input ^ ".out";;

	Random.self_init();;

	let recDel = ref "" and
		key = Hashtbl.create 20 and
		id = Hashtbl.create 4;;

	let gen_int imin imax =
		let amin = abs (min imin imax) and amax = abs (max imin imax) in
			match amin, amax with
				i, j when i = j -> i
				| _, _ -> (Random.int (amax - amin)) + amin;;

	let gen_float fmin fmax =
		let amin = abs_float (min fmin fmax) and amax = abs_float (max fmin fmax) in
			match amin, amax with
				i, j when i = j -> i
				| _, _ -> (Random.float (amax -. amin)) +. amin;;

	let gen_char cap =
		let c =
			match cap with
				true -> int_of_char 'A'
				| false -> int_of_char 'a' in
			char_of_int ((Random.int 26) + c);;

	let gen_name min max =
		let length = gen_int min max in
			let str = String.create (length + 1) in
				let rec gen len =
					match len with
						0 -> String.set str 0 (gen_char true); str
						| _ -> String.set str len (gen_char false); gen (len - 1) in
				gen length;;

	let gen_postcode fi =
		let pc = Buffer.create 8 in
			Buffer.add_char	pc (gen_char true);
			Buffer.add_char	pc (gen_char true);
			Buffer.add_string pc (string_of_int (gen_int 1 29));
			Buffer.add_char pc ' ';
			Buffer.add_string pc (string_of_int (gen_int 1 9));
			Buffer.add_char pc (gen_char true);
			Buffer.add_char pc (gen_char true);
		Buffer.contents pc;;

	let gen_address fi =
		let suf = [|"Street"; "Lane"; "Road"; "Crescent"; "Rise"; "Court"; "View"|] in
			let add = Buffer.create 25 in
				Buffer.add_string add (string_of_int (gen_int 1 100));
				Buffer.add_char add ' ';
				Buffer.add_string add (gen_name 3 10);
				Buffer.add_char add ' ';
				Buffer.add_string add (suf.(Random.int (Array.length suf)));
			Buffer.contents add;;

	let gen_email fi =
		let suf = [|"com"; "net"; "org"; "co.uk"|] in
			let em = Buffer.create 30 in
				Buffer.add_string em (gen_name 3 10);
				Buffer.add_char em '@';
				Buffer.add_string em (gen_name 3 10);
				Buffer.add_char em '.';
				Buffer.add_string em (suf.(Random.int (Array.length suf)));
			Buffer.contents em;;

	let gen_id fi first inc =
		let frst = abs first and
			ic = abs inc in
		if Hashtbl.mem id fi then
			Hashtbl.replace id fi ((Hashtbl.find id fi) + ic)
		else
			Hashtbl.add id fi frst;
		Hashtbl.find id fi;;

	let gen_date fy fm fd ty tm td =
		string_of_int (gen_int fy ty) ^ "-" ^ string_of_int (gen_int fm tm) ^ "-" ^ string_of_int (gen_int fd td) ^ " 00:00:00";;

	let generate fi =
		let k = Hashtbl.find key fi in
			if Str.string_match (Str.regexp "ID \\([0-9]+\\)-\\([0-9]+\\)") k 0 then
				string_of_int (gen_id fi (int_of_string (Str.matched_group 1 k)) (int_of_string (Str.matched_group 2 k)))
			else if Str.string_match (Str.regexp "Name") k 0 then
				gen_name 3 10
			else if Str.string_match (Str.regexp "Address") k 0 then
				gen_address fi
			else if Str.string_match (Str.regexp "Postcode") k 0 then
				gen_postcode fi
			else if Str.string_match (Str.regexp "Email") k 0 then
				gen_email fi
			else if Str.string_match (Str.regexp "Word \\([0-9]+\\)-\\([0-9]+\\)") k 0 then
				gen_name (int_of_string (Str.matched_group 1 k)) (int_of_string (Str.matched_group 2 k))
			else if Str.string_match (Str.regexp "Integer \\([0-9]+\\)-\\([0-9]+\\)") k 0 then
				string_of_int (gen_int (int_of_string (Str.matched_group 1 k)) (int_of_string (Str.matched_group 2 k)))
			else if Str.string_match (Str.regexp "Decimal \\([0-9]+\\.[0-9]+\\)-\\([0-9]+\\.[0-9]+\\) \\([0-9]+\\)") k 0 then
				Format.sprintf "%.*f" (int_of_string (Str.matched_group 3 k)) (gen_float (float_of_string (Str.matched_group 1 k)) (float_of_string (Str.matched_group 2 k)))
			else if Str.string_match (Str.regexp "Literal \\(.*\\)") k 0 then
				Str.matched_group 1 k
			else if Str.string_match (Str.regexp "Date \\([0-9][0-9][0-9][0-9]\\)-\\([0-9][0-9]?\\)-\\([0-9][0-9]?\\) \\([0-9][0-9][0-9][0-9]\\)-\\([0-9][0-9]?\\)-\\([0-9][0-9]?\\)") k 0 then
				gen_date (int_of_string (Str.matched_group 1 k)) (int_of_string (Str.matched_group 2 k)) (int_of_string (Str.matched_group 3 k)) (int_of_string (Str.matched_group 4 k)) (int_of_string (Str.matched_group 5 k)) (int_of_string (Str.matched_group 6 k))
			else
				"";;

	let end_field file txt fi del =
		match txt, !populate with
			"" , true -> Printf.fprintf file "%s%s" (generate fi) del
			| _, _ -> Printf.fprintf file "%s%s" txt del;;

	let gen_field file count =
		let cnt = abs count in
			let rec gf ct =
				if ct < cnt then
					(end_field file "" ct ","; gf (ct + 1))
				else
					end_field file "" ct !recDel
			in
				gf 0;;

	let gen_record file count =
		let keys = (Hashtbl.length key) - 1 and
			cnt = abs count in
			let rec gr ct =
				match ct with
					0 -> ()
					| _ -> gen_field file keys; gr (ct - 1)
			in
				gr cnt;;
}
rule tokens = parse
	['\"'] { `Escape }
	| [','] { `Field }
	| ('\013'?'\n' as del) { `Record (del) }
	| eof { `File }
	| ([^',' '\"' '\013' '\n']+ as dat) { `Data (dat) }
{
	let rec next_token txt esc ri fi outF lBuf =
		let tok = tokens lBuf in
			match tok, esc, ri with
				`File, _, _ -> end_field outF txt fi !recDel
				| `Record del, true, _ ->	next_token (txt ^ del) esc ri fi outF lBuf
				| `Record del, false, 0 -> recDel := del; Hashtbl.add key fi txt; next_token "" esc (ri + 1) 0 outF lBuf
				| `Record del, false, _ -> end_field outF txt fi del; next_token "" esc (ri + 1) 0 outF lBuf
				| `Field, true, _ -> next_token (txt ^ ",") esc ri fi outF lBuf
				| `Field, false, 0 -> Hashtbl.add key fi txt; next_token "" esc ri (fi + 1) outF lBuf
				| `Field, false, _ -> end_field outF txt fi ","; next_token "" esc ri (fi + 1) outF lBuf
				| `Escape, _, _ -> next_token (txt ^ "\"") (not esc) ri fi outF lBuf
				| `Data dat, _, _ -> next_token (txt ^ dat) esc ri fi outF lBuf;;

	let _ =
		let outFile = open_out !output and inFile = open_in !input in
		let res = try
			let lb = Lexing.from_channel inFile in
				next_token "" false 0 0 outFile lb;
				populate := true; gen_record outFile !append;
				"Completed.\n"
			with exn -> close_in inFile; close_out outFile; raise exn in
				close_in inFile;
				close_out outFile;
				print_string res;;
}