class Api::V1::SongsController < ApplicationController
  # GET /songs/search
  def search
    @songs = Genius::Song.search(params[:artist], params: allowed_params.slice(:per_page))
    render json: { songs: @songs }
  end

  private

  def allowed_params
    params.permit(:artist, :per_page)
  end
end