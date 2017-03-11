note
	description: ""
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	ETF_NEW_GAME
inherit
	ETF_NEW_GAME_INTERFACE
		redefine new_game end
create
	make
feature -- command
	new_game(player1: STRING ; player2: STRING)
		require else
			new_game_precond(player1, player2)
    	do
			-- perform some update on the model state
			if player1 ~ player2 then
				model.status_flag (1)
				model.invalid_command (model.get_status_message)
			elseif not model.is_alpha_name (player1) or not model.is_alpha_name (player2) then
				model.status_flag (2)
				model.invalid_command (model.get_status_message)
			else
				model.new_game (player1, player2)
			end
			etf_cmd_container.on_change.notify ([Current])
    	end

end
