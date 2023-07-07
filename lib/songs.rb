module Songs
  def self.find_by_artist(artist)
    songs = GeniusApi.search(q: artist)

    # Weed out results that may not be related to the given artist.
    songs.select { |r| self.matches_artist?(r['result'], artist) }
  end

  private

  def self.matches_artist?(result, artist)
    # This is a very rough attempt at weeding out results that are not related to the artist we're looking for.
    # The algorithm is this: include records if a single word in the artist query is part of the primary or featured 
    # artist listed in the result.

    primary_artist = result['primary_artist']['name'].downcase
    if result['featured_artists']
      featured_artists = result['featured_artists'].collect { |a| a['name'].downcase }
    end

    artist.split(' ').each do |t|
      name_part = t.downcase
      return true if primary_artist.match(name_part)
      return true if featured_artists && featured_artists.join(' ').match(name_part)
    end

    false
  end
end