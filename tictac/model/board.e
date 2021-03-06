note
	description: "A default spaghetti model."
	author: "Dan Sheng"
	date: "$Date$"
	revision: "$Revision$"

class
	BOARD

inherit
	ANY
		redefine
			out
		end

create {BOARD_ACCESS}
	make

feature {NONE} -- Initialization

	make
		local
			dummy_player: PLAYER
		do
			create player_one.make ("", "X", 1)
			create player_two.make ("", "O", 2)
			create next_player.make ("", "", 0)
			create dummy_player.make ("", "", 0)
			create {ARRAYED_LIST[TUPLE [player: PLAYER; position: INTEGER; status: STRING]]} move_list.make (0)

			previous_first_mover := player_two.get_piece
			status_message := "ok"
			redo_allowed := false
			game_in_play := false
			moves_made := 0

			move_list.force (dummy_player, 0, "ok")								-- initializing move
			move_list.forth

		end

feature {BOARD} -- board attributes

	move_list: LIST[TUPLE [player: PLAYER; position: INTEGER; status: STRING]]	-- history of moves done
	player_one, player_two, next_player: PLAYER									-- players, next_player used for printing and allowing next player, alternates between matches
	game_in_play: BOOLEAN														-- if false, undo and redo are not possible
	status_message: STRING														-- stores status message to output
	redo_allowed: BOOLEAN														-- allows redo operations
	game_won: BOOLEAN															-- checks if game won, used for undo and win condition/prompts
	previous_first_mover: STRING												-- the piece of the person who went first last round
	moves_made: INTEGER															-- holds the number of moves made
	start_of_new_game: BOOLEAN
	play_barrier: INTEGER

feature -- User Commands

	new_game (a_player_one_name: STRING; a_player_two_name: STRING)
		do
			if game_won or game_in_play then reset end

			player_one.change_name (a_player_one_name)
			player_one.reset_won
			player_two.change_name (a_player_two_name)
			player_two.reset_won

			game_won := false
			game_in_play := true
			start_of_new_game := true
			next_player := player_one
			previous_first_mover := player_one.get_piece
			moves_made := 0
			play_barrier := move_list.index

			status_flag(0)
		end

	play_again
		local
			dummy_player: PLAYER
		do
			create dummy_player.make ("", "", 0)
			create {ARRAYED_LIST[TUPLE [player: PLAYER; position: INTEGER; status: STRING]]} move_list.make (0)
			move_list.force (dummy_player, 0, "ok")
			move_list.forth

			redo_allowed := false
			game_in_play := true
			game_won := false
			start_of_new_game := false
			moves_made := 0
			play_barrier := move_list.index

			if previous_first_mover ~ player_one.get_piece then
				next_player := player_two
				previous_first_mover := player_two.get_piece
			else
				next_player := player_one
				previous_first_mover := player_one.get_piece
			end

			status_flag(0)
		end

	play (a_player_name: STRING; a_move: INTEGER)
		local
			current_player: PLAYER
			current_player_move: TUPLE[player: PLAYER; position: INTEGER; status: STRING]
			current_index: INTEGER
			temp_move_list: LIST[TUPLE [player: PLAYER; position: INTEGER; status: STRING]]
		do
			current_player := get_player_with_name (a_player_name)

			if current_player ~ player_one then
				next_player := player_two
			else
				next_player := player_one
			end

			current_player_move := [current_player, a_move, "ok"]

			if move_list.count > move_list.index then
				move_list.forth
				move_list.replace (current_player_move)
			else
				move_list.force (current_player_move)
				move_list.forth
			end

			redo_allowed := false
			start_of_new_game := false
			moves_made := moves_made + 1

			--Nuke everything past
			if move_list.index < move_list.count then
				current_index := move_list.index
				move_list.start
				temp_move_list := move_list.duplicate (current_index)
				move_list := temp_move_list
				move_list.go_i_th (current_index)
			end

			check_for_win
		end

	undo
		do
			if move_list.index > 1 then
				if game_in_play and move_list.index - 1 >= play_barrier then
					if move_list.item.position /= 0 then
						moves_made := moves_made - 1
						next_player := move_list.item.player
					end
					move_list.back
					redo_allowed := true
				elseif not game_in_play then
					if move_list.index = 2 then
						status_message := move_list.item.status
					else
						move_list.back
					end
					redo_allowed := true
				end
			else
				status_flag(0)
			end
		end

	redo
		local
			possible_next_player: PLAYER
		do
			if redo_allowed and move_list.count >= move_list.index + 1 then
				possible_next_player := move_list.item.player
				move_list.forth
				if move_list.item.position /= 0 then
					moves_made := moves_made + 1
					next_player := possible_next_player
				end
			end
		end

