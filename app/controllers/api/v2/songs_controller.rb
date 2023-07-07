class Api::V2::SongsController < ApplicationController
  include Songs

  # GET /songs/search
  def search
    @songs = Songs.find_by_artist(params[:artist])
    render json: { songs: @songs }
  end

  private

  def allowed_params
    params.permit(:artist)
  end
end