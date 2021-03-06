class GamesController < ApplicationController

    def index

        allGames = Game.visible_games.map{
            |game|
            {
                name: game.name,
                id: game.id,
                created_at: game.created_at,
                game_type: game.game_type,
                closed: game.closed,
                connection_count: MessagesChannel.game_connection_count(game.id),
                # connection_count: game.connections
            }
        }
        render json: {
            lobby_status:{
                games: allGames,
                connections: GamesChannel.connection_count + 1
        } 
    }
    end

    def create

        game = Game.new(game_params)
        game.save

        GamesController.broadcast_lobby_status

    end

    def self.broadcast_lobby_status

        allGames = Game.visible_games.map{
            |game|
            {
                name: game.name,
                id: game.id,
                created_at: game.created_at,
                game_type: game.game_type,
                closed: game.closed,
                connection_count: MessagesChannel.game_connection_count(game.id)
            }
        }
    
        lobby_status = {
            connections: GamesChannel.connection_count,
            games: allGames
        }

        ActionCable.server.broadcast 'games_channel', {lobby_status: lobby_status}
        # head :ok
    
    end



    def destroy
        game = Game.find_by(id: params[:id])
        game.destroy

        GamesController.broadcast_lobby_status
    
    end

    def show
        game = Game.find_by(id: params[:id])

        if game
            turn_hash ={
                game_id: game.id,
                game_type: "game_status",
                action: {
                    connections: MessagesChannel.game_connection_count(game.id),
                    closed: game.closed,
                    name: game.name,    
                                    }
            }

            ActionCable.server.broadcast "turn_channel_#{game.id}", {turn: turn_hash}

        else
            render status: :not_found
        end

    end

    def close
        @game = Game.find_by(id:params[:id])

        new_closed_state = !@game.closed


        if @game
            @game.closed = !@game.closed
            @game.save
            turn_hash ={
                game_id: @game.id,
                game_type: "game_status",
                action: {
                    connections: MessagesChannel.game_connection_count(@game.id),
                    closed: @game.closed,
                    name: @game.name,    
                                    }
            }
            ActionCable.server.broadcast "turn_channel_#{@game.id}", {turn: turn_hash}

            GamesController.broadcast_lobby_status



        end




    end


    

    private

    def game_params
        params.require(:game).permit(:name, :game_type)
    end

end