feature -- Defensive Queries

	is_valid_move (a_move: INTEGER): BOOLEAN
		local
			validity: BOOLEAN
			i: INTEGER
		do
			validity := true

			if a_move >= 1 and a_move <= 9 then
				from
					i := 1
				until
					i > move_list.index or not validity
				loop
					if move_list[i].position = a_move then
						validity := false
					end
					i := i + 1
				end
				Result := validity
			else
				Result := false
			end
		end

	is_their_turn (a_player_name: STRING): BOOLEAN
		do
			Result := a_player_name ~ next_player.get_name
		end

	player_exists (a_player_name: STRING): BOOLEAN
		do
			Result := a_player_name ~ player_one.get_name or a_player_name ~ player_two.get_name
		end

	is_alpha_name (a_player_name: STRING): BOOLEAN
		do
			Result := a_player_name[1].is_alpha
		end

	play_again_allowed: BOOLEAN
		do
			Result := not game_in_play and game_won = true
		end

feature	-- status message commands

	status_flag (a_flag: INTEGER)
	do
		inspect a_flag
		when 0 then status_message := "ok"
		when 1 then status_message := "names of players must be different"
		when 2 then status_message := "name must start with A-Z or a-z"
		when 3 then status_message := "not this player's turn"
		when 4 then status_message := "no such player"
		when 5 then status_message := "button already taken"
		when 6 then status_message := "there is a winner"
		when 7 then status_message := "finish this game first"
		when 8 then status_message := "game is finished"
		when 9 then status_message := "game ended in a tie"
		else
					status_message := ""
		end
	end

	invalid_command (a_status_message: STRING)
	local
		dummy_player: PLAYER
		status_move: TUPLE [player: PLAYER; position: INTEGER; status: STRING]
	do
		create dummy_player.make ("", "", 0)
		status_move := [dummy_player, 0, a_status_message]
		move_list.force (status_move)
		move_list.forth
	end

feature	-- status message queries

	get_status_message: STRING
	do
		Result := status_message
	end

	get_previous_status_message: STRING
	do
		if move_list.index > 1 then
			Result := move_list[move_list.index - 1].status
		else
			Result := ""
		end

	end

feature {BOARD} -- Hidden Commands

	build_board: ARRAY[STRING]
		-- Store each piece in an array, index in array matching index on board
		local
			i: INTEGER
			tiles: ARRAY[STRING]
		do
			create tiles.make_filled ("", 1, 9)

			from
				i := 1
			until
				i > move_list.index
			loop
				if move_list[i].position > 0 then
					tiles.put (move_list[i].player.get_piece, move_list[i].position)
				end
				i := i + 1
			end

			Result := tiles
		end

	check_for_win
		local
			tiles: ARRAY[STRING]
			winning_piece: STRING
		do
			tiles := build_board
			winning_piece := compare_pieces (tiles)
			if winning_piece /~ "" then
				get_player_with_piece(winning_piece).win_game
				game_won := true
				game_in_play := false

				status_flag(6)
			elseif moves_made = 9 then
				game_won := true
				game_in_play := false

				status_flag(9)
			end
		end

	compare_pieces (tiles: ARRAY[STRING]): STRING
