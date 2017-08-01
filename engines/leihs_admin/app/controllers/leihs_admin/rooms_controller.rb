module LeihsAdmin
  class RoomsController < AdminController

    def index
      @rooms = \
        Room
        .includes(:building)
        .order('buildings.name ASC, lower(rooms.name) ASC')
      if search_term_param
        @rooms = @rooms.search(search_term_param)
      end
      @rooms = @rooms.default_paginate(paginate_params)

      respond_to do |format|
        format.html
        format.js do
          render partial: 'leihs_admin/rooms/room', collection: @rooms
        end
      end
    end

    def new
      @room = Room.new
      @buildings = ([Building.new] + Building.all)
    end

    def create
      @room = Room.create room_params
      if @room.persisted?
        flash[:notice] = _('Room successfully created')
        redirect_to action: :index
      else
        flash.now[:error] = @room.errors.full_messages.uniq.join(', ')
        @buildings = ([Building.new] + Building.all)
        render :new
      end
    end

    def edit
      @room = Room.find(room_id_param)
      @buildings = Building.all
    end

    def update
      @room = Room.find(room_id_param)
      if @room.update_attributes room_params
        flash[:notice] = _('Room successfully updated')
        redirect_to action: :index
      else
        flash.now[:error] = @room.errors.full_messages.uniq.join(', ')
        @buildings = Building.all
        render :edit
      end
    end

    def destroy
      @room = Room.find(room_id_param)
      begin
        @room.destroy
        flash[:success] = _('%s successfully deleted') % _('Room')
      rescue => e
        flash[:error] = e.to_s
      end
      redirect_to action: :index
    end

    private

    def room_id_param
      params.require(:id)
    end

    def room_params
      params.require(:room).permit(:building_id, :name, :description)
    end

    def paginate_params
      params.permit(:page)
    end

    def search_term_param
      params.fetch(:search_term, nil)
    end

  end
end