--			Check the board, return the winning piece, return "" if no winning piece
		do
			Result := ""
			if tiles[1] ~ tiles[2] and tiles[2] ~ tiles[3] and tiles[1] /~ "" or
			   tiles[1] ~ tiles[5] and tiles[5] ~ tiles[9] and tiles[1] /~ "" or
			   tiles[1] ~ tiles[4] and tiles[4] ~ tiles[7] and tiles[1] /~ "" then
					Result := tiles[1]
			elseif tiles[4] ~ tiles[5] and tiles[5] ~ tiles[6] and tiles[4] /~ "" or
			       tiles[7] ~ tiles[5] and tiles[5] ~ tiles[3] and tiles[7] /~ "" or
			       tiles[2] ~ tiles[5] and tiles[5] ~ tiles[8] and tiles[2] /~ "" then
					Result := tiles[5]
			elseif tiles[7] ~ tiles[8] and tiles[8] ~ tiles[9] and tiles[7] /~ "" or
				   tiles[3] ~ tiles[6] and tiles[6] ~ tiles[9] and tiles[3] /~ "" then
					Result := tiles[9]
			end
		end

feature {BOARD} -- Hidden Queries

	get_player_with_name (a_player_name: STRING): PLAYER
		do
			if player_one.get_name ~ a_player_name then
				Result := player_one
			else
				Result := player_two
			end
		end

	get_player_with_piece (a_piece: STRING): PLAYER
		do
			if a_piece ~ player_one.get_piece then
				Result := player_one
			else
				Result := player_two
			end
		end

	print_message: STRING
		do
			create Result.make_from_string ("")
			Result.append (": => ")
			if player_one.get_name ~ "" then
				Result.make_from_string ("")
				Result.append (":  => ")
				Result.append ("start new game%N  ")
			elseif game_won = true then
				Result.append ("play again or start new game%N  ")
			else
				if player_one.get_wins = 0 and player_two.get_wins = 0 and start_of_new_game then		-- new game
					Result.append (player_one.get_name)
				else
					Result.append (next_player.get_name)
				end
				Result.append (" plays next%N  ")
			end
			Result.append (print_board)
			Result.append ("%N  ")

			Result.append (player_one.get_wins.out)
			Result.append (": score for %"")
			Result.append (player_one.get_name)
			Result.append ("%" (as X)%N  ")

			Result.append (player_two.get_wins.out)
			Result.append (": score for %"")
			Result.append (player_two.get_name)
			Result.append ("%" (as O)")
		end

	print_opponent (a_player: PLAYER): STRING
		do
			if a_player ~ player_one then
				Result := player_two.get_name
			elseif a_player ~ player_two then
				Result := player_one.get_name
			--PLAY_AGAIN
			elseif previous_first_mover ~ player_one.get_piece then
				Result := player_two.get_name
			else
				Result := player_one.get_name
			end
		end

	print_board: STRING
		local
			top_row, mid_row, bot_row: STRING
			i: INTEGER
		do
			create Result.make_from_string ("")
			top_row := "___"
			mid_row := "___"
			bot_row := "___"

			from
				i := 1
			until
				i > move_list.index
			loop
				if move_list[i].position >= 1 and move_list[i].position <= 3 then
					top_row.remove (move_list[i].position)
					if move_list[i].player.get_piece ~ "X" or move_list[i].player.get_piece ~ "O" then
						top_row.insert_string (move_list[i].player.get_piece, move_list[i].position)
					end
				elseif move_list[i].position >= 4 and move_list[i].position <= 6 then
					mid_row.remove (move_list[i].position - 3)
					if move_list[i].player.get_piece ~ "X" or move_list[i].player.get_piece ~ "O" then
						mid_row.insert_string (move_list[i].player.get_piece, move_list[i].position - 3)
					end
				elseif move_list[i].position >= 7 and move_list[i].position <= 9 then
					bot_row.remove (move_list[i].position - 6)
					if move_list[i].player.get_piece ~ "X" or move_list[i].player.get_piece ~ "O" then
						bot_row.insert_string (move_list[i].player.get_piece, move_list[i].position - 6)
					end
				end
				i := i + 1
			end

			Result.append (top_row)
			Result.append ("%N  ")
			Result.append (mid_row)
			Result.append ("%N  ")
			Result.append (bot_row)
		end

feature -- model reset operations

	reset
		do
			make
		end

feature -- output query

	out : STRING
		do
			create Result.make_from_string ("  ")

			if status_message /~ "" then
				Result.append (status_message)
			else
				Result.append (move_list.item.status)
			end

			Result.append (print_message)
			status_message := ""
		end

end




